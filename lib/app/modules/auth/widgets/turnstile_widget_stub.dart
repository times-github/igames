import 'package:flutter/material.dart';

class TurnstileWidget extends StatelessWidget {
  const TurnstileWidget({
    super.key,
    required this.siteKey,
    required this.onToken,
    this.theme = 'dark',
  });

  final String siteKey;
  final ValueChanged<String> onToken;
  final String theme;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
