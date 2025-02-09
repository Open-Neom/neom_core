import 'package:enum_to_string/enum_to_string.dart';

import '../../../neom_commons.dart';
import '../../utils/enums/app_currency.dart';
import '../../utils/enums/owner_type.dart';
import '../../utils/enums/release_status.dart';
import '../../utils/enums/release_type.dart';
import 'place.dart';
import 'price.dart';
import 'woo/woo_product.dart';

class AppReleaseItem {

  String id; ///ID FOR ITEM ON DB OR WC
  String name; ///NAME OF ITEM
  String description; ///DESCRIPTION OF ITEM
  String imgUrl; ///COVER IMAGE
  List<String>? galleryUrls; ///FIRST IMAGE ON GALLERY MUST BE OwnerImgUrl
  String previewUrl; ///URL WITH FILE
  int duration; ///SECONDS - NUMBER OF PAGES - ETC

  ReleaseType type; ///RELEASE TYPE TO HANDLE FURTHER FEATURES
  ReleaseStatus status;

  String ownerEmail; ///EMAIL OF PROFILE ON APP
  String ownerName; ///NAME OF PROFILE ON APP
  OwnerType ownerType; ///TO KNOW IF RELEASE WAS UPLOADED FROM USER OR BAND TO FLOW

  List<String> categories; ///CATEGORIES OR GENRES FOR BOOKS | SONGS | PODCASTS | CATEGORIES RETRIEVED FROM WC
  List<String>? tags; ///CATEGORIES OR GENRES FOR BOOKS | SONGS | PODCASTS | CATEGORIES RETRIEVED FROM WC

  String? metaId; ///ID OF ITEMLIST CREATED TO INCLUDE ITEMS IN CASE OF INCLUDING MORE ON SAME
  String? metaName; ///ITEMLIST NAME
  String? metaOwnerId; ///EMAIL USED TO UPLOAD ITEM FROM APP OR WC

  List<String>? instruments; ///INSTRUMENTS USED ON RELEASE - IT DEPENDS OF THE APP

  String? lyrics; ///LYRICS FOR SONGS
  String? language; ///SPANISH - ENGLISH - ETC

  Price? digitalPrice; ///PRICE FOR DIGITAL ITEM  - IF NOT NULL ITEM IS AVAILABLE AS DIGITAL
  Price? physicalPrice; ///PRICE IN CASE ITEM HAS A PHYSICAL VERSION AS WELL - IF NOT NULL ITEM IS AVAILABLE AS PHYSICAL
  Price? salePrice; ///SALE PRICE FOR ITEM AFTER ANY DISCOUNT
  List<String>? variations; ///VARIATION IDS FOR CASES WHEN ITEM HAS DIFFERENT SUBITEMS
  bool isRental; ///Verify if item is elegible for unlimited access for members

  int? publishedYear; ///YEAR OF PUBLISHIN FOR ITEMS PUBLISHED PREVIOUSLY OUTSIDE THE PLATFORM.
  String? publisher; ///IN CASE OF A FORMAL PUBLISHER BESIDES AUTOPUBLISHING
  Place? place; ///PLACE OR LOCATION FOR PUBLISHER IF ABLE.

  List<String>? boughtUsers; ///PROFILEID OR EMAIL OF USERS WHO BOUGHT THIS ITEM - IT ALSO IS USEFUL TO KNOW TOTAL SALES WITH LIST.LENGHT

  ///DEPRECATED
  /// List<String>? followingProfiles;
  /// List<BandFulfillment> bandsFulfillment;

  int createdTime; ///CREATED TIME ON PLATFORM
  int? modifiedTime; ///TIME OF LAST MODIFICATION

  int state; ///STATE FOR USERS WHEN THE SAVE ITEM ON ITEMLISTS - FROM O to 5

  List<String>? externalArtists; ///Out of the app
  Map<String, String>? featInternalArtists; ///key: artistId - value: name
  List<String>? likedProfiles; ///LIST OF PROFILEIDS IN CASE OF MORE DETAILS. ALSO TO KNOW NUMBER OF LIKES WITH LIST.LENGHT

