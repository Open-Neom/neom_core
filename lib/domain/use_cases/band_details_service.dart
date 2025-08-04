import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../model/app_media_item.dart';
import '../model/band.dart';
import '../model/genre.dart';

abstract class BandDetailsService {

  Future<void> getBandMembers();
  Future<void> getBandGenres();
  Iterable<Widget> get genreChips;
  void addGenre(Genre genre);
  void removeGenre(Genre genre);
  Widget getBandImageWidget(BuildContext context);
  void getItemDetails(AppMediaItem appMediaItem);
  Future<void> retrieveBandInformation();

  Band get band;

  String get bandId;
  set bandId(String id);

  bool get isLoading;
  set isLoading(bool loading);

}
