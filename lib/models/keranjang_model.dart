// models/keranjang_model.dart
class KeranjangItem {
  String id;
  String productId;
  String name;
  String image;
  int price;
  int quantity;
  bool isSelected;

  KeranjangItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.image,
    required this.price,
    required this.quantity,
    this.isSelected = true,
  });

  int get total => price * quantity;
}