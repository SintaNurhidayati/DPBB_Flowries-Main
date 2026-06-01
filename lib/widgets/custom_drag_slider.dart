import 'package:flutter/material.dart';

/// Custom Widget dengan Custom Drawing Canvas dan Gesture
class CustomDragSlider extends StatefulWidget {
  final double minValue;
  final double maxValue;
  final double initialValue;
  final Function(double) onValueChanged;
  final String label;
  final String unit;
  
  const CustomDragSlider({
    super.key,
    this.minValue = 0,
    this.maxValue = 100,
    this.initialValue = 50,
    required this.onValueChanged,
    required this.label,
    this.unit = '',
  });

  @override
  State<CustomDragSlider> createState() => _CustomDragSliderState();
}

class _CustomDragSliderState extends State<CustomDragSlider> {
  late double _value;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  void _updateValue(double newValue) {
    setState(() {
      _value = newValue.clamp(widget.minValue, widget.maxValue);
    });
    widget.onValueChanged(_value);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_value.toStringAsFixed(0)}${widget.unit}',
                style: const TextStyle(
                  color: Color(0xFF2E7D32),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onHorizontalDragUpdate: (details) {
            final RenderBox box = context.findRenderObject() as RenderBox;
            final position = box.globalToLocal(details.globalPosition);
            final width = box.size.width;
            double newValue = widget.minValue + (position.dx / width) * (widget.maxValue - widget.minValue);
            _updateValue(newValue);
            setState(() => _isDragging = true);
          },
          onHorizontalDragEnd: (details) {
            setState(() => _isDragging = false);
          },
          child: CustomPaint(
            size: const Size(double.infinity, 40),
            painter: _SliderPainter(
              value: (_value - widget.minValue) / (widget.maxValue - widget.minValue),
              isDragging: _isDragging,
              primaryColor: const Color(0xFF2E7D32),
            ),
          ),
        ),
      ],
    );
  }
}

class _SliderPainter extends CustomPainter {
  final double value;
  final bool isDragging;
  final Color primaryColor;
  
  _SliderPainter({
    required this.value,
    required this.isDragging,
    required this.primaryColor,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final trackPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.fill;
    
    final activePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;
    
    final thumbPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    final thumbStroke = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    // Shadow paint - dipisah karena cascade operator tidak bisa digabung
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    
    final radius = 8.0;
    final thumbRadius = isDragging ? 16.0 : 12.0;
    final thumbX = size.width * value;
    
    // Track background
    final trackRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, size.height / 2 - radius, size.width, radius * 2),
      Radius.circular(radius),
    );
    canvas.drawRRect(trackRect, trackPaint);
    
    // Active track
    final activeRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, size.height / 2 - radius, thumbX, radius * 2),
      Radius.circular(radius),
    );
    canvas.drawRRect(activeRect, activePaint);
    
    // Thumb shadow
    canvas.drawCircle(
      Offset(thumbX, size.height / 2),
      thumbRadius + 2,
      shadowPaint,
    );
    
    // Thumb
    canvas.drawCircle(
      Offset(thumbX, size.height / 2),
      thumbRadius,
      thumbPaint,
    );
    canvas.drawCircle(
      Offset(thumbX, size.height / 2),
      thumbRadius,
      thumbStroke,
    );
    
    // Inner dot when dragging
    if (isDragging) {
      final innerPaint = Paint()..color = primaryColor;
      canvas.drawCircle(
        Offset(thumbX, size.height / 2),
        4,
        innerPaint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant _SliderPainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.isDragging != isDragging;
  }
}