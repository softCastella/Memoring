import 'package:flutter/material.dart';

class ImageTitleBanner extends StatelessWidget {
  const ImageTitleBanner({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final text = title.trim();
    if (text.isEmpty) {
      return const SizedBox.shrink();
    }
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        color: const Color(0x99000000),
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 7),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
