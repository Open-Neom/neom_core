import 'package:enum_to_string/enum_to_string.dart';

import '../../utils/enums/media_item_type.dart';
import '../../utils/enums/owner_type.dart';
import '../../utils/enums/release_status.dart';
import '../../utils/enums/release_type.dart';
import 'ia_info.dart';
import 'place.dart';
import 'playable_item.dart';
import 'price.dart';

class AppReleaseItem implements PlayableItem {

  String id; ///ID FOR ITEM ON DB OR WC
  String name; ///NAME OF ITEM
  String description; ///DESCRIPTION OF ITEM
  String imgUrl; ///COVER IMAGE
  List<String>? galleryUrls; ///FIRST IMAGE ON GALLERY MUST BE OwnerImgUrl
  String previewUrl; ///URL WITH FILE
  int duration; ///SECONDS - NUMBER OF PAGES - ETC

  ReleaseType type; ///RELEASE TYPE TO HANDLE FURTHER FEATURES
  ReleaseStatus status;
  MediaItemType? mediaType;

  String ownerEmail; ///EMAIL OF USER ON APP
  String ownerName; ///NAME OF PROFILE ON APP
  OwnerType ownerType; ///TO KNOW IF RELEASE WAS UPLOADED FROM USER OR BAND TO FLOW

  List<String> categories; ///CATEGORIES OR GENRES FOR BOOKS | SONGS | PODCASTS | CATEGORIES RETRIEVED FROM WC
  List<String>? tags; ///CATEGORIES OR GENRES FOR BOOKS | SONGS | PODCASTS | CATEGORIES RETRIEVED FROM WC

  String? metaId; ///ID OF ITEMLIST CREATED TO INCLUDE ITEMS IN CASE OF INCLUDING MORE ON SAME
  String? metaName; ///ITEMLIST NAME
  String? metaOwnerId; ///EMAIL USED TO UPLOAD ITEM FROM APP OR WC
  String? metaOwner; ///NAME OF PUBLISHER OR META OWNER

  List<String>? instruments; ///INSTRUMENTS USED ON RELEASE - IT DEPENDS OF THE APP

  String? lyrics; ///LYRICS FOR SONGS
  String? language; ///SPANISH - ENGLISH - ETC

  Price? digitalPrice; ///PRICE FOR DIGITAL ITEM  - IF NOT NULL ITEM IS AVAILABLE AS DIGITAL
  Price? physicalPrice; ///PRICE IN CASE ITEM HAS A PHYSICAL VERSION AS WELL - IF NOT NULL ITEM IS AVAILABLE AS PHYSICAL
  Price? salePrice; ///SALE PRICE FOR ITEM AFTER ANY DISCOUNT
  List<String>? variations; ///VARIATION IDS FOR CASES WHEN ITEM HAS DIFFERENT SUBITEMS
  bool isRental; ///Verify if item is elegible for unlimited access for members

  int? publishedYear; ///YEAR OF PUBLISHIN FOR ITEMS PUBLISHED PREVIOUSLY OUTSIDE THE PLATFORM.
  Place? place; ///PLACE OR LOCATION FOR METAOWNER IF ABLE.

  List<String>? boughtUsers; ///PROFILEID OR EMAIL OF USERS WHO BOUGHT THIS ITEM - IT ALSO IS USEFUL TO KNOW TOTAL SALES WITH LIST.LENGHT

  int createdTime; ///CREATED TIME ON PLATFORM
  int? modifiedTime; ///TIME OF LAST MODIFICATION

  int state; ///STATE FOR USERS WHEN THE SAVE ITEM ON ITEMLISTS - FROM O to 5

  List<String>? externalArtists; ///Out of the app
  Map<String, String>? featInternalArtists; ///key: artistId - value: name
  List<String>? likedProfiles; ///LIST OF PROFILEIDS IN CASE OF MORE DETAILS. ALSO TO KNOW NUMBER OF LIKES WITH LIST.LENGHT

  String? externalUrl; ///URL FOR ITEM IN WEB
  String? webPreviewUrl; ///URL FOR Preview IN WEB

  /// AI assistant configuration for this item
  IaInfo? iaInfo;

  /// URL slug for vanity URLs (e.g., emxi.org/quemando-mis-razones)
  String slug;

  /// Content moderation fields
  bool isSuspended;
  String? suspendedBy;
  String? suspendedReason;

  // ── Playback fields (for PlayableItem interface) ──
  /// Streaming URL for audio/video playback (same as previewUrl for most items).
  String? streamingUrl;
  /// Track number within an album/itemlist.
  int? trackNumber;
  /// Disc number for multi-disc releases.
  int? discNumber;
  /// Audio quality (0=low, 5=lossless).
  int? quality;
  /// Local file path for offline playback.
  String? localPath;
  /// Owner profile ID (for internal routing).
  String? ownerProfileId;
  /// Total page views (books/articles).
  int totalPageViews;

