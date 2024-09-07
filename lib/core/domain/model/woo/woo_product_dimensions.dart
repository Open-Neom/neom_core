class WooProductDimensions {
  final double length;
  final double width;
  final double height;

  WooProductDimensions({
    this.length = 0,
    this.width = 0,
    this.height = 0,
  });

  factory WooProductDimensions.fromJSON(Map<String, dynamic> json) {
    return WooProductDimensions(
      length: double.tryParse(json['length'] ?? '') ?? 0.0,
      width: double.tryParse(json['width'] ?? '') ?? 0.0,
      height: double.tryParse(json['height'] ?? '') ?? 0.0,
    );
  }

  Map<String, dynamic> toJSON() {
    return {
      'length': length,
      'width': width,
      'height': height,
    };
  }
}
