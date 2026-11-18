import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import '../../domain/model/account_load_exception.dart';
import '../../domain/model/app_profile.dart';
import '../../domain/model/app_user.dart';
import '../../domain/repository/account_repository.dart';
import '../../utils/enums/facilitator_type.dart';
import '../../utils/enums/profile_type.dart';
import '../../utils/enums/user_role.dart';
import 'app_data_api_client.dart';
import 'data_api_codec.dart';

class AppUserApi implements AccountRepository {
  AppUserApi({required this.client, required this.firebase});
  final AppDataApiClient client;
  final AccountRepository firebase;

  AppUser _decode(dynamic value, {bool withProfiles = false}) {
    if (value is! Map ||
        value['id'] is! String ||
        (value['id'] as String).isEmpty) {
      throw const FormatException('Expected an account ID');
    }
    final data = Map<String, dynamic>.from(value)..remove('password');
    final user = AppUser.fromJSON(data);
    final rawProfiles = data['profiles'];
    if (rawProfiles != null && rawProfiles is! List) {
      throw const FormatException('Expected account profiles');
    }
    user.profiles = <AppProfile>[];
    for (final raw in rawProfiles as List? ?? const []) {
      if (raw is! Map ||
          raw['id'] is! String ||
          (raw['id'] as String).isEmpty) {
        throw const FormatException('Expected an owned profile ID');
      }
      user.profiles.add(AppProfile.fromJSON(profileApiMap(raw)));
    }
    if (withProfiles && user.profiles.isEmpty) {
      throw const AccountLoadException();
    }
    if (user.currentProfileId.isNotEmpty) {
      final current = user.profiles
          .where((p) => p.id == user.currentProfileId)
          .firstOrNull;
      if (current != null) {
        user.profiles = [
          current,
          ...user.profiles.where((p) => p.id != current.id),
        ];
      }
    }
    return user;
  }

  Future<List<AppUser>> _users(
    String operation,
    Map<String, dynamic> arguments,
    Future<List<AppUser>> Function() fallback, {
    bool single = false,
    bool withProfiles = false,
  }) => client.read(
    operation,
    dataApiValue(arguments) as Map<String, dynamic>,
    fallback: fallback,
    referenceIds: (items) => items.map((u) => u.id),
    decode: (response) {
      final raw = response['items'];
      if (raw is! List) throw const FormatException('Expected accounts');
      if (single && raw.length > 1) throw const AccountLoadException();
      // During migration an unseeded local DB is not evidence of a new user.
      if (single && raw.isEmpty && response['authoritative'] != true) {
        throw const AppDataUnavailable();
      }
      return raw.map((v) => _decode(v, withProfiles: withProfiles)).toList();
    },
  );

  Future<T> _value<T>(
    String operation,
    Map<String, dynamic> args,
    Future<T> Function() fallback,
  ) => client.read(
    operation,
    dataApiValue(args) as Map<String, dynamic>,
    fallback: fallback,
    referenceIds: (_) => const [],
    decode: (r) => dataApiScalar<T>(r['value']),
  );
  Future<bool> _boolWrite(String operation, Map<String, dynamic> args) async =>
      dataApiScalar<bool>(
        await client.mutate(
          operation,
          dataApiValue(args) as Map<String, dynamic>,
          durable: operation != 'updateSpotifyToken',
        ),
      );
  Map<String, dynamic> _userJson(AppUser user) => {
    ...(Map<String, dynamic>.from(user.toJSON())..remove('spotifyToken')),
    'id': user.id,
    'currentProfileId': user.currentProfileId,
    'profiles': user.profiles.map((p) => p.toJSON()).toList(),
  };

  @override
  Future<AppUser> getById(
    String userId, {
    bool getProfileFeatures = false,
    bool throwOnError = false,
  }) async {
    if (userId.isEmpty) throw const AccountLoadException();
    final items = await _users(
      'getById',
      {'userId': userId, 'getProfileFeatures': getProfileFeatures},
      () async {
        final u = await firebase.getById(
          userId,
          getProfileFeatures: getProfileFeatures,
          throwOnError: true,
        );
        return u.id.isEmpty ? [] : [u];
      },
      single: true,
      withProfiles: true,
    );
    if (items.isNotEmpty && items.single.id != userId) {
      throw const AccountLoadException();
    }
    return items.firstOrNull ?? AppUser();
  }

