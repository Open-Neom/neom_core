
class SaleInfo {
  SaleInfo({
    String? country,
    String? saleability,
    bool? isEbook,
  }) {
    _country = country;
    _saleability = saleability;
    _isEbook = isEbook;
  }

  SaleInfo.fromJson(dynamic json) {
    _country = json['country'];
    _saleability = json['saleability'];
    _isEbook = json['isEbook'];
  }
  String? _country;
  String? _saleability;
  bool? _isEbook;
  SaleInfo copyWith({
    String? country,
    String? saleability,
    bool? isEbook,
  }) =>
      SaleInfo(
        country: country ?? _country,
        saleability: saleability ?? _saleability,
        isEbook: isEbook ?? _isEbook,
      );
  String? get country => _country;
  String? get saleability => _saleability;
  bool? get isEbook => _isEbook;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['country'] = _country;
    map['saleability'] = _saleability;
    map['isEbook'] = _isEbook;
    return map;
  }
}