  // ── PlayableItem interface implementation ──
  @override
  String get streamUrl => streamingUrl ?? previewUrl;
  @override
  bool get isInternal => true;
  @override
  String get ownerId => ownerProfileId ?? ownerEmail;
  @override
  String get displayDuration {
    if (duration <= 0) return '';
    final d = Duration(seconds: duration);
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return h > 0
        ? '${h}h ${m.toString().padLeft(2, '0')}m'
        : '${m}:${s.toString().padLeft(2, '0')}';
  }

  AppReleaseItem({
    this.id = '',
    this.name = '',
    this.description = '',
    this.imgUrl = '',
    this.galleryUrls,
    this.previewUrl = '',
    this.duration = 0,
    this.type = ReleaseType.single,
    this.status = ReleaseStatus.draft,
    this.mediaType,
    this.ownerEmail = '',
    this.ownerName = '',
    this.ownerType = OwnerType.notDefined,
    this.categories = const [],
    this.tags = const [],
    this.metaId,
    this.metaName,
    this.metaOwnerId,
    this.instruments,
    this.lyrics,
    this.language,
    this.digitalPrice,
    this.physicalPrice,
    this.salePrice,
    this.variations,
    this.isRental = true,
    this.publishedYear,
    this.metaOwner,
    this.place,
    this.boughtUsers,
    this.createdTime = 0,
    this.modifiedTime,
    this.state = 0,
    this.externalArtists,
    this.featInternalArtists,
    this.likedProfiles,
    this.externalUrl,
    this.webPreviewUrl,
    this.iaInfo,
    this.slug = '',
    this.isSuspended = false,
    this.suspendedBy,
    this.suspendedReason,
    this.streamingUrl,
    this.trackNumber,
    this.discNumber,
    this.quality,
    this.localPath,
    this.ownerProfileId,
    this.totalPageViews = 0,
  });

  @override
  String toString() {
    return 'AppReleaseItem{id: $id, name: $name, description: $description, imgUrl: $imgUrl, galleryUrls: $galleryUrls, previewUrl: $previewUrl, duration: $duration, type: $type, status: $status, ownerEmail: $ownerEmail, ownerName: $ownerName, ownerType: $ownerType, categories: $categories, metaId: $metaId, metaName: $metaName, metaOwnerId: $metaOwnerId, instruments: $instruments, lyrics: $lyrics, language: $language, digitalPrice: $digitalPrice, physicalPrice: $physicalPrice, variations: $variations, publishedYear: $publishedYear, metaOwner: $metaOwner, place: $place, boughtUsers: $boughtUsers, createdTime: $createdTime, modifiedTime: $modifiedTime, state: $state, externalArtists: $externalArtists, featInternalArtists: $featInternalArtists, likedProfiles: $likedProfiles, externalUrl: $externalUrl}';
  }

  AppReleaseItem.fromJSON(dynamic data) :
        id = data["id"] ?? '',
        name = data["name"] ?? '',
        description = data["description"] ?? '',
        imgUrl = data["imgUrl"] ?? '',
        galleryUrls = List.from(data["galleryUrls"]?.cast<String>() ?? []),
        previewUrl = data["previewUrl"] ?? '',
        duration = data["duration"] ?? 0,
        type = EnumToString.fromString(ReleaseType.values, data["type"] ?? ReleaseType.single.name) ?? ReleaseType.single,
        status = EnumToString.fromString(ReleaseStatus.values, data["status"] ?? ReleaseStatus.draft.name) ?? ReleaseStatus.draft,
        mediaType = EnumToString.fromString(MediaItemType.values, data["mediaType"] ?? ''),
        ownerEmail = data["ownerEmail"] ?? '',
        ownerName = data["ownerName"] ?? '',
        ownerType = EnumToString.fromString(OwnerType.values, data["ownerType"] ?? OwnerType.notDefined.name) ?? OwnerType.notDefined,
        categories = List.from(data["categories"]?.cast<String>() ?? []),
        tags = List.from(data["tags"]?.cast<String>() ?? []),
        metaId = data["metaId"] ?? '',
        metaName = data["metaName"] ?? '',
        metaOwnerId = data["metaOwnerId"] ?? '',
        instruments = List.from(data["instruments"]?.cast<String>() ?? []),
        lyrics = data["lyrics"] ?? '',
        language = data["language"] ?? '',
        digitalPrice = Price.fromJSON(data["digitalPrice"] ?? {}),
        physicalPrice = Price.fromJSON(data["physicalPrice"] ?? {}),
        variations = List.from(data["variations"]?.cast<String>() ?? []),
        isRental = data["isRental"] ?? true,
        publishedYear = data["publishedYear"] ?? 0,
        metaOwner = data["metaOwner"] ?? '',
        place =  Place.fromJSON(data["place"] ?? {}),
        boughtUsers = List.from(data["boughtUsers"]?.cast<String>() ?? []),
        createdTime = data["createdTime"] ?? 0,
        modifiedTime = data["modifiedTime"] ?? 0,
        state = data["state"] ?? 0,
        externalArtists = List.from(data["externalArtists"]?.cast<String>() ?? []),
        featInternalArtists = data["featInternalArtists"] as Map<String,String>?,
        likedProfiles = List.from(data["likedProfiles"]?.cast<String>() ?? []),
        externalUrl = data["externalUrl"]?.toString(),
        webPreviewUrl = data["webPreviewUrl"]?.toString(),
        iaInfo = data["iaInfo"] != null ? IaInfo.fromJSON(data["iaInfo"] as Map<String, dynamic>) : null,
        slug = data["slug"] ?? '',
        isSuspended = data["isSuspended"] ?? false,
        suspendedBy = data["suspendedBy"],
        suspendedReason = data["suspendedReason"],
        totalPageViews = data["totalPageViews"] ?? 0,
        streamingUrl = data["streamingUrl"],
        trackNumber = data["trackNumber"],
        quality = data["quality"],
        localPath = data["localPath"],
        ownerProfileId = data["ownerProfileId"];
  
