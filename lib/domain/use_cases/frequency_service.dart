import '../model/neom/neom_frequency.dart';

abstract class FrequencyService {

  Map<String, NeomFrequency> get frequencies;

  Future<void> loadFrequencies();
  Future<void>  addFrequency(int index);
  Future<void> removeFrequency(int index);
  void makeMainFrequency(NeomFrequency frequency);
  void sortFavFrequencies();

}
