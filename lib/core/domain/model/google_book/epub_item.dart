
class Epub {
  Epub({
    bool? isAvailable,
  }) {
    _isAvailable = isAvailable;
  }

  Epub.fromJson(dynamic json) {
    _isAvailable = json['isAvailable'];
  }
  bool? _isAvailable;
  Epub copyWith({
    bool? isAvailable,
  }) =>
      Epub(
        isAvailable: isAvailable ?? _isAvailable,
      );
  bool? get isAvailable => _isAvailable;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['isAvailable'] = _isAvailable;
    return map;
  }
}
