
import '../model/instrument.dart';

abstract class InstrumentService {

  Future<void> loadInstruments();
  Future<void>  addInstrument(int index);
  Future<void> removeInstrument(int index);
  void makeMainInstrument(Instrument instrument);
  void sortFavInstruments();

  Map<String, Instrument> get instruments;
  Map<String, Instrument> get favInstruments;
  Map<String, Instrument> get sortedInstruments;

}
