
class ReadingModes {
  ReadingModes({
    bool? text,
    bool? image,
  }) {
    _text = text;
    _image = image;
  }

  ReadingModes.fromJson(dynamic json) {
    _text = json['text'];
    _image = json['image'];
  }
  bool? _text;
  bool? _image;
  ReadingModes copyWith({
    bool? text,
    bool? image,
  }) =>
      ReadingModes(
        text: text ?? _text,
        image: image ?? _image,
      );
  bool? get text => _text;
  bool? get image => _image;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['text'] = _text;
    map['image'] = _image;
    return map;
  }
}
