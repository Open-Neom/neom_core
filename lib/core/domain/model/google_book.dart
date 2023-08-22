
import '../../utils/app_utilities.dart';
import 'app_item.dart';
import 'app_media_item.dart';
import 'genre.dart';
import 'google_book/access_info.dart';
import 'google_book/sale_info.dart';
import 'google_book/search_info.dart';
import 'google_book/volume_info.dart';

class GoogleBook {

  String? kind;
  String? id;
  String? etag;
  String? selfLink;
  VolumeInfo? volumeInfo;
  SaleInfo? saleInfo;
  AccessInfo? accessInfo;
  SearchInfo? searchInfo;

  GoogleBook({
    String? kind,
    String? id,
    String? etag,
    String? selfLink,
    VolumeInfo? volumeInfo,
    SaleInfo? saleInfo,
    AccessInfo? accessInfo,
    SearchInfo? searchInfo,
  });

  GoogleBook.fromJson(dynamic json) {
    kind = json['kind'];
    id = json['id'];
    etag = json['etag'];
    selfLink = json['selfLink'];
    volumeInfo = json['volumeInfo'] != null
        ? VolumeInfo.fromJson(json['volumeInfo'])
        : null;
    saleInfo =
        json['saleInfo'] != null ? SaleInfo.fromJson(json['saleInfo']) : null;
    accessInfo = json['accessInfo'] != null
        ? AccessInfo.fromJson(json['accessInfo'])
        : null;
    searchInfo = json['searchInfo'] != null
        ? SearchInfo.fromJson(json['searchInfo'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['kind'] = kind;
    map['id'] = id;
    map['etag'] = etag;
    map['selfLink'] = selfLink;
    if (volumeInfo != null) {
      map['volumeInfo'] = volumeInfo?.toJson();
    }
    if (saleInfo != null) {
      map['saleInfo'] = saleInfo?.toJson();
    }
    if (accessInfo != null) {
      map['accessInfo'] = accessInfo?.toJson();
    }
    if (searchInfo != null) {
      map['searchInfo'] = searchInfo?.toJson();
    }
    return map;
  }

  static AppMediaItem toAppMediaItem(GoogleBook googleBook) {

    AppMediaItem appItem = AppMediaItem();
    List<Genre> genres = [];

    try {
      String authors = "";
      if(googleBook.volumeInfo?.authors?.isNotEmpty ?? false) {
        googleBook.volumeInfo?.authors?.forEach((element) {
          if(authors.isNotEmpty) {
            authors = "$authors, ";
          }

          if(authors.isEmpty) {
            authors = element;
          } else {
            authors = "$authors$element";
          }
        });

      }

      if(googleBook.volumeInfo?.categories?.isNotEmpty ?? false) {
        googleBook.volumeInfo?.categories?.forEach((element) {
          genres.add(Genre(id: element, name: element));
        });
      }

      appItem =  AppMediaItem(
          id: googleBook.id ?? "",
          name: googleBook.volumeInfo?.title ?? "",
          album: googleBook.volumeInfo?.publisher ?? "",
          artist: authors,
          allImgs: [googleBook.volumeInfo?.imageLinks?.smallThumbnail ?? ""],
          duration: googleBook.volumeInfo?.pageCount ?? 0, ///NUMBER OF PAGES
          imgUrl: googleBook.volumeInfo?.imageLinks?.thumbnail ?? "",
          permaUrl: googleBook.volumeInfo?.infoLink ?? "",
          url: googleBook.volumeInfo?.previewLink ?? "",
          state: 0,
          genres: genres.map((e) => e.name).toList(),
          description: googleBook.volumeInfo?.description ?? "",
          publishedDate: 0, ///VERIFY HOW TO HANDLE THIS DATE TO SINCEEPOCH googleBook.volumeInfo?.publishedDate ?? ""
      );
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return appItem;
  }

}
