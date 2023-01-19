import 'package:enum_to_string/enum_to_string.dart';

import '../../utils/enums/user_role.dart';
import 'app_profile.dart';
import 'wallet.dart';

class AppUser {

  String id;
  String name;
  String firstName;
  String lastName;
  String dateOfBirth;
  String homeTown;
  String phoneNumber;
  String countryCode;

  String password;
  String email;
  String photoUrl;
  UserRole userRole;
  bool isPremium;
  bool isVerified;
  bool isBanned;

  String androidNotificationToken;
  List<AppProfile> profiles;

  Wallet wallet = Wallet();
  List<String> orderIds = [];

  //TODO
  //Add read of this values from documentSnapshot
  String referralCode = "";
  int createdDate = 0;
  int lastTimeOn = 0;

  String fcmToken;
  String spotifyToken;
  String currentProfileId;

  AppUser({
      this.id = "",
      this.name = "",
      this.firstName = "",
      this.lastName = "",
      this.dateOfBirth = "",
      this.homeTown = "",
      this.phoneNumber = "",
      this.countryCode = "",
      this.password = "",
      this.email = "",
      this.photoUrl = "",
      this.userRole = UserRole.subscriber,
      this.isPremium = false,
      this.isVerified = false,
      this.isBanned = false,
      this.androidNotificationToken = "",
      this.profiles = const [],
      this.orderIds = const [],
      this.referralCode = "",
      this.createdDate = 0,
      this.lastTimeOn = 0,
      this.fcmToken = "",
      this.spotifyToken = "",
      this.currentProfileId = "",
  });


  @override
  String toString() {
    return 'AppUser{id: $id, name: $name, firstName: $firstName, lastName: $lastName, dateOfBirth: $dateOfBirth, homeTown: $homeTown, phoneNumber: $phoneNumber, countryCode: $countryCode, password: $password, email: $email, photoUrl: $photoUrl, userRole: $userRole, isPremium: $isPremium, isVerified: $isVerified, isBanned: $isBanned, androidNotificationToken: $androidNotificationToken, profiles: $profiles, wallet: $wallet, orderIds: $orderIds, referralCode: $referralCode, createdDate: $createdDate, lastTimeOn: $lastTimeOn, fcmToken: $fcmToken, spotifyToken: $spotifyToken, currentProfileId: $currentProfileId}';
  }

  AppUser.fromJSON(data) :
        id = data["id"] ?? "",
        name = data["name"] ?? "",
        firstName = data["firstName"] ?? "",
        lastName = data["lastName"] ?? "",
        dateOfBirth = data["dateOfBirth"] ?? "",
        homeTown = data["homeTown"] ?? "",
        phoneNumber = data["phoneNumber"] ?? "",
        countryCode = data["countryCode"] ?? "",
        password = data["password"] ?? "",
        email = data["email"] ?? "",
        photoUrl = data["photoUrl"] ?? "",
        userRole =  EnumToString.fromString(UserRole.values, data["userRole"] ?? UserRole.subscriber.name) ?? UserRole.subscriber,
        isPremium = data["isPremium"] ?? true,
        isVerified = data["isPremium"] ?? true,
        isBanned = data["isBanned"] ?? true,
        androidNotificationToken = data["androidNotificationToken"] ?? "",
        profiles = [],
        wallet = Wallet.fromJSON(data["wallet"] ?? {}),
        orderIds = data["orderIds"]?.cast<String>() ?? [],
        referralCode = data["referralCode"] ?? "",
        createdDate = data["createdDate"] ?? 0,
        lastTimeOn = data["lastTimeOn"] ?? 0,
        fcmToken = data["fcmToken"] ?? "",
        spotifyToken = data["spotifyToken"] ?? "",
        currentProfileId = data["currentProfileId"] ?? "";

  AppUser.fromFbProfile(profile) :
    id = profile["id"],
    name = profile["name"],
    firstName = profile["first_name"],
    lastName = profile["last_name"],
    password = "",
    email = profile["email"],
    photoUrl = profile['picture']['data']['url'],
    userRole = UserRole.subscriber,
    dateOfBirth = "",
    homeTown = "",
    phoneNumber = "",
    countryCode = "",
    isBanned = false,
    isPremium = false,
    isVerified = false,
    androidNotificationToken = "",
    profiles = [],
    orderIds = [],
    referralCode = "",
    fcmToken = "",
    spotifyToken = "",
    currentProfileId = "";


  Map<String, dynamic> toJSON() {
    return <String, dynamic>{
      //'id': id, //not needed at firebase
      'name': name,
      'firstName': firstName,
      'lastName': lastName,
      'dateOfBirth': dateOfBirth,
      'homeTown': homeTown,
      'password': password,
      'email': email,
      'phoneNumber': phoneNumber,
      'countryCode': countryCode,
      'photoUrl': photoUrl,
      'userRole': userRole.name,
      'isPremium': isPremium,
      'isVerified': isVerified,
      'isBanned': isBanned,
      'androidNotificationToken': androidNotificationToken,
      'wallet': wallet.toJSON(),
      'orderIds': orderIds,
      'referralCode': referralCode,
      'createdDate': createdDate,
      'lastTimeOn': lastTimeOn,
      'fcmToken': fcmToken,
      'spotifyToken': spotifyToken,
    };
  }

  Map<String, dynamic> toInvoiceJSON() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'firstName': firstName,
      'lastName': lastName,
      'dateOfBirth': dateOfBirth,
      'homeTown': homeTown,
      'email': email,
      'phoneNumber': phoneNumber,
      'countryCode': countryCode,
      'photoUrl': photoUrl
    };
  }

}
