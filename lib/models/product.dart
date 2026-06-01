class Product {
  final String id;
  final String name;
  final int price;
  final int stock;
  final String image;
  final String description;
  final List<String> colors;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.image,
    required this.description,
    required this.colors,
  });
}
