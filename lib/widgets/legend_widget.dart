import 'package:flutter/material.dart';


class LegendWidget extends StatelessWidget {
final double minV; final double maxV; final String title;
const LegendWidget({super.key, required this.minV, required this.maxV, required this.title});
@override Widget build(BuildContext context){
return Container(
padding: const EdgeInsets.all(8),
decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(8)),
child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
const SizedBox(height:6),
SizedBox(
width: 160, height: 10,
child: CustomPaint(painter: _GradientBar()),
),
const SizedBox(height:6),
Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[
Text(minV.toStringAsFixed(0), style: const TextStyle(color: Colors.white, fontSize: 12)),
Text(maxV.toStringAsFixed(0), style: const TextStyle(color: Colors.white, fontSize: 12)),
])
]),
);
}
}


class _GradientBar extends CustomPainter {
@override void paint(Canvas c, Size s){
final rect = Offset.zero & s;
final g = const LinearGradient(colors:[Color(0xFF3B82F6), Color(0xFFFF0000)]); // blue->red
final p = Paint()..shader = g.createShader(rect);
c.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), p);
}
@override bool shouldRepaint(CustomPainter oldDelegate)=>false;
}