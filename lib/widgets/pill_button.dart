import 'package:flutter/material.dart';


class PillButton extends StatelessWidget {
final IconData icon; final String label; final VoidCallback onTap;
const PillButton({super.key, required this.icon, required this.label, required this.onTap});
@override Widget build(BuildContext context){
return ElevatedButton.icon(
onPressed:onTap, icon: Icon(icon), label: Text(label),
style: ElevatedButton.styleFrom(shape: const StadiumBorder()),
);
}
}