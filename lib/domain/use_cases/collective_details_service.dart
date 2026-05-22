import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../model/app_media_item.dart';
import '../model/collective.dart';
import '../model/genre.dart';

abstract class CollectiveDetailsService {

  Future<void> getCollectiveMembers();
  Future<void> getCollectiveGenres();
  Iterable<Widget> get genreChips;
  void addGenre(Genre genre);
  void removeGenre(Genre genre);
  Widget getCollectiveImageWidget(BuildContext context);
  void getItemDetails(AppMediaItem appMediaItem);
  Future<void> retrieveCollectiveInformation();

  Collective get collective;

  String get collectiveId;
  set collectiveId(String id);

  bool get isLoading;
  set isLoading(bool loading);

}
