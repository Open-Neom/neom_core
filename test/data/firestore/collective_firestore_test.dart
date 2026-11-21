import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fba;
import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/data/firestore/collective_daw_project_firestore.dart';
import 'package:neom_core/data/firestore/collective_firestore.dart';
import 'package:neom_core/data/firestore/inbox_firestore.dart';
import 'package:neom_core/domain/model/app_profile.dart';
import 'package:neom_core/domain/model/app_user.dart';
import 'package:neom_core/domain/model/collective.dart';
import 'package:neom_core/domain/model/collective_daw_project.dart';
import 'package:neom_core/domain/model/collective_member.dart';
import 'package:neom_core/domain/model/inbox_message.dart';
import 'package:neom_core/domain/model/instrument.dart';
import 'package:neom_core/domain/use_cases/login_service.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';
import 'package:neom_core/utils/enums/auth_status.dart';
import 'package:neom_core/utils/enums/collective_member_role.dart';
import 'package:neom_core/utils/enums/inbox_room_kind.dart';
import 'package:neom_core/utils/enums/inbox_room_type.dart';
import 'package:sint/sint.dart';

class _FakeFirebaseUser extends Fake implements fba.User {}

class _FakeLoginService extends Fake implements LoginService {
  @override
  AuthStatus getAuthStatus() => AuthStatus.loggedIn;

  @override
  fba.User get fbaUser => _FakeFirebaseUser();
}

class _FakeUserService extends Fake implements UserService {
  @override
  final user = AppUser(id: 'u1');

  @override
  final profile = AppProfile(id: 'founder-1', name: 'Founder');
}

