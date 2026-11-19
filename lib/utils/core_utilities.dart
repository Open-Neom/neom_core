import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../app_properties.dart';
import '../domain/model/app_media_item.dart';
import '../domain/model/app_profile.dart';
import '../domain/model/app_release_item.dart';
import '../domain/model/collective.dart';
import '../domain/model/collective_member.dart';
import '../domain/model/event.dart';
import '../domain/model/external_item.dart';
import '../domain/model/facility.dart';
import '../domain/model/genre.dart';
import '../domain/model/instrument.dart';
import '../domain/model/item_list.dart';
import '../domain/model/neom/neom_chamber.dart';
import '../domain/model/neom/neom_chamber_preset.dart';
import '../domain/model/place.dart';
import '../domain/model/post.dart';
import 'constants/data_assets.dart';
import 'enums/app_currency.dart';
import 'enums/app_item_state.dart';
import 'enums/itemlist_type.dart';
import 'enums/media_item_type.dart';
import 'enums/profile_type.dart';
import 'enums/release_type.dart';
import 'enums/usage_reason.dart';
import 'neom_error_logger.dart';
import 'neom_js_helper.dart';
import 'neom_logger.dart';
import 'platform/core_exit_app.dart';
import 'position_parser.dart';
import 'secure_logger.dart';


class CoreUtilities {
  static const int _maxInlineJsonSnapshotChars = 262144;

  @Deprecated('Use PositionParser.JSONtoPosition instead')
  // ignore: non_constant_identifier_names
  static Position JSONtoPosition(dynamic positionSnapshot) {
    return PositionParser.JSONtoPosition(positionSnapshot);
  }


