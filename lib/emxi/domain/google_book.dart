
import '../../core/domain/model/app_item.dart';
import '../../core/domain/model/genre.dart';
import '../../core/utils/app_utilities.dart';
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

  static AppItem toAppItem(GoogleBook googleBook) {

    AppItem appItem = AppItem();
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

      appItem =  AppItem(
          id: googleBook.id ?? "",
          name: googleBook.volumeInfo?.title ?? "",
          albumName: googleBook.volumeInfo?.publisher ?? "",
          artist: authors,
          artistImgUrl: googleBook.volumeInfo?.imageLinks?.smallThumbnail ?? "",
          durationMs: googleBook.volumeInfo?.pageCount ?? 0,
          albumImgUrl: googleBook.volumeInfo?.imageLinks?.thumbnail ?? "",
          infoUrl: googleBook.volumeInfo?.infoLink ?? "",
          previewUrl: googleBook.volumeInfo?.previewLink ?? "",
          state: 0,
          genres: genres,
          description: googleBook.volumeInfo?.description ?? "",
          publishedDate: googleBook.volumeInfo?.publishedDate ?? ""
      );
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return appItem;
  }

}
