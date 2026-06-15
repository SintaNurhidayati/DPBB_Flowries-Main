import 'package:flutter/material.dart';

class CustomRangeSlider extends StatefulWidget {
  final double min;
  final double max;
  final RangeValues values;
  final ValueChanged<RangeValues> onChanged;
  final Color activeColor;
  final Color inactiveColor;
  
  const CustomRangeSlider({
    super.key,
    required this.min,
    required this.max,
    required this.values,
    required this.onChanged,
    this.activeColor = Colors.green,
    this.inactiveColor = Colors.grey,
  });

  @override
  State<CustomRangeSlider> createState() => _CustomRangeSliderState();
}

class _CustomRangeSliderState extends State<CustomRangeSlider> {
  double _startValue = 0;
  double _endValue = 0;
  bool _isDraggingStart = false;
  bool _isDraggingEnd = false;
  bool _isDraggingRange = false;
  double _dragStartX = 0;
  double _initialStartValue = 0;
  double _initialEndValue = 0;
  
  late double _sliderWidth;
  late double _thumbRadius = 12;
  
  @override
  void initState() {
    super.initState();
    _startValue = widget.values.start;
    _endValue = widget.values.end;
  }
  
  @override
  void didUpdateWidget(CustomRangeSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.values != oldWidget.values) {
      _startValue = widget.values.start;
      _endValue = widget.values.end;
    }
  }
  
  double _getPositionFromValue(double value) {
    final ratio = (value - widget.min) / (widget.max - widget.min);
    return ratio * _sliderWidth;
  }
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _sliderWidth = constraints.maxWidth;
        
        final startX = _getPositionFromValue(_startValue);
        final endX = _getPositionFromValue(_endValue);
        
        return GestureDetector(
          onHorizontalDragStart: (details) {
            final localX = details.localPosition.dx;
            final startDistance = (localX - startX).abs();
            final endDistance = (localX - endX).abs();
            final rangeDistance = (localX - ((startX + endX) / 2)).abs();
            
            if (startDistance < _thumbRadius) {
              _isDraggingStart = true;
              _dragStartX = localX;
              _initialStartValue = _startValue;
            } else if (endDistance < _thumbRadius) {
              _isDraggingEnd = true;
              _dragStartX = localX;
              _initialEndValue = _endValue;
            } else if (rangeDistance < _thumbRadius * 2) {
              _isDraggingRange = true;
              _dragStartX = localX;
              _initialStartValue = _startValue;
              _initialEndValue = _endValue;
            }
          },
          onHorizontalDragUpdate: (details) {
            if (_isDraggingStart) {
              final delta = details.localPosition.dx - _dragStartX;
              double newValue = _initialStartValue + 
                  (delta / _sliderWidth) * (widget.max - widget.min);
              newValue = newValue.clamp(widget.min, _endValue - 1000);
              if (newValue != _startValue) {
                setState(() => _startValue = newValue);
                widget.onChanged(RangeValues(_startValue, _endValue));
              }
            } else if (_isDraggingEnd) {
              final delta = details.localPosition.dx - _dragStartX;
              double newValue = _initialEndValue + 
                  (delta / _sliderWidth) * (widget.max - widget.min);
              newValue = newValue.clamp(_startValue + 1000, widget.max);
              if (newValue != _endValue) {
                setState(() => _endValue = newValue);
                widget.onChanged(RangeValues(_startValue, _endValue));
              }
            } else if (_isDraggingRange) {
              final delta = details.localPosition.dx - _dragStartX;
              double deltaValue = (delta / _sliderWidth) * (widget.max - widget.min);
              double newStart = (_initialStartValue + deltaValue)
                  .clamp(widget.min, widget.max - (_initialEndValue - _initialStartValue));
              double newEnd = newStart + (_initialEndValue - _initialStartValue);
              
              if (newStart != _startValue) {
                setState(() {
                  _startValue = newStart;
                  _endValue = newEnd;
                });
                widget.onChanged(RangeValues(_startValue, _endValue));
              }
            }
          },
          onHorizontalDragEnd: (details) {
            setState(() {
              _isDraggingStart = false;
              _isDraggingEnd = false;
              _isDraggingRange = false;
            });
          },
          child: Stack(
            children: [
              // Track background
              Container(
                height: 4,
                margin: EdgeInsets.symmetric(vertical: _thumbRadius),
                decoration: BoxDecoration(
                  color: widget.inactiveColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Active range
              Positioned(
                left: startX,
                right: _sliderWidth - endX,
                child: Container(
                  height: 4,
                  margin: EdgeInsets.symmetric(vertical: _thumbRadius),
                  decoration: BoxDecoration(
                    color: widget.activeColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              // Start thumb
              Positioned(
                left: startX - _thumbRadius,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  width: _thumbRadius * 2,
                  height: _thumbRadius * 2,
                  decoration: BoxDecoration(
                    color: _isDraggingStart ? widget.activeColor : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(
                      color: widget.activeColor,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: widget.activeColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
              
              // End thumb
              Positioned(
                left: endX - _thumbRadius,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  width: _thumbRadius * 2,
                  height: _thumbRadius * 2,
                  decoration: BoxDecoration(
                    color: _isDraggingEnd ? widget.activeColor : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(
                      color: widget.activeColor,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: widget.activeColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
              
              // Tooltip saat dragging
              if (_isDraggingStart || _isDraggingEnd || _isDraggingRange)
                Positioned(
                  top: -30,
                  left: (_isDraggingStart ? startX : _isDraggingEnd ? endX : (startX + endX) / 2) - 40,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _isDraggingStart 
                          ? 'Rp ${_startValue.toInt()}'
                          : _isDraggingEnd
                              ? 'Rp ${_endValue.toInt()}'
                              : 'Rp ${_startValue.toInt()} - Rp ${_endValue.toInt()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}