  /// Returns true if this release item contains audio content (audiobook, song, podcast, etc.)
  /// Used to route to audio player instead of book details
  bool get isAudioContent {
    // Check by mediaType first
    if (mediaType != null) {
      return mediaType == MediaItemType.audiobook ||
             mediaType == MediaItemType.song ||
             mediaType == MediaItemType.podcast ||
             mediaType == MediaItemType.binaural ||
             mediaType == MediaItemType.frequency ||
             mediaType == MediaItemType.nature ||
             mediaType == MediaItemType.neomPreset;
    }

    // Fallback: check file extension in previewUrl (strip query params for Firebase URLs)
    final url = previewUrl.toLowerCase();
    final path = Uri.tryParse(url)?.path ?? url;
    return path.endsWith('.mp3') ||
           path.endsWith('.wav') ||
           path.endsWith('.m4a') ||
           path.endsWith('.aac') ||
           path.endsWith('.ogg') ||
           path.endsWith('.flac');
  }

  /// Returns true if this release item is a readable book (PDF, EPUB, etc.)
  bool get isBookContent {
    // Check by mediaType first
    if (mediaType != null) {
      return mediaType == MediaItemType.book ||
             mediaType == MediaItemType.pdf;
    }

    // Fallback: check file extension in previewUrl (strip query params for Firebase URLs)
    final url = previewUrl.toLowerCase();
    final path = Uri.tryParse(url)?.path ?? url;
    return path.endsWith('.pdf') ||
           path.endsWith('.epub') ||
           path.endsWith('.mobi');
  }

  /// Generates a URL-friendly slug from a title.
  /// "Quemando mis razones" → "quemando-mis-razones"
  static String generateSlug(String title) {
    return title
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'[^a-z0-9\-áéíóúñü]'), '');
  }

  Map<String, dynamic>  toJSON() => {
    'id': id,
    'name': name,
    'description': description,
    'imgUrl': imgUrl,
    'galleryUrls': galleryUrls,
    'previewUrl': previewUrl,
    'duration': duration,
    'type': type.name,
    'status': status.name,
    'mediaType': mediaType?.name,
    'ownerEmail': ownerEmail,
    'ownerName': ownerName,
    'ownerType': ownerType.name,
    'categories': categories,
    'tags': tags,
    'metaId': metaId,
    'metaName': metaName,
    'metaOwnerId': metaOwnerId,
    'instruments': instruments,
    'lyrics': lyrics,
    'language': language,
    'digitalPrice': digitalPrice?.toJSON(),
    'physicalPrice': physicalPrice?.toJSON(),
    'salePrice': salePrice?.toJSON(),
    'isRental': isRental,
    'publishedYear': publishedYear,
    'metaOwner': metaOwner,
    'place': place?.toJSON(),
    'boughtUsers': boughtUsers,
    'createdTime': createdTime,
    'modifiedTime': modifiedTime,
    'state': state,
    'externalArtists': externalArtists,
    'featInternalArtists': featInternalArtists,
    'likedProfiles': likedProfiles,
    'externalUrl': externalUrl,
    'webPreviewUrl': webPreviewUrl,
    'iaInfo': iaInfo?.toJSON(),
    'slug': slug,
    'isSuspended': isSuspended,
    'suspendedBy': suspendedBy,
    'suspendedReason': suspendedReason,
  };

}
