
class SearchInfo {

  SearchInfo({
    String? textSnippet,
  }) {
    _textSnippet = textSnippet;
  }

  SearchInfo.fromJson(dynamic json) {
    _textSnippet = json['textSnippet'];
  }
  String? _textSnippet;
  SearchInfo copyWith({
    String? textSnippet,
  }) =>
      SearchInfo(
        textSnippet: textSnippet ?? _textSnippet,
      );
  String? get textSnippet => _textSnippet;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['textSnippet'] = _textSnippet;
    return map;
  }
}
