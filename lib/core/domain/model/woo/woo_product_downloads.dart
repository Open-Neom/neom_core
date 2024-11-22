class WooProductDownload {

  String? id;
  String? name;
  String? file;

  WooProductDownload({
    this.id,
    this.name,
    this.file,
  });

  // Factory constructor for creating a new WooProductDownloads instance from a JSON map
  factory WooProductDownload.fromJson(Map<String, dynamic> json) {
    return WooProductDownload(
      id: json['id'] as String?,
      name: json['name'] as String?,
      file: json['file'] as String?,
    );
  }

  // Method to convert WooProductDownloads instance to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'file': file,
    };
  }

}
