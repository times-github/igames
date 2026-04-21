import 'package:flutter/widgets.dart';

class GameFrame extends StatelessWidget {
  const GameFrame({
    super.key,
    required this.url,
    this.onLoaded,
    this.onError,
  });

  final String url;
  final VoidCallback? onLoaded;
  final ValueChanged<String>? onError;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
