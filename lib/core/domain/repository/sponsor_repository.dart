import 'dart:async';
import '../model/sponsor.dart';

abstract class SponsorRepository {

  Future<String> insert(Sponsor sponsor);
  Future<Map<String, Sponsor>> getSponsorsTimeline();
  Future<Map<String, Sponsor>> getNextSponsorsTimeline();

}
