import 'package:flutter/material.dart';
class CustomQuantitySelector extends StatefulWidget {
  final int initialQuantity;
  final int minQuantity;
  final int maxQuantity;
  final Function(int) onQuantityChanged;
  final Color primaryColor;
  
  const CustomQuantitySelector({
    super.key,
    this.initialQuantity = 1,
    this.minQuantity = 1,
    this.maxQuantity = 99,
    required this.onQuantityChanged,
    this.primaryColor = const Color(0xFF2E7D32),
  });

  @override
  State<CustomQuantitySelector> createState() => _CustomQuantitySelectorState();
}

class _CustomQuantitySelectorState extends State<CustomQuantitySelector> {
  late int _quantity;

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialQuantity;
  }

  void _increment() {
    if (_quantity < widget.maxQuantity) {
      setState(() => _quantity++);
      widget.onQuantityChanged(_quantity);
    }
  }

  void _decrement() {
    if (_quantity > widget.minQuantity) {
      setState(() => _quantity--);
      widget.onQuantityChanged(_quantity);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Minus Button
          GestureDetector(
            onTap: _decrement,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _quantity <= widget.minQuantity ? Colors.grey.shade100 : widget.primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  bottomLeft: Radius.circular(30),
                ),
              ),
              child: Icon(
                Icons.remove,
                color: _quantity <= widget.minQuantity ? Colors.grey : widget.primaryColor,
                size: 20,
              ),
            ),
          ),
          // Custom Drawing - Animated Counter
          Container(
            width: 50,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                '$_quantity',
                key: ValueKey(_quantity),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          // Plus Button
          GestureDetector(
            onTap: _increment,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _quantity >= widget.maxQuantity ? Colors.grey.shade100 : widget.primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Icon(
                Icons.add,
                color: _quantity >= widget.maxQuantity ? Colors.grey : widget.primaryColor,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}