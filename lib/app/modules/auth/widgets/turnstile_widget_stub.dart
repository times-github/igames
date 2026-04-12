import 'package:flutter/material.dart';

const bool supportsTurnstileChallenge = false;

class TurnstileWidget extends StatelessWidget {
  const TurnstileWidget({
    super.key,
    required this.siteKey,
    required this.onToken,
    this.theme = 'dark',
    this.language = 'auto',
  });

  final String siteKey;
  final ValueChanged<String> onToken;
  final String theme;
  final String language;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
