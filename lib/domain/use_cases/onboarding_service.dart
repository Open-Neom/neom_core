import '../../utils/enums/facilitator_type.dart';
import '../../utils/enums/place_type.dart';
import '../../utils/enums/profile_type.dart';
import '../../utils/enums/usage_reason.dart';

abstract class OnBoardingService {

  void setProfileType(ProfileType profileType);
  void setReason(UsageReason reason);
  void handleImage();
  void setDateOfBirth(DateTime? pickedDate);
  void finishAccount();
  void setPlaceType(PlaceType placeType);
  void setFacilityType(FacilityType facilityTpe);
  void setTermsAgreement(bool agree);
  Future<void> createAdditionalProfile();
  Future<void> verifyPhone();
  Future<void> verifySmsCode();

}
