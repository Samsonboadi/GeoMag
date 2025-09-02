import 'package:flutter/material.dart';


class ChipButton extends StatelessWidget {
final IconData icon; final String label; final VoidCallback onTap;
const ChipButton({super.key, required this.icon, required this.label, required this.onTap});
@override Widget build(BuildContext context){
return Material(
color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(24),
child: InkWell(
onTap:onTap, borderRadius: BorderRadius.circular(24),
child: Padding(
padding: const EdgeInsets.symmetric(horizontal:12, vertical:8),
child: Row(mainAxisSize: MainAxisSize.min, children:[
Icon(icon, color: Colors.white, size: 18), const SizedBox(width:6), Text(label, style: const TextStyle(color: Colors.white)),
]),
),
),
);
}
}