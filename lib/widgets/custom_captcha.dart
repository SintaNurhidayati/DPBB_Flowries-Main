import 'dart:math';
import 'package:flutter/material.dart';

class CustomCaptcha extends StatefulWidget {
  final VoidCallback onSuccess;

  const CustomCaptcha({Key? key, required this.onSuccess}) : super(key: key);

  @override
  _CustomCaptchaState createState() => _CustomCaptchaState();
}

class _CustomCaptchaState extends State<CustomCaptcha> {
  double _sliderPosition = 0.0;
  final double _sliderMax = 200.0;
  final double _targetPosition = 150.0;
  final double _tolerance = 15.0;
  bool _isSuccess = false;
  String _captchaText = "Geser puzzle untuk verifikasi";

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isSuccess) return;
    setState(() {
      _sliderPosition += details.delta.dx;
      if (_sliderPosition < 0) _sliderPosition = 0;
      if (_sliderPosition > _sliderMax) _sliderPosition = _sliderMax;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isSuccess) return;
    if ((_sliderPosition - _targetPosition).abs() <= _tolerance) {
      setState(() {
        _isSuccess = true;
        _captchaText = "Verifikasi Berhasil!";
        _sliderPosition = _targetPosition;
      });
      widget.onSuccess();
    } else {
      setState(() {
        _sliderPosition = 0; // Reset
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(_captchaText, style: TextStyle(color: _isSuccess ? Colors.green : Colors.grey)),
        SizedBox(height: 10),
        Container(
          width: _sliderMax + 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey),
          ),
          child: Stack(
            children: [
              // Target marker
              Positioned(
                left: _targetPosition,
                top: 5,
                child: CustomPaint(
                  size: Size(50, 50),
                  painter: TargetPainter(),
                ),
              ),
              // Draggable object
              Positioned(
                left: _sliderPosition,
                top: 5,
                child: GestureDetector(
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: _onPanEnd,
                  child: CustomPaint(
                    size: Size(50, 50),
                    painter: DraggablePainter(isSuccess: _isSuccess),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class TargetPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.grey.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    
    Path path = Path();
    path.addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), Radius.circular(8)));
    
    // Add a puzzle piece cutout shape
    path.addOval(Rect.fromCircle(center: Offset(size.width, size.height / 2), radius: 10));
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class DraggablePainter extends CustomPainter {
  final bool isSuccess;

  DraggablePainter({required this.isSuccess});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = isSuccess ? Colors.green : Colors.blue
      ..style = PaintingStyle.fill;
      
    Path path = Path();
    path.addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), Radius.circular(8)));
    path.addOval(Rect.fromCircle(center: Offset(size.width, size.height / 2), radius: 10));
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // May change based on success state
  }
}
