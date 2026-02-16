
import '../../utils/enums/release_type.dart';
import '../model/band.dart';
import '../model/genre.dart';

abstract class ReleaseUploadService {

  Future<void> setReleaseType(ReleaseType releaseType);
  void addInstrument(int index);
  void removeInstrument(int index);
  Future<void> addInstrumentsToReleaseItem();
  Future<void> uploadReleaseItem();
  Future<void> createReleasePost();
  Future<void> getPublisherPlace(context);
  bool validateInfo();
  void setPublishedYear(int year);
  void setIsPhysical();
  void setIsAutoPublished();
  void setReleaseAuthor();
  void setReleaseTitle();
  void setReleaseDesc();
  bool validateNameDesc();
  Future<void> gotoReleaseSummary();
  Future<void> addReleaseCoverImg();
  void addGenre(Genre genre);
  void removeGenre(Genre genre);
  Future<void> addReleaseFile();
  Future<void> setAppReleaseItemsQty(int itemsQty);
  void setItemlistName();
  void setItemlistDesc();
  bool validateItemlistNameDesc();
  void setSelectedBand(Band band);
  void setAsSolo();

}