  String? externalUrl; ///URL FOR ITEM IN WEB
  String? webPreviewUrl; ///URL FOR Preview IN WEB

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
    this.publisher,
    this.place,
    this.boughtUsers,
    this.createdTime = 0,
    this.modifiedTime,
    this.state = 0,
    this.externalArtists,
    this.featInternalArtists,
    this.likedProfiles,
    this.externalUrl,
    this.webPreviewUrl
  });

  @override
  String toString() {
    return 'AppReleaseItem{id: $id, name: $name, description: $description, imgUrl: $imgUrl, galleryUrls: $galleryUrls, previewUrl: $previewUrl, duration: $duration, type: $type, status: $status, ownerEmail: $ownerEmail, ownerName: $ownerName, ownerType: $ownerType, categories: $categories, metaId: $metaId, metaName: $metaName, metaOwnerId: $metaOwnerId, instruments: $instruments, lyrics: $lyrics, language: $language, digitalPrice: $digitalPrice, physicalPrice: $physicalPrice, variations: $variations, publishedYear: $publishedYear, publisher: $publisher, place: $place, boughtUsers: $boughtUsers, createdTime: $createdTime, modifiedTime: $modifiedTime, state: $state, externalArtists: $externalArtists, featInternalArtists: $featInternalArtists, likedProfiles: $likedProfiles, externalUrl: $externalUrl}';
  }

  AppReleaseItem.fromJSON(data) :
        id = data["id"] ?? '',
        name = data["name"] ?? '',
        description = data["description"] ?? '',
        imgUrl = data["imgUrl"] ?? '',
        galleryUrls = List.from(data["galleryUrls"]?.cast<String>() ?? []),
        previewUrl = data["previewUrl"] ?? '',
        duration = data["duration"] ?? 0,
        type = EnumToString.fromString(ReleaseType.values, data["type"] ?? ReleaseType.single.name) ?? ReleaseType.single,
        status = EnumToString.fromString(ReleaseStatus.values, data["status"] ?? ReleaseStatus.draft.name) ?? ReleaseStatus.draft,
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
        publisher = data["publisher"] ?? '',
        place =  Place.fromJSON(data["place"] ?? {}),
        boughtUsers = List.from(data["boughtUsers"]?.cast<String>() ?? []),
        createdTime = data["createdTime"] ?? 0,
        modifiedTime = data["modifiedTime"] ?? 0,
        state = data["state"] ?? 0,
        externalArtists = List.from(data["externalArtists"]?.cast<String>() ?? []),
        featInternalArtists = data["featInternalArtists"] as Map<String,String>?,
        likedProfiles = List.from(data["likedProfiles"]?.cast<String>() ?? []),
        externalUrl = data["externalUrl"].toString(),
        webPreviewUrl = data["webPreviewUrl"].toString();
  
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
    'publisher': publisher,
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
  };

  AppReleaseItem.fromWooProduct(WooProduct product) :
        id = product.id.toString(),
        name = product.name,
        description = product.description.isNotEmpty ? product.description : product.shortDescription.isNotEmpty ? product.shortDescription : '',
        imgUrl = product.images.isNotEmpty ? product.images.first.src : '',
        galleryUrls = product.images.map<String>((img)=> img.src).toList(),
        previewUrl = (product.attributes?.containsKey('previewUrl') ?? false) ? product.attributes!['previewUrl']!.options.first : '',
        duration = (product.attributes?.containsKey('duration') ?? false) ? int.tryParse(product.attributes!['duration']!.options.first) ?? 0 : 0,
        type = (product.attributes?.containsKey('type') ?? false) ? EnumToString.fromString(ReleaseType.values, product.attributes!['type']!.options.first) ?? ReleaseType.single : ReleaseType.single,
        status = EnumToString.fromString(ReleaseStatus.values, product.status.name) ?? ReleaseStatus.draft,
        ownerEmail = (product.attributes?.containsKey('ownerEmail') ?? false) ? product.attributes!['ownerEmail']!.options.first : '',
        ownerName = (product.attributes?.containsKey('ownerName') ?? false) ? product.attributes!['ownerName']!.options.first : AppUtilities.getArtistName(product.name),
        ownerType = OwnerType.woo,
        categories = List.from(product.categories.map((c) => c.name).toList()),
        tags = List.from(product.tags.map((t) => t.name).toList()),
        // metaName = null,
        // metaId = null,
        // metaOwnerId = null,
        // appMediaItemIds = null,
        // instruments = null,
        lyrics = product.shortDescription,
        language = (product.attributes?.containsKey('language') ?? false) ? product.attributes!['language']!.options.first : '',
        digitalPrice = product.virtual ? Price(amount: product.regularPrice, currency: AppCurrency.mxn) : null,
        physicalPrice = !product.virtual ? Price(amount: product.regularPrice, currency: AppCurrency.mxn) : null,
        salePrice = Price(amount: product.salePrice, currency: AppCurrency.mxn),
        variations = product.variations,
        isRental = (product.attributes?.containsKey('isRental') ?? true) ? bool.parse(product.attributes!['isRental']!.options.first) : true,
        publishedYear = (product.attributes?.containsKey('publishedYear') ?? false) ? int.tryParse(product.attributes!['publishedYear']!.options.first) : null,
        publisher = (product.attributes?.containsKey('publisher') ?? false) ? product.attributes!['publisher']!.options.first : null,
        // place =  null,
        // boughtUsers = null,
        createdTime = product.dateCreated?.millisecondsSinceEpoch ?? 0,
        modifiedTime = product.dateModified?.millisecondsSinceEpoch,
        state = 0,
        // externalArtists = null,
        // featInternalArtists = null,
        // likedProfiles = null
        externalUrl = product.permalink,
        webPreviewUrl = (product.attributes?.containsKey('webPreviewUrl') ?? false) ? product.attributes!['webPreviewUrl']!.options.first : null;

}
