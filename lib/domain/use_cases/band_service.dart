import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../model/band.dart';
import '../model/genre.dart';

abstract class BandService {

  void addInstrument(int index);
  void removeInstrument(int index);
  Future<void> retrieveBandsByProfile();
  Future<Map<String, Band>> retrieveBands();
  void addGenre(Genre genre);
  void removeGenre(Genre genre);
  Widget getCoverImageWidget(BuildContext context);
  Future<void> removeBand(Band band);
  void addBand();
  void setBand(Band band);
  void addBandToProfile(Band band);
  void nextEventPage();

  Map<String, Band> get bands;

}