  @override
  Future<AppUser?> getByEmail(
    String email, {
    bool getProfile = false,
    bool getProfileFeatures = false,
    bool throwOnError = false,
  }) async {
    if (email.trim().isEmpty) throw const AccountLoadException();
    final items = await _users(
      'getByEmail',
      {
        'email': email,
        'getProfile': getProfile,
        'getProfileFeatures': getProfileFeatures,
      },
      () async {
        final u = await firebase.getByEmail(
          email,
          getProfile: getProfile,
          getProfileFeatures: getProfileFeatures,
          throwOnError: true,
        );
        return u == null ? [] : [u];
      },
      single: true,
      withProfiles: getProfile,
    );
    if (items.isNotEmpty &&
        items.single.email.trim().toLowerCase() != email.trim().toLowerCase()) {
      throw const AccountLoadException();
    }
    return items.firstOrNull;
  }

  @override
  Future<AppUser> getByProfileId(String profileId) async {
    final items = await _users(
      'getByProfileId',
      {'profileId': profileId},
      () async {
        final u = await firebase.getByProfileId(profileId);
        return u.id.isEmpty ? [] : [u];
      },
      single: true,
    );
    return items.firstOrNull ?? AppUser();
  }

  @override
  Future<List<AppUser>> getAll() => _users('getAll', {}, firebase.getAll);
  @override
  Future<bool> insert(AppUser user) {
    if (user.id.isEmpty) throw ArgumentError('Account ID required');
    return _boolWrite('insert', {'user': _userJson(user)});
  }

  @override
  Future<String> insertWithProfile(AppUser user, AppProfile profile) async {
    if (user.id.isEmpty || user.id.contains('/')) {
      throw ArgumentError('Account ID required');
    }
    if (profile.id.isEmpty) profile.id = const Uuid().v4();
    final id = dataApiScalar<String>(
      await client.mutate('insertWithProfile', {
        'user': _userJson(user),
        'profile': profile.toJSON(),
      }),
    );
    if (id != profile.id) {
      throw const FormatException('Unexpected created profile ID');
    }
    user.currentProfileId = id;
    return id;
  }

  @override
  Future<AppProfile> updateCurrentProfile(
    String userId,
    String currentProfileId,
  ) async {
    final value = await client.mutate('updateCurrentProfile', {
      'userId': userId,
      'currentProfileId': currentProfileId,
    });
    if (value is! Map || value['id'] != currentProfileId) {
      throw const FormatException('Expected selected profile');
    }
    return AppProfile.fromJSON(profileApiMap(value));
  }

  @override
  Future<bool> remove(String userId) =>
      _boolWrite('remove', {'userId': userId});

  @override
  Future<bool> updateAndroidNotificationToken(String userId, String token) =>
      _boolWrite('updateAndroidNotificationToken', {
        'userId': userId,
        'token': token,
      });

  @override
  Future<bool> isAvailableEmail(String email) => _value<bool>(
    'isAvailableEmail',
    {'email': email},
    () => firebase.isAvailableEmail(email),
  );

  @override
  Future<bool> isAvailablePhone(String phoneNumber) => _value<bool>(
    'isAvailablePhone',
    {'phoneNumber': phoneNumber},
    () => firebase.isAvailablePhone(phoneNumber),
  );

  @override
  Future<bool> updatePhotoUrl(String userId, String photoUrl) =>
      _boolWrite('updatePhotoUrl', {'userId': userId, 'photoUrl': photoUrl});

  @override
  Future<bool> addOrderId({required String userId, required String orderId}) =>
      _boolWrite('addOrderId', {'userId': userId, 'orderId': orderId});

