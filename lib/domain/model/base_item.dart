class BaseItem {

  String id;
  String name;
  String? description;
  String imgUrl;
  List<String>? galleryUrls;

  String ownerId;
  String ownerName;

  String url;
  int duration;
  int state;
  String permaUrl; // O externalUrl/webPreviewUrl, elige el más genérico

  int publishedYear = 0;
  String? metaOwner;
  List<String> categories;

  BaseItem({
    this.id = '',
    this.name = '',
    this.description,
    this.imgUrl = '',
    this.galleryUrls,
    this.url = '',
    this.duration = 0,
    this.state = 0,
    this.permaUrl = '',
    this.ownerId = '',
    this.ownerName = '',
    this.publishedYear = 0,
    this.metaOwner,
    this.categories = const [],
  });

}