void main() {
  late FakeFirebaseFirestore firestore;
  late CollectiveFirestore repo;
  late InboxFirestore inboxRepo;

  setUp(() {
    Sint.reset();
    AppConfig.instance.appInUse = AppInUse.g;
    AppConfig.instance.isGuestMode = true;
    firestore = FakeFirebaseFirestore();
    repo = CollectiveFirestore(
      firestore: firestore,
      authUidProvider: () => 'auth-uid-1',
    );
    inboxRepo = InboxFirestore(firestore: firestore);
  });

  tearDown(() {
    Sint.reset();
    AppConfig.instance.isGuestMode = true;
  });

  test('insert creates active collective, members with doc ids, and group inbox room', () async {
    final collective = Collective(
      name: 'Los Neones',
      description: 'Banda de synth rock',
      photoUrl: 'https://firebasestorage.googleapis.com/band.png',
    );
    collective.members = {
      'slot-founder': CollectiveMember(
        name: 'Ana',
        profileId: 'founder-1',
        role: CollectiveMemberRole.founder,
        instrument: Instrument(id: 'guitar', name: 'guitar'),
      ),
      'slot-open': CollectiveMember(
        name: '',
        profileId: '',
        role: CollectiveMemberRole.member,
        instrument: Instrument(id: 'drums', name: 'drums'),
      ),
    };

    final id = await repo.insert(collective);
    expect(id, isNotEmpty);
    expect(collective.id, id);
    expect(collective.isActive, isTrue);

    final doc = await firestore.collection('collectives').doc(id).get();
    expect(doc.exists, isTrue);
    expect(doc.data()!['id'], id);
    expect(doc.data()!['isActive'], isTrue);
    expect(doc.data()!['ownerAuthUid'], 'auth-uid-1');
    expect(doc.data()!['memberProfileIds'], ['founder-1']);
    expect(doc.data()!['adminProfileIds'], ['founder-1']);

    // Duplicate slug check (case-insensitive)
    expect(await repo.isAvailableName('los neones'), isFalse);
    expect(await repo.isAvailableName('Otra Banda'), isTrue);

    // Parent group chat room created
    final inboxDoc = await firestore.collection('inbox').doc(id).get();
    expect(inboxDoc.exists, isTrue);
    expect(inboxDoc.data()!['roomKind'], InboxRoomKind.collective.name);
    expect(inboxDoc.data()!['name'], 'Los Neones');
    expect(inboxDoc.data()!['profileIds'], ['founder-1']);
    expect(inboxDoc.data()!['adminIds'], ['founder-1']);
  });

  test('retrieve returns only public itemlists for guests & non-members, all for members', () async {
    final collective = Collective(name: 'Banda Publica');
    collective.members = {
      'founder': CollectiveMember(
        name: 'Ana',
        profileId: 'founder-1',
        role: CollectiveMemberRole.founder,
      ),
    };
    final id = await repo.insert(collective);

    await firestore.collection('itemlists').doc('list-pub').set({
      'id': 'list-pub',
      'name': 'Giglist Publica',
      'ownerId': id,
      'ownerName': 'Banda Publica',
      'ownerType': 'collective',
      'type': 'giglist',
      'public': true,
    });
    await firestore.collection('itemlists').doc('list-priv').set({
      'id': 'list-priv',
      'name': 'Ensayo Privado',
      'ownerId': id,
      'ownerName': 'Banda Publica',
      'ownerType': 'collective',
      'type': 'giglist',
      'public': false,
    });

    // Guest mode -> only public
    AppConfig.instance.isGuestMode = true;
    final guestView = await repo.retrieve(id);
    expect(guestView.itemlists?.keys, ['list-pub']);

    // Signed in non-member -> only public
    AppConfig.instance.isGuestMode = false;
    Sint.put<LoginService>(_FakeLoginService());
    Sint.put<UserService>(_FakeUserService());
    final visitorView = await repo.retrieve(id, viewerProfileId: 'outsider-99');
    expect(visitorView.itemlists?.keys, ['list-pub']);

    // Signed in member -> both public and private
    final memberView = await repo.retrieve(id, viewerProfileId: 'founder-1');
    expect(memberView.itemlists?.keys, unorderedEquals(['list-pub', 'list-priv']));
  });

  test('member add, role update, unfulfill, remove sync roster & inbox and reject empty ids', () async {
    final collective = Collective(name: 'Trio Jazz');
    collective.members = {
      'f': CollectiveMember(
        name: 'Ana',
        profileId: 'founder-1',
        role: CollectiveMemberRole.founder,
      ),
    };
    final id = await repo.insert(collective);

    // Reject empty member id safely
    expect(await repo.fulfillCollectiveMember(id, CollectiveMember()), isFalse);
    expect(await repo.unfulfillCollectiveMember(id, CollectiveMember()), isFalse);
    expect(await repo.removeCollectiveMember(id, CollectiveMember()), isFalse);

    // Add member
    final bassMember = CollectiveMember(
      name: 'Luis',
      profileId: 'member-2',
      role: CollectiveMemberRole.member,
      instrument: Instrument(id: 'bass', name: 'bass'),
    );
    final memberDocId = await repo.addCollectiveMember(id, bassMember);
    expect(memberDocId, isNotEmpty);

    var inboxDoc = await firestore.collection('inbox').doc(id).get();
    expect(inboxDoc.data()!['profileIds'], unorderedEquals(['founder-1', 'member-2']));
    expect(inboxDoc.data()!['adminIds'], ['founder-1']);

    // Promote to moderator (admin)
    expect(
      await repo.updateCollectiveMemberRole(id, memberDocId, CollectiveMemberRole.moderator),
      isTrue,
    );
    inboxDoc = await firestore.collection('inbox').doc(id).get();
    expect(inboxDoc.data()!['adminIds'], unorderedEquals(['founder-1', 'member-2']));

    // Expel (unfulfill) -> removes from profileIds/adminIds
    expect(await repo.unfulfillCollectiveMember(id, bassMember), isTrue);
    inboxDoc = await firestore.collection('inbox').doc(id).get();
    expect(inboxDoc.data()!['profileIds'], ['founder-1']);
    expect(inboxDoc.data()!['adminIds'], ['founder-1']);

    // Remove collective cleans up doc, subcollections & parent inbox doc
    expect(await repo.remove(collective), isTrue);
    expect((await firestore.collection('collectives').doc(id).get()).exists, isFalse);
    expect((await firestore.collection('inbox').doc(id).get()).exists, isFalse);
  });

  test('InboxFirestore.addMessage for collective merges lastMessage without not-found', () async {
    final msg = InboxMessage(
      ownerId: 'founder-1',
      profileName: 'Ana',
      text: 'Ensayo el viernes a las 8pm',
      createdTime: 1000,
    );
    final ok = await inboxRepo.addMessage(
      'brand-new-collective-room',
      msg,
      inboxRoomType: InboxRoomType.collective,
    );
    expect(ok, isTrue);

    final roomDoc = await firestore.collection('inbox').doc('brand-new-collective-room').get();
    expect(roomDoc.exists, isTrue);
    expect(roomDoc.data()!['roomKind'], InboxRoomKind.collective.name);
    expect((roomDoc.data()!['lastMessage'] as Map)['text'], 'Ensayo el viernes a las 8pm');
  });

  test('CollectiveDawProjectFirestore stamps ownerAuthUid and queries owned/collab projects', () async {
    final dawRepo = CollectiveDawProjectFirestore(
      firestore: firestore,
      authUidProvider: () => 'auth-uid-1',
    );
    final project = CollectiveDawProject(
      name: 'Demo Nuevo',
      ownerId: 'founder-1',
      collectiveId: 'coll-1',
      updatedTime: 500,
    );
    final pid = await dawRepo.insert(project);
    expect(pid, isNotEmpty);
    expect(project.ownerAuthUid, 'auth-uid-1');

    final loaded = await dawRepo.getByCollective('coll-1');
    expect(loaded.map((p) => p.id), [pid]);
  });
}