  // ignore: non_constant_identifier_names
  static List<String> JSONtoItemIds(dynamic itemsIdsSnapshot) {
    if (itemsIdsSnapshot == null) return <String>[];
    try {
      dynamic decoded = itemsIdsSnapshot;
      if (itemsIdsSnapshot is String) {
        if (itemsIdsSnapshot.isEmpty ||
            itemsIdsSnapshot.length > _maxInlineJsonSnapshotChars) {
          return <String>[];
        }
        decoded = jsonDecode(itemsIdsSnapshot);
      }
      if (decoded is! Iterable) return <String>[];
      final itemIds = <String>[];
      for (final itemJSON in decoded.take(5000)) {
        if (itemJSON == null) continue;
        final id = itemJSON.toString().trim();
        if (id.isNotEmpty) itemIds.add(id);
      }
      return itemIds;
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'JSONtoItemIds',
      );
      return <String>[];
    }
  }

  // ignore: non_constant_identifier_names
  static List<AppMediaItem> JSONtoItemlistItems(dynamic itemsIdsSnapshot) {
    if (itemsIdsSnapshot == null) return <AppMediaItem>[];
    final itemlistItems = <AppMediaItem>[];
    try {
      dynamic decoded = itemsIdsSnapshot;
      if (itemsIdsSnapshot is String) {
        if (itemsIdsSnapshot.isEmpty ||
            itemsIdsSnapshot.length > _maxInlineJsonSnapshotChars) {
          return <AppMediaItem>[];
        }
        decoded = jsonDecode(itemsIdsSnapshot);
      }
      Iterable<dynamic>? rawItems;
      if (decoded is Iterable) {
        rawItems = decoded;
      } else if (decoded is Map) {
        final itemIdVal = decoded['itemId'];
        if (itemIdVal is Iterable) {
          rawItems = itemIdVal;
        } else if (itemIdVal != null && itemIdVal.toString().trim().isNotEmpty) {
          rawItems = <dynamic>[decoded];
        }
      }
      if (rawItems == null) return itemlistItems;
      for (final itemJSON in rawItems.take(5000)) {
        if (itemJSON is AppMediaItem) {
          itemlistItems.add(itemJSON);
        } else if (itemJSON is Map) {
          final id = (itemJSON['id'] ?? itemJSON['itemId'] ?? '')
              .toString()
              .trim();
          final rawState = itemJSON['itemState'] ?? itemJSON['state'];
          final state =
              rawState is num && rawState.toDouble().isFinite
                  ? rawState.toInt()
                  : 0;
          if (id.isNotEmpty) {
            itemlistItems.add(AppMediaItem(id: id, state: state));
          }
        }
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'JSONtoItemlistItems');
    }

    return itemlistItems;
  }

  static AppItemState getItemState(int itemState){

    AppItemState state = AppItemState.noState;
    switch (itemState) {
      case 0:
        state = AppItemState.noState;
        break;
      case 1:
        state = AppItemState.heardIt;
        break;
      case 2:
        state = AppItemState.learningIt;
        break;
      case 3:
        state = AppItemState.needToPractice;
        break;
      case 4:
        state = AppItemState.readyToPlay;
        break;
      case 5:
        state = AppItemState.knowByHeart;
        break;
    }

    return state;
  }

  static Map<String, AppMediaItem> getTotalMediaItems(Map<String, Itemlist> itemlists){
    Map<String, AppMediaItem> totalItems = {};

    itemlists.forEach((key, itemlist) {
      for (var appMediaItem in itemlist.appMediaItems ?? []) {
        totalItems[appMediaItem.id] = appMediaItem;
      }
    });

    return totalItems;
  }

  static Map<String, AppReleaseItem> getTotalReleaseItems(Map<String, Itemlist> itemlists){
    Map<String, AppReleaseItem> totalItems = {};

    itemlists.forEach((key, itemlist) {
      for (var appReleaseItem in itemlist.appReleaseItems ?? []) {
        totalItems[appReleaseItem.id] = appReleaseItem;
      }
    });

    return totalItems;
  }

  static Map<String, NeomChamberPreset> getTotalPresets(Map<String, NeomChamber> chambers){
    Map<String, NeomChamberPreset> totalPresets = {};

    chambers.forEach((key, chamber) {
      for (var preset in chamber.chamberPresets ?? []) {
        totalPresets[preset.id] = preset;
      }
    });

    return totalPresets;
  }

  static Map<String, ExternalItem> getTotalExternalItems(Map<String, Itemlist> itemlists){
    Map<String, ExternalItem> totalItems = {};

    itemlists.forEach((key, itemlist) {
      for (var externalItem in itemlist.externalItems ?? []) {
        totalItems[externalItem.id] = externalItem;
      }
    });

    return totalItems;
  }

  static int getTotalItemsQty(Map<String, Itemlist> itemlists){
    int totalItems = 0;

    itemlists.forEach((key, itemlist) {
      totalItems = totalItems + itemlist.getTotalItems();
    });

    return totalItems;
  }

  static String createCompositeInboxId(List<String> profileIds){
    StringBuffer compositeKeyBuffer = StringBuffer();
    for (var profileId in profileIds) {
      compositeKeyBuffer.write("${profileId}_");
    }
    return compositeKeyBuffer.toString();
  }

  static String getProfileMainFeature(AppProfile profile) {

    String profileMainFeature = "";

    switch(profile.type) {
      case(ProfileType.appArtist):
        profileMainFeature = getMainInstrument(profile.instruments ?? <String, Instrument>{});
        break;
      case(ProfileType.facilitator):
        profileMainFeature = getMainFacility(profile.facilities ?? <String, Facility>{});
        break;
      case(ProfileType.host):
        profileMainFeature = getMainPlace(profile.places ?? <String, Place>{});
        break;
      default:
        profileMainFeature = CoreUtilities.getMainGenre(profile.genres ?? <String, Genre>{});
        break;
    }


    return profileMainFeature.isNotEmpty ? profileMainFeature : profile.type.value;
  }


  static String getMainInstrument(Map<String, Instrument> instruments){

    if(instruments.isEmpty) return "";

    Instrument mainInstrument = Instrument();
    for (var element in instruments.values) {
      if(element.isMain) mainInstrument = element;
    }

    return mainInstrument.name.isNotEmpty ? mainInstrument.name : instruments.values.first.name;
  }


  static String getMainGenre(Map<String, Genre> genres) {

    if(genres.isEmpty) return "";

    Genre mainGenre = Genre();
    for (var element in genres.values) {
      if(element.isMain) mainGenre = element;
    }

    return mainGenre.name.isNotEmpty ? mainGenre.name : genres.values.first.name;
  }

  static String getMainPlace(Map<String, Place> places){

    if(places.isEmpty) return "";

    Place mainPlace = Place();

    for (var element in places.values) {
      if(element.isMain) mainPlace = element;
    }

    return mainPlace.type.name;
  }


  static String getMainFacility(Map<String, Facility> facilities){

    if(facilities.isEmpty) return "";

    Facility mainFacility = Facility();
    for (var element in facilities.values) {
      if(element.isMain) mainFacility = element;
    }

    return mainFacility.type.name;
  }

  static Future<List<Genre>> loadGenres() async {
    neomLogger.t("loadGenres");
    List<Genre> genreList = [];

    try {
      String genreStr = await rootBundle.loadString(DataAssets.genresJsonPath);
      List<dynamic> genresJSON = jsonDecode(genreStr);

      for (var genreJSON in genresJSON) {
        genreList.add(Genre.fromJsonDefault(genreJSON));
      }

      neomLogger.d("${genreList.length} loaded genres from json");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'loadGenres');
    }

    return genreList;
  }

  static Future<List<Genre>> loadReleaseGenres() async {
    neomLogger.t("loadReleaseGenres");
    List<Genre> genreList = [];

    try {
      String genreStr = await rootBundle.loadString(DataAssets.releaseGenresJsonPath);
      List<dynamic> genresJSON = jsonDecode(genreStr);

      for (var genreJSON in genresJSON) {
        genreList.add(Genre.fromJsonDefault(genreJSON));
      }

      neomLogger.d("${genreList.length} loaded release genres from json");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'loadReleaseGenres');
    }

    return genreList;
  }

  static Future<List<Genre>> loadReleaseSubgenres() async {
    neomLogger.t("loadReleaseSubgenres");
    List<Genre> genreList = [];

    try {
      String genreStr = await rootBundle.loadString(DataAssets.releaseSubgenresJsonPath);
      List<dynamic> genresJSON = jsonDecode(genreStr);

      for (var genreJSON in genresJSON) {
        genreList.add(Genre.fromJsonDefault(genreJSON));
      }

      neomLogger.d("${genreList.length} loaded release subgenres from json");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'loadReleaseSubgenres');
    }

    return genreList;
  }


  static Map<String, AppItemState> getItemMatches(Map<String, AppMediaItem> totalItems, List<String> profileItems) {
    neomLogger.t("Get Item Matches for ${totalItems.length} total items");
    Map<String, AppItemState> matchedItems = <String, AppItemState>{};

    try {
      totalItems.forEach((itemId, item) {
        if(profileItems.contains(itemId)) {
          matchedItems[itemId] = getItemState(item.state);
          neomLogger.t("Adding Item Id: $itemId - Name: ${item.name}");
        }
      });
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'getItemMatches');
    }
    neomLogger.d("Total ItemmMatches: ${matchedItems.length}");
    return matchedItems;
  }

  static Map<String, Instrument> getInstrumentMatches(Event event, Map<String,Instrument> profileInstruments) {
    Map<String, Instrument> matchedInstruments = <String, Instrument>{};

    try {
      for (var instrumentFulfillment in event.instrumentsFulfillment ?? []) {
        if(profileInstruments.containsKey(instrumentFulfillment.instrument.id)
            && !instrumentFulfillment.isFulfilled) {
          matchedInstruments[instrumentFulfillment.instrument.id] = instrumentFulfillment.instrument;
        }
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'getInstrumentMatches');
    }

    return matchedInstruments;
  }

  static List<Instrument> getCollectiveInstrumentMatches(Collective collective, Map<String,Instrument> profileInstruments) {

    List<Instrument> collectiveInstrumentMatches = [];

    try {
      for (var collectiveMember in collective.members!.values) {
        if(profileInstruments.containsKey(collectiveMember.instrument!.id)
            && collectiveMember.profileId.isEmpty) {
          collectiveInstrumentMatches.add(profileInstruments[collectiveMember.instrument!.id] ?? Instrument());
        }
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'getCollectiveInstrumentMatches');
    }

    return collectiveInstrumentMatches;
  }

  static Map<String, Instrument> getCollectiveMemberInstrumentMatches(List<CollectiveMember> collectiveMembers, Map<String,Instrument> profileInstruments) {

    Map<String, Instrument> collectiveInstrumentMatches = {};

    try {
      for (var collectiveMember in collectiveMembers) {
        if(profileInstruments.containsKey(collectiveMember.instrument!.id)
            && collectiveMember.profileId.isEmpty) {
          collectiveInstrumentMatches[profileInstruments[collectiveMember.instrument!.id]!.id] = profileInstruments[collectiveMember.instrument!.id] ?? Instrument();
        }
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'getCollectiveMemberInstrumentMatches');
    }

    return collectiveInstrumentMatches;
  }

  static bool fulfillmentMatchedRequirements({
    required Event event,
    required  Map<String, AppMediaItem> requiredItems,
    required  Map<String, AppItemState> matchedItems,
    required Map<String,Instrument> matchedInstruments,
    UsageReason profileReason = UsageReason.any,
    int profileDistanceKm = 0})
  {
    neomLogger.t("Fulfillment Matched Requirements");

    bool requirementsMatched = false;

    try {

      if(matchedInstruments.isNotEmpty && event.distanceKm >= profileDistanceKm) {
        if(requiredItems.isNotEmpty && matchedItems.isNotEmpty || requiredItems.isEmpty) {
          requirementsMatched = true;
        }

      }

    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'fulfillmentMatchedRequirements');
    }


    return requirementsMatched;
  }

  static final RegExp _forbiddenMediaUrlChars = RegExp(
    r'[\x00-\x20\x7F-\x9F\u0085\u061C\u200B-\u200F\u2028-\u202E\u2060-\u2064\u2066-\u2069\u3002\uFF0E\uFF61\uFEFF]',
  );
  static final RegExp _encodedControlOrBidiInUriRe = RegExp(
    r'%(?:0[0-9a-f]|1[0-9a-f]|7f|c2%(?:8[0-9a-f]|9[0-9a-f])|d8%9c|e2%80%(?:8[b-f]|a[8-e])|e2%81%(?:a[0-46-9])|ef%bb%bf)',
    caseSensitive: false,
  );

  static int? _parseIpv4Part(String s) {
    if (s.isEmpty) return null;
    if (s.startsWith('0x') || s.startsWith('0X')) {
      return int.tryParse(s.substring(2), radix: 16);
    }
    if (s.length > 1 && s.startsWith('0')) {
      return int.tryParse(s.substring(1), radix: 8);
    }
    return int.tryParse(s, radix: 10);
  }

  static List<int>? _tryParseIpv4Octets(String host) {
    if (host.isEmpty || host.contains(':')) return null;
    final parts = host.split('.');
    if (parts.isEmpty || parts.length > 4) return null;
    final nums = <int>[];
    for (final p in parts) {
      if (p.isEmpty || !RegExp(r'^(?:0[xX][0-9a-fA-F]+|[0-9]+)$').hasMatch(p)) {
        return null;
      }
      final v = _parseIpv4Part(p);
      if (v == null || v < 0) return null;
      nums.add(v);
    }
    int value32;
    if (nums.length == 1) {
      if (nums[0] > 0xFFFFFFFF) return null;
      value32 = nums[0];
    } else if (nums.length == 2) {
      if (nums[0] > 255 || nums[1] > 0xFFFFFF) return null;
      value32 = nums[0] * 0x1000000 + nums[1];
    } else if (nums.length == 3) {
      if (nums[0] > 255 || nums[1] > 255 || nums[2] > 0xFFFF) return null;
      value32 = nums[0] * 0x1000000 + nums[1] * 0x10000 + nums[2];
    } else {
      if (nums.any((n) => n > 255)) return null;
      return nums;
    }
    return <int>[
      (value32 ~/ 0x1000000) & 0xFF,
      (value32 ~/ 0x10000) & 0xFF,
      (value32 ~/ 0x100) & 0xFF,
      value32 & 0xFF,
    ];
  }

  static List<int>? _extractEmbeddedIpv4FromIpv6(String lower) {
    for (final prefix in const <String>[
      '::ffff:',
      '0:0:0:0:0:ffff:',
      '0000:0000:0000:0000:0000:ffff:',
      '64:ff9b::',
    ]) {
      if (lower.startsWith(prefix)) {
        final tail = lower.substring(prefix.length);
        final dotted = _tryParseIpv4Octets(tail);
        if (dotted != null) return dotted;
        final groups = tail.split(':');
        if (groups.length == 2) {
          final hi = int.tryParse(groups[0], radix: 16);
          final lo = int.tryParse(groups[1], radix: 16);
          if (hi != null && lo != null && hi <= 0xFFFF && lo <= 0xFFFF) {
            return <int>[(hi >> 8) & 0xFF, hi & 0xFF, (lo >> 8) & 0xFF, lo & 0xFF];
          }
        }
      }
    }
    if (lower.startsWith('2002:')) {
      final rest = lower.substring(5).split(':');
      if (rest.length >= 2 && rest[0].isNotEmpty && rest[1].isNotEmpty) {
        final hi = int.tryParse(rest[0], radix: 16);
        final lo = int.tryParse(rest[1], radix: 16);
        if (hi != null && lo != null && hi <= 0xFFFF && lo <= 0xFFFF) {
          return <int>[(hi >> 8) & 0xFF, hi & 0xFF, (lo >> 8) & 0xFF, lo & 0xFF];
        }
      }
    }
    return null;
  }

  /// Validates that [uri] is a public `http`/`https` media URL free of SSRF
  /// targets (loopback, RFC1918, CGNAT, IMDS, link-local, intranet single-label,
  /// userInfo, backslashes, or control/BiDi chars).
  static bool isSafePublicMediaUri(Uri? uri) {
    if (uri == null) return false;
    final raw = uri.toString();
    if (raw.isEmpty ||
        raw.length > 4096 ||
        raw.contains('\\') ||
        _forbiddenMediaUrlChars.hasMatch(raw) ||
        _encodedControlOrBidiInUriRe.hasMatch(raw)) {
      return false;
    }
    final scheme = uri.scheme.toLowerCase();
    if ((scheme != 'http' && scheme != 'https') || uri.userInfo.isNotEmpty) {
      return false;
    }
    final rawHost = uri.host.trim().toLowerCase();
    if (rawHost.isEmpty || rawHost.contains('%')) return false;
    final host = rawHost.startsWith('[') && rawHost.endsWith(']')
        ? rawHost.substring(1, rawHost.length - 1)
        : rawHost;
    if (host.isEmpty ||
        host == 'localhost' ||
        host == 'instance-data' ||
        host == 'metadata' ||
        host.startsWith('metadata.') ||
        host.endsWith('.localhost') ||
        host.endsWith('.local') ||
        host.endsWith('.internal') ||
        host.endsWith('.corp') ||
        host.endsWith('.lan') ||
        host.endsWith('.home.arpa') ||
        host.endsWith('.invalid') ||
        host.endsWith('.test') ||
        host.endsWith('.example') ||
        host.endsWith('.ts.net') ||
        host.endsWith('.onion') ||
        host.endsWith('.metadata.azure.com') ||
        host == 'metadata.google.internal' ||
        host == 'metadata.goog' ||
        host.endsWith('.')) {
      return false;
    }
    final v4 = _tryParseIpv4Octets(host) ?? _extractEmbeddedIpv4FromIpv6(host);
    if (v4 != null) {
      final a = v4[0];
      final b = v4[1];
      final c = v4[2];
      if (a == 0 || a == 10 || a == 127) return false;
      if (a == 169 && b == 254) return false;
      if (a == 172 && b >= 16 && b <= 31) return false;
      if (a == 192 && b == 168) return false;
      if (a == 192 && b == 0 && (c == 0 || c == 2)) return false;
      if (a == 198 && (b == 18 || b == 19)) return false;
      if (a == 198 && b == 51 && c == 100) return false;
      if (a == 203 && b == 0 && c == 113) return false;
      if (a == 100 && b >= 64 && b <= 127) return false;
      if (a >= 224) return false;
      if (!host.contains(':') &&
          !RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$').hasMatch(host)) {
        return false;
      }
      return true;
    }
    if (host.contains(':')) {
      if (host == '::' ||
          host == '::1' ||
          host == '0:0:0:0:0:0:0:0' ||
          host == '0:0:0:0:0:0:0:1' ||
          host.startsWith('2001:0:') ||
          host.startsWith('2001:0000:') ||
          host.startsWith('2001:db8:') ||
          host.startsWith('2001:0db8:') ||
          host.startsWith('fc') ||
          host.startsWith('fd') ||
          host.startsWith('ff') ||
          host.startsWith('fe8') ||
          host.startsWith('fe9') ||
          host.startsWith('fea') ||
          host.startsWith('feb')) {
        return false;
      }
      return true;
    }
    return host.contains('.');
  }

  /// Probes [uri] using `HEAD` (falling back to `Range: bytes=0-0` on `405`/`501`)
  /// with `followRedirects = false`, validating every redirect hop against
  /// [isSafePublicMediaUri] without buffering full media files into RAM.
  static Future<bool> probePublicMediaUrlAvailable(
    String rawMediaUrl, {
    http.Client? injectedClient,
  }) async {
    final initial = Uri.tryParse(rawMediaUrl.trim());
    if (!isSafePublicMediaUri(initial)) return false;

    final client = injectedClient ?? http.Client();
    try {
      var current = initial!;
      for (var hop = 0; hop <= 3; hop++) {
        final headReq = http.Request('HEAD', current)..followRedirects = false;
        final headResp =
            await client.send(headReq).timeout(const Duration(seconds: 6));
        final code = headResp.statusCode;
        // Cancel immediately rather than draining so a rogue server returning
        // an unbounded body on HEAD cannot stall or exhaust RAM.
        final headSub = headResp.stream.listen((_) {});
        await headSub.cancel();

        if (code == 200 || code == 206) {
          return true;
        }
        if (code == 301 || code == 302 || code == 303 || code == 307 || code == 308) {
          if (hop == 3) return false;
          final loc = headResp.headers['location']?.trim();
          if (loc == null || loc.isEmpty) return false;
          final parsedLoc = Uri.tryParse(loc);
          if (parsedLoc == null) return false;
          final next = current.resolveUri(parsedLoc);
          if (!isSafePublicMediaUri(next)) return false;
          if (current.scheme == 'https' && next.scheme != 'https') return false;
          current = next;
          continue;
        }
        if (code == 405 || code == 501) {
          final getReq = http.Request('GET', current)
            ..followRedirects = false
            ..headers['Range'] = 'bytes=0-0';
          final getResp =
              await client.send(getReq).timeout(const Duration(seconds: 6));
          final getStatus = getResp.statusCode;
          // Consume at most the first chunk then cancel subscription to avoid full download.
          final sub = getResp.stream.listen((_) {});
          await sub.cancel();
          return getStatus == 200 || getStatus == 206;
        }
        return false;
      }
      return false;
    } finally {
      if (injectedClient == null) {
        client.close();
      }
    }
  }

  Future<bool> isAvailableMediaUrl(String mediaUrl) async {
    neomLogger.t(
      'Verifying if mediaUrl is available: ${SecureLogger.sanitize(mediaUrl)}',
    );

    try {
      return await probePublicMediaUrlAvailable(mediaUrl);
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'isAvailableMediaUrl');
      return false;
    }
  }


  Future<Post> verifyPostMediaUrls(Post post) async {
    if(post.profileImgUrl.isEmpty || !await isAvailableMediaUrl(post.profileImgUrl)) {
      post.profileImgUrl = AppProperties.getNoImageUrl();
    }

    if(post.mediaUrl.isEmpty || !await isAvailableMediaUrl(post.mediaUrl)) {
      post.mediaUrl = AppProperties.getNoImageUrl();
    }

    if(post.thumbnailUrl.isEmpty || !await isAvailableMediaUrl(post.thumbnailUrl)) {
      post.thumbnailUrl = AppProperties.getNoImageUrl();
    }

    return post;
  }


  static String getCurrencySymbol(AppCurrency currency) {
    String currencySymbol = "\u{0024}";
    switch(currency) {
      case (AppCurrency.mxn):
        currencySymbol = "\u{0024}";
        break;
      case (AppCurrency.appCoin):
        currencySymbol = "\u{0024}";
        break;
      case (AppCurrency.usd):
        currencySymbol = "\u{0024}";
        break;
      case (AppCurrency.eur):
        currencySymbol = "\u{20AC}";
        break;
      case (AppCurrency.gbp):
        currencySymbol = "\u{00A3}";
        break;
    }

    return currencySymbol;
  }

  static Map<double, AppProfile> sortProfilesByLocation(
    Position currentPosition,
    List<AppProfile> profiles,
  ) {
    final sortedProfiles = SplayTreeMap<double, AppProfile>();
    if (!currentPosition.latitude.isFinite ||
        !currentPosition.longitude.isFinite) {
      return <double, AppProfile>{};
    }

    int tieIndex = 0;
    for (final mate in profiles) {
      final pos = mate.position;
      if (pos == null || !pos.latitude.isFinite || !pos.longitude.isFinite) {
        continue;
      }
      final rawDistanceKm = Geolocator.distanceBetween(
            currentPosition.latitude.clamp(-90.0, 90.0),
            currentPosition.longitude.clamp(-180.0, 180.0),
            pos.latitude.clamp(-90.0, 90.0),
            pos.longitude.clamp(-180.0, 180.0),
          ) /
          1000.0;
      if (!rawDistanceKm.isFinite) continue;
      tieIndex++;
      var key = rawDistanceKm + (tieIndex * 1e-9);
      while (sortedProfiles.containsKey(key)) {
        tieIndex++;
        key = rawDistanceKm + (tieIndex * 1e-9);
      }
      sortedProfiles[key] = mate;
    }

    neomLogger.d("Sorted Profiles ${sortedProfiles.length}");
    return Map<double, AppProfile>.from(sortedProfiles);
  }

  static Map<String, AppProfile> sortProfilesByName(List<AppProfile> profiles) {
    final sortedProfiles = List<AppProfile>.of(profiles)
      ..sort((a, b) => a.name.compareTo(b.name));

    Map<String, AppProfile> profileMap = LinkedHashMap.fromIterable(
      sortedProfiles,
      key: (profile) => profile.name,
      value: (profile) => profile,
    );

    return profileMap;
  }

  static List<Itemlist> filterItemlists(List<Itemlist> lists, ItemlistType type) {
    if (lists.isEmpty) return [];

    final filtered = List<Itemlist>.from(lists);
    if (type == ItemlistType.giglist) {
      filtered.removeWhere((list) => list.type != ItemlistType.giglist);
    } else if (type.isStreamableAudio) {
      filtered.removeWhere((list) => !list.type.isStreamableAudio);
    } else {
      filtered.removeWhere((list) => list.type != type);
    }

    return filtered;
  }

  /// Normalizes a song title + artist into a canonical repertoire match key.
  /// Mirrors `normalizeSongMatchKey` in Gigmeout's platform server so Firebase
  /// and own-server Songmate matching produce identical results.
  static String normalizeSongMatchKey(String title, [String artist = '']) {
    String cleanChannel(String raw) => raw
        .replaceAll(RegExp(r'\s*-\s*topic\s*$', caseSensitive: false), '')
        .replaceAll(RegExp(r'vevo\s*$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+(?:official|oficial|music)\s*$', caseSensitive: false), '')
        .trim();

    String stripAccents(String s) {
      const from = 'áàäâãéèëêíìïîóòöôõúùüûñçÁÀÄÂÃÉÈËÊÍÌÏÎÓÒÖÔÕÚÙÜÛÑÇ';
      const to = 'aaaaaeeeeiiiiooooouuuuncAAAAAEEEEIIIIOOOOOUUUUNC';
      final sb = StringBuffer();
      for (var i = 0; i < s.length; i++) {
        final idx = from.indexOf(s[i]);
        sb.write(idx >= 0 ? to[idx] : s[i]);
      }
      return sb.toString();
    }

    String cleanPart(String raw) => stripAccents(raw.toLowerCase())
        .replaceAll(
          RegExp(
            r'\((?:official|oficial|video|audio|lyric|lyrics|remaster(?:ed|izado)?|live|hd|4k|en vivo|letra|visualizer|acustico|acoustic)[^)]*\)',
            caseSensitive: false,
          ),
          ' ',
        )
        .replaceAll(
          RegExp(
            r'\[(?:official|oficial|video|audio|lyric|lyrics|remaster(?:ed|izado)?|live|hd|4k|en vivo|letra|visualizer|acustico|acoustic)[^\]]*\]',
            caseSensitive: false,
          ),
          ' ',
        )
        .replaceAll(
          RegExp(
            r'\b(?:official\s+music\s+video|video\s+oficial|audio\s+oficial|official\s+video|official\s+audio|lyric\s+video|remastered\s*\d*)\b',
            caseSensitive: false,
          ),
          ' ',
        )
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');

    var rawTitle = title.trim();
    var rawArtist = cleanChannel(artist);
    var aCompact = cleanPart(rawArtist).replaceAll('-', '');

    final dashIdx = rawTitle.indexOf(' - ');
    if (dashIdx > 0) {
      final left = rawTitle.substring(0, dashIdx).trim();
      final right = rawTitle.substring(dashIdx + 3).trim();
      final leftCompact = cleanPart(cleanChannel(left)).replaceAll('-', '');
      if (right.isNotEmpty && (aCompact.isEmpty || leftCompact == aCompact)) {
        rawTitle = right;
        if (aCompact.isEmpty) aCompact = leftCompact;
      }
    }

    final t = cleanPart(rawTitle);
    if (t.isEmpty) return '';
    return aCompact.isNotEmpty ? '$t::$aCompact' : t;
  }

  static const Set<String> _sharedMultiTenantSuffixes = <String>{
    'github.io',
    'gitlab.io',
    'pages.dev',
    'web.app',
    'firebaseapp.com',
    'appspot.com',
    'run.app',
    'cloudfunctions.net',
    'vercel.app',
    'netlify.app',
    'herokuapp.com',
    'co.uk',
    'org.uk',
    'com.mx',
    'org.mx',
    'gob.mx',
  };

  static String? _extractDomainHost(String rawConfigValue) {
    final trimmed = rawConfigValue.trim().toLowerCase();
    if (trimmed.isEmpty) return null;
    if (trimmed.contains('://')) {
      final parsed = Uri.tryParse(trimmed);
      if (parsed == null || parsed.host.isEmpty) return null;
      return parsed.host.toLowerCase();
    }
    final withoutPath = trimmed.split('/').first.split(':').first.trim();
    if (withoutPath.isEmpty || !withoutPath.contains('.')) return null;
    return withoutPath;
  }

  @visibleForTesting
  static bool isInternalUrlForDomains(
    String url,
    Iterable<String> trustedDomainsOrBuckets,
  ) {
    final trimmed = url.trim();
    if (trimmed.isEmpty ||
        trimmed.length > 4096 ||
        trimmed.contains('\\') ||
        _forbiddenMediaUrlChars.hasMatch(trimmed)) {
      return false;
    }
    final uri = Uri.tryParse(trimmed);
    if (!isSafePublicMediaUri(uri)) return false;
    final scheme = uri!.scheme.toLowerCase();
    final host = uri.host.trim().toLowerCase();
    if (host.isEmpty) return false;

    for (final raw in trustedDomainsOrBuckets) {
      final cleanRaw = raw.trim().toLowerCase();
      if (cleanRaw.isEmpty) continue;
      // Support Firebase Storage bucket URLs (`https://firebasestorage.googleapis.com/v0/b/<bucket>/...`)
      if (scheme == 'https' &&
          host == 'firebasestorage.googleapis.com' &&
          cleanRaw.contains('.') &&
          !cleanRaw.contains('://') &&
          uri.pathSegments.length >= 3 &&
          uri.pathSegments[0] == 'v0' &&
          uri.pathSegments[1] == 'b' &&
          uri.pathSegments[2].toLowerCase() == cleanRaw) {
        return true;
      }
      final configuredHost = _extractDomainHost(cleanRaw);
      if (configuredHost == null ||
          _sharedMultiTenantSuffixes.contains(configuredHost)) {
        continue;
      }
      if (cleanRaw.contains('://')) {
        final configuredUri = Uri.tryParse(cleanRaw);
        if (configuredUri == null) continue;
        final configuredScheme = configuredUri.scheme.toLowerCase();
        if (configuredScheme == 'https' && scheme != 'https') {
          continue;
        }
      }
      if (host == configuredHost || host.endsWith('.$configuredHost')) {
        final trustedOriginUrl = cleanRaw.contains('://')
            ? cleanRaw
            : '$scheme://$configuredHost';
        if (NeomJsHelper.isSameSiteWebUrl(trimmed, trustedOriginUrl)) {
          return true;
        }
      }
    }
    return false;
  }

  static bool isInternal(String url) {
    return isInternalUrlForDomains(url, <String>[
      AppProperties.getSiteUrl(),
      AppProperties.getHubName(),
      AppProperties.getStorageServerName(),
    ]);
  }

  static const int _maxSafeEpochMs = 8640000000000000;

  static bool isWithinFirstMonth(int createdTime) {
    if (!createdTime.toDouble().isFinite ||
        createdTime <= 0 ||
        createdTime > _maxSafeEpochMs) {
      return false;
    }
    DateTime creationDate = DateTime.fromMillisecondsSinceEpoch(createdTime);
    DateTime now = DateTime.now();

    DateTime dateOneMonthLater = DateTime(
      creationDate.year,
      creationDate.month + 1,
      creationDate.day,
    );

    return now.isBefore(dateOneMonthLater);
  }

  static void exitApp() {
    coreExitApp();
  }

  static MediaItemType getMediaItemType(AppReleaseItem releaseItem) {

    MediaItemType itemType = MediaItemType.song;

    switch (releaseItem.type) {
      case ReleaseType.single:
        if (releaseItem.previewUrl.toLowerCase().endsWith('.pdf')) {
          itemType =  MediaItemType.pdf;
        }
        break;
      case ReleaseType.episode:
        itemType = MediaItemType.podcast;
      case ReleaseType.chapter:
        itemType = MediaItemType.audiobook;
      case ReleaseType.artwork:
        itemType = MediaItemType.artwork;
      default:
        itemType = MediaItemType.song;
    }

    return itemType;
  }

}
