import 'package:flutter/material.dart';

/// Custom Widget dengan Gesture Swipe to Delete
class SwipeToDeleteWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback onDelete;
  final String? confirmationText;
  
  const SwipeToDeleteWidget({
    super.key,
    required this.child,
    required this.onDelete,
    this.confirmationText,
  });

  @override
  State<SwipeToDeleteWidget> createState() => _SwipeToDeleteWidgetState();
}

class _SwipeToDeleteWidgetState extends State<SwipeToDeleteWidget> {
  double _dragOffset = 0;
  bool _isDeleting = false;
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        if (_isDeleting) return;
        setState(() {
          _dragOffset += details.delta.dx;
          if (_dragOffset < 0) _dragOffset = 0;
          if (_dragOffset > 100) _dragOffset = 100;
        });
      },
      onHorizontalDragEnd: (details) {
        if (_dragOffset > 80) {
          _showDeleteConfirmation();
        } else {
          setState(() => _dragOffset = 0);
        }
      },
      child: Stack(
        children: [
          // Background delete indicator
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red.shade400,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Icon(Icons.delete, color: Colors.white),
                ),
              ),
            ),
          ),
          // Animated child
          Transform.translate(
            offset: Offset(-_dragOffset, 0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
  
  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Item'),
        content: Text(widget.confirmationText ?? 'Apakah Anda yakin ingin menghapus item ini?'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _dragOffset = 0);
              Navigator.pop(context);
            },
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              setState(() => _isDeleting = true);
              Navigator.pop(context);
              widget.onDelete();
              setState(() => _isDeleting = false);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}