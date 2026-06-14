import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

class AdminSalesChart extends StatelessWidget {
  final List<double> salesData;

  const AdminSalesChart({super.key, required this.salesData});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 24.0, bottom: 12.0, left: 16.0, right: 16.0),
        child: salesData.isEmpty
            ? const Center(
                child: Text(
                  'Belum ada data transaksi',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              )
            : CustomPaint(
                size: Size.infinite,
                painter: AdminSalesChartPainter(
                  salesData: salesData,
                  barColor: Colors.pink[300]!,
                ),
              ),
      ),
    );
  }
}

class AdminSalesChartPainter extends CustomPainter {
  final List<double> salesData;
  final Color barColor;

  AdminSalesChartPainter({required this.salesData, required this.barColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (salesData.isEmpty) return;

    final paint = Paint()
      ..color = barColor
      ..style = PaintingStyle.fill;

    //Menggunakan compact currency format Indonesia (contoh: Rp150 rb)
    final currencyFormat = NumberFormat.compactSimpleCurrency(locale: 'id_ID');

    final maxVal = salesData.reduce((curr, next) => curr > next ? curr : next);
    final numBars = salesData.length;

    final chartHeight = size.height - 25;
    
    const gap = 16.0;
    final totalGap = gap * (numBars - 1);
    final barWidth = (size.width - totalGap) / numBars;

    for (int i = 0; i < numBars; i++) {
      final barHeight = maxVal == 0 
          ? 0.0 
          : (salesData[i] == 0.0 ? 2.0 : (salesData[i] / maxVal) * (chartHeight - 20));
      
      final x = i * (barWidth + gap);
      final y = chartHeight - barHeight;

      //Gambar Balok Grafik
      final rect = Rect.fromLTWH(x, y, barWidth, barHeight);
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));
      canvas.drawRRect(rrect, paint);

      //Gambar Teks Nominal di Atas Balok
      final textValue = currencyFormat.format(salesData[i]);
      final valuePainter = TextPainter(
        text: TextSpan(
          text: textValue,
          style: TextStyle(
            color: Colors.grey[800],
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      valuePainter.layout(minWidth: 0, maxWidth: barWidth);
      
      final xOffsetValue = x + (barWidth - valuePainter.width) / 2;
      valuePainter.paint(canvas, Offset(xOffsetValue, y - 16));

      //Gambar Label Sumbu X di Bawah Balok
      final labelPainter = TextPainter(
        text: TextSpan(
          text: 'Minggu ${i + 1}',
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      labelPainter.layout(minWidth: 0, maxWidth: barWidth);
      
      final xOffsetLabel = x + (barWidth - labelPainter.width) / 2;
      labelPainter.paint(canvas, Offset(xOffsetLabel, chartHeight + 6));
    }
  }

  @override
  bool shouldRepaint(covariant AdminSalesChartPainter oldDelegate) {
    return oldDelegate.salesData != salesData;
  }
}