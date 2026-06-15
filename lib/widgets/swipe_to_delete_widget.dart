import 'package:flutter/material.dart';
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

class _SwipeToDeleteWidgetState extends State<SwipeToDeleteWidget> with SingleTickerProviderStateMixin {
  double _dragOffset = 0;
  bool _isDeleting = false;
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _animateReset() {
    _animationController.forward(from: 0).then((_) {
      if (mounted) {
        setState(() {
          _dragOffset = 0;
        });
        _animationController.reset();
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        if (_isDeleting) return;
        setState(() {
          // Swipe dari kanan ke kiri (nilai negatif)
          _dragOffset += details.delta.dx;
          // Batasi hanya untuk swipe ke kiri (max -100)
          if (_dragOffset > 0) _dragOffset = 0;
          if (_dragOffset < -100) _dragOffset = -100;
        });
      },
      onHorizontalDragEnd: (details) {
        if (_isDeleting) return;

        if (_dragOffset < -80) {
          _showDeleteConfirmation();
        } else {
          setState(() {
            _dragOffset = 0;
          });
        }
      },
      child: Stack(
        children: [
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
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            transform: Matrix4.translationValues(_dragOffset, 0, 0),
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
        ],
      ),
    );
  }
  
  Future<void> _showDeleteConfirmation() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Item'),
        content: Text(widget.confirmationText ?? 'Apakah Anda yakin ingin menghapus item ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    
    if (shouldDelete == true) {
      setState(() {
        _isDeleting = true;
      });

      setState(() {
        _dragOffset = 0;
      });

      await Future.delayed(const Duration(milliseconds: 250));

      widget.onDelete();
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    } else {
      setState(() {
        _dragOffset = 0;
      });
    }
  }
}