  @override
  Future<bool> removeOrderId({
    required String userId,
    required String orderId,
  }) => _boolWrite('removeOrderId', {'userId': userId, 'orderId': orderId});

  @override
  Future<bool> updateFcmToken(String userId, String fcmToken) =>
      _boolWrite('updateFcmToken', {'userId': userId, 'fcmToken': fcmToken});

  @override
  Future<String> retrieveFcmToken(String userId) => _value<String>(
    'retrieveFcmToken',
    {'userId': userId},
    () => firebase.retrieveFcmToken(userId),
  );

  @override
  Future<bool> updateSpotifyToken(String userId, String spotifyToken) =>
      _boolWrite('updateSpotifyToken', {
        'userId': userId,
        'spotifyToken': spotifyToken,
      });

  @override
  Future<void> updateLastTimeOn(String userId) async {
    await client.mutate(
      'updateLastTimeOn',
      dataApiValue({'userId': userId}) as Map<String, dynamic>,
    );
  }

  @override
  Future<List<AppUser>> getWithParameters({
    bool needsPhone = false,
    bool includeProfile = false,
    bool needsPosts = false,
    List<ProfileType>? profileTypes,
    FacilityType? facilityType,
    Position? currentPosition,
    int maxDistance = 30,
  }) => _users(
    'getWithParameters',
    {
      'needsPhone': needsPhone,
      'includeProfile': includeProfile,
      'needsPosts': needsPosts,
      'profileTypes': profileTypes,
      'facilityType': facilityType,
      'currentPosition': currentPosition,
      'maxDistance': maxDistance,
    },
    () => firebase.getWithParameters(
      needsPhone: needsPhone,
      includeProfile: includeProfile,
      needsPosts: needsPosts,
      profileTypes: profileTypes,
      facilityType: facilityType,
      currentPosition: currentPosition,
      maxDistance: maxDistance,
    ),
  );

  @override
  Future<List<String>> getFCMTokens() => client.read(
    'getFCMTokens',
    {},
    fallback: () => firebase.getFCMTokens(),
    referenceIds: (_) => const [],
    decode: (r) {
      final value = r['value'];
      if (value is! List || value.any((x) => x is! String)) {
        throw const FormatException('Expected token list');
      }
      return value.cast<String>();
    },
  );

  @override
  Future<bool> updateUserRole(String userId, UserRole userRole) =>
      _boolWrite('updateUserRole', {'userId': userId, 'userRole': userRole});

  @override
  Future<bool> addBoughtItem({
    required String userId,
    required String itemId,
  }) => _boolWrite('addBoughtItem', {'userId': userId, 'itemId': itemId});

  @override
  Future<bool> removeBoughtItem(String userId, String itemId) =>
      _boolWrite('removeBoughtItem', {'userId': userId, 'itemId': itemId});

  @override
  Future<void> updateCustomerId(String userId, String customerId) async {
    await client.mutate(
      'updateCustomerId',
      dataApiValue({'userId': userId, 'customerId': customerId})
          as Map<String, dynamic>,
    );
  }

  @override
  Future<void> updateSubscriptionId(
    String userId,
    String subscriptionId,
  ) async {
    await client.mutate(
      'updateSubscriptionId',
      dataApiValue({'userId': userId, 'subscriptionId': subscriptionId})
          as Map<String, dynamic>,
    );
  }

  @override
  Future<void> updatePhoneNumber(String userId, String phoneNumber) async {
    await client.mutate(
      'updatePhoneNumber',
      dataApiValue({'userId': userId, 'phoneNumber': phoneNumber})
          as Map<String, dynamic>,
    );
  }

  @override
  Future<void> updateCountryCode(String userId, String countryCode) async {
    await client.mutate(
      'updateCountryCode',
      dataApiValue({'userId': userId, 'countryCode': countryCode})
          as Map<String, dynamic>,
    );
  }

  @override
  Future<void> setIsVerified(String userId, bool isVerified) async {
    await client.mutate(
      'setIsVerified',
      dataApiValue({'userId': userId, 'isVerified': isVerified})
          as Map<String, dynamic>,
    );
  }
}
