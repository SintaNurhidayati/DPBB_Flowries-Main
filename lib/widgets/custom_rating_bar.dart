import 'package:flutter/material.dart';

class CustomRatingBar extends StatefulWidget {
  final int maxRating;
  final Function(int) onRatingChanged;
  final int initialRating;
  final double iconSize;

  const CustomRatingBar({
    Key? key,
    this.maxRating = 5,
    required this.onRatingChanged,
    this.initialRating = 0,
    this.iconSize = 40.0,
  }) : super(key: key);

  @override
  _CustomRatingBarState createState() => _CustomRatingBarState();
}

class _CustomRatingBarState extends State<CustomRatingBar> {
  late int _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
  }

  void _handleDrag(DragUpdateDetails details) {
    RenderBox box = context.findRenderObject() as RenderBox;
    Offset localPosition = box.globalToLocal(details.globalPosition);
    double singleIconWidth = widget.iconSize;
    int rating = (localPosition.dx / singleIconWidth).ceil();
    if (rating < 1) rating = 1;
    if (rating > widget.maxRating) rating = widget.maxRating;

    if (rating != _currentRating) {
      setState(() {
        _currentRating = rating;
      });
      widget.onRatingChanged(_currentRating);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: _handleDrag,
      onTapDown: (details) {
        RenderBox box = context.findRenderObject() as RenderBox;
        Offset localPosition = box.globalToLocal(details.globalPosition);
        double singleIconWidth = widget.iconSize;
        int rating = (localPosition.dx / singleIconWidth).ceil();
        if (rating < 1) rating = 1;
        if (rating > widget.maxRating) rating = widget.maxRating;

        setState(() {
          _currentRating = rating;
        });
        widget.onRatingChanged(_currentRating);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(widget.maxRating, (index) {
          return Icon(
            index < _currentRating ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: widget.iconSize,
          );
        }),
      ),
    );
  }
}
