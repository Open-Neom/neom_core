class WooLineItem {

  String productId;
  int quantity;

  WooLineItem({
    required this.productId,
    required this.quantity,
  });

  // Convert a LineItem object to a JSON map
  Map<String, dynamic> toJSON() {
    return {
      'product_id': productId,
      'quantity': quantity,
    };
  }

  // Create a LineItem object from a JSON map
  factory WooLineItem.fromJSON(Map<String, dynamic> json) {
    return WooLineItem(
      productId: json['product_id'].toString(),
      quantity: json['quantity'],
    );
  }
}
