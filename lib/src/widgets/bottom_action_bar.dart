/// Bottom Action Bar Widget
/// 
/// Bottom navigation bar with primary actions like try-on, save, and share.
/// Provides quick access to key app functions during product browsing.
import 'package:flutter/material.dart';

class BottomActionBar extends StatelessWidget {
  final VoidCallback? onTryOn;
  final VoidCallback? onSave;
  final VoidCallback? onShare;

  const BottomActionBar({
    super.key,
    this.onTryOn,
    this.onSave,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (onTryOn != null)
            ElevatedButton.icon(
              onPressed: onTryOn,
              icon: const Icon(Icons.view_in_ar),
              label: const Text('Try On'),
            ),
          if (onSave != null)
            IconButton(
              onPressed: onSave,
              icon: const Icon(Icons.favorite_border),
            ),
          if (onShare != null)
            IconButton(
              onPressed: onShare,
              icon: const Icon(Icons.share),
            ),
        ],
      ),
    );
  }
}
