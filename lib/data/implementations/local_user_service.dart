import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fba;

import '../../domain/model/app_profile.dart';
import '../../domain/model/app_user.dart';
import '../../domain/model/collective.dart';
import '../../domain/model/user_subscription.dart';
import '../../domain/use_cases/user_service.dart';
import '../../utils/enums/itemlist_type.dart';
import '../../utils/enums/owner_type.dart';
import '../../utils/enums/subscription_level.dart';
import '../../utils/enums/user_role.dart';

/// Shared offline / guest [UserService] implementation for Open Neom host apps
/// that operate without a cloud Firebase session (e.g., Pakal, Blup offline
/// mode, and local widget/unit tests).
///
/// Host apps with device-specific offline persistence (such as Blup's sovereign
/// Ed25519 trust store) should extend this class rather than reimplementing the
/// entire [UserService] contract.
class LocalUserService implements UserService {
  LocalUserService({
    AppUser? initialUser,
    AppProfile? initialProfile,
    SubscriptionLevel initialSubscriptionLevel = SubscriptionLevel.freemium,
  })  : _user = initialUser ??
            AppUser(
              id: '',
              name: 'Invitado',
              email: '',
              userRole: UserRole.subscriber,
            ),
        _profile = initialProfile ??
            AppProfile(
              id: '',
              name: 'Invitado',
            ),
        _subscriptionLevel = initialSubscriptionLevel;

  AppUser _user;
  AppProfile _profile;
  AppProfile _newProfile = AppProfile();
  Collective _collective = Collective();
  UserSubscription? _userSubscription;
  SubscriptionLevel _subscriptionLevel;

  void updateLocalSubscriptionLevel(SubscriptionLevel level) {
    _subscriptionLevel = level;
  }

  void updateLocalUserRole(UserRole role) {
    _user.userRole = role;
  }

  @override
  AppUser get user => _user;
  @override
  set user(AppUser val) => _user = val;

  @override
  AppProfile get profile => _profile;
  @override
  set profile(AppProfile val) => _profile = val;

  @override
  AppProfile get newProfile => _newProfile;
  @override
  set newProfile(AppProfile val) => _newProfile = val;

  @override
  Collective get collective => _collective;
  @override
  set collective(Collective val) => _collective = val;

  @override
  UserSubscription? get userSubscription => _userSubscription;
  @override
  set userSubscription(UserSubscription? val) => _userSubscription = val;

  @override
  SubscriptionLevel get subscriptionLevel => _subscriptionLevel;

  @override
  OwnerType itemlistOwnerType = OwnerType.profile;

  ItemlistType? _currentItemlistType;
  @override
  ItemlistType? get currentItemlistType => _currentItemlistType;
  @override
  void setCurrentItemlistType(ItemlistType? type) => _currentItemlistType = type;

  @override
  bool get isNewUser => false;

  @override
  Future<void> createUser() async {}

  @override
  Future<void> removeAccount() async {
    _user = AppUser(id: '', name: '', email: '');
    _profile = AppProfile(id: '', name: '');
    _newProfile = AppProfile();
    _userSubscription = null;
    _subscriptionLevel = SubscriptionLevel.freemium;
  }

  @override
  Future<void> getUserFromFacebook(String fbAccessToken) async {}
  @override
  void getUserFromFirebase(fba.User fbaUser) {}
  @override
  Future<void> setUserById(String userId) async {}
  @override
  Future<void> setUserByEmail(String userEmail) async {}
  @override
  Future<void> changeProfile(AppProfile selectedProfile) async {}
  @override
  Future<void> createProfile() async {}
  @override
  Future<void> getProfiles() async {}
  @override
  Future<void> removeProfile() async {}
  @override
  Future<void> reloadProfileItemlists() async {}
  @override
  Future<void> loadProfileChambers() async {}
  @override
  void stopGoingToEvent(String eventId) {}
  @override
  void goingToEvent(String eventId) {}
  @override
  Future<void> addOrderId(String orderId) async {}
  @override
  Future<void> addBoughtItem(String itemId) async {}
  @override
  Future<void> updateCustomerId(String customerId) async {}
  @override
  Future<void> updateSubscriptionId(String subscriptionId) async {}
  @override
  Future<bool> updatePhoneNumber(String phone, String countryCode) async => true;
  @override
  Future<void> getUserSubscription() async {}
  @override
  Future<void> setUserSubscription(UserSubscription subscription) async {}
  @override
  Future<void> setIsVerified(bool isVerified) async {}
  @override
  Future<void> verifyLocation() async {}

  final StreamController<String> _postRemovedController =
      StreamController<String>.broadcast();

  @override
  Stream<String> get postRemovedStream => _postRemovedController.stream;

  @override
  void addPostToProfile(String postId) {
    _profile.posts ??= [];
    if (!_profile.posts!.contains(postId)) {
      _profile.posts!.add(postId);
    }
  }

  @override
  void removePostFromProfile(String postId, {String? ownerId}) {
    if (ownerId == null || ownerId.isEmpty || ownerId == _profile.id) {
      _profile.posts?.removeWhere((id) => id == postId);
    }
    _postRemovedController.add(postId);
  }
}
