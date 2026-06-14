class CartItem {
  final String id;
  final String productId;
  final String productNama;
  final double productHarga;
  final String productGambar;
  final int quantity;

  CartItem({
    required this.id,
    required this.productId,
    required this.productNama,
    required this.productHarga,
    required this.productGambar,
    required this.quantity,
  });

  double get subtotal => productHarga * quantity;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'productNama': productNama,
      'productHarga': productHarga,
      'productGambar': productGambar,
      'quantity': quantity,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      productId: json['productId'],
      productNama: json['productNama'],
      productHarga: json['productHarga'].toDouble(),
      productGambar: json['productGambar'],
      quantity: json['quantity'],
    );
  }
}
