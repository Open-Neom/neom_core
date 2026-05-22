import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../model/collective.dart';
import '../model/genre.dart';

abstract class CollectiveService {

  void addInstrument(int index);
  void removeInstrument(int index);
  Future<void> retrieveCollectivesByProfile();
  Future<Map<String, Collective>> retrieveCollectives();
  void addGenre(Genre genre);
  void removeGenre(Genre genre);
  Widget getCoverImageWidget(BuildContext context);
  Future<void> removeCollective(Collective collective);
  void addCollective();
  void setCollective(Collective collective);
  void addCollectiveToProfile(Collective collective);
  void nextEventPage();

  Map<String, Collective> get collectives;

}
