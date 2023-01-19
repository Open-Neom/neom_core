import '../../utils/enums/app_file_from.dart';
import '../../utils/enums/facilitator_type.dart';
import '../../utils/enums/place_type.dart';
import '../../utils/enums/profile_type.dart';
import '../../utils/enums/usage_reason.dart';

abstract class OnBoardingService {

  void setProfileType(ProfileType profileType);
  Future<void> addInstrumentIntro(int index);
  Future<void> removeInstrumentIntro(int index);
  void addInstrumentToProfile();
  void setReason(UsageReason reason);
  void handleImage(AppFileFrom appFileFrom);
  void setDateOfBirth(DateTime? pickedDate);
  void finishAccount();
  void setPlaceType(PlaceType placeType);
  void setFacilityType(FacilityType facilityTpe);
  void addGenresToProfile();
  Future<void> removeGenreIntro(int index);
  void setTermsAgreement(bool agree);
  Future<void> createAdditionalProfile();

}
