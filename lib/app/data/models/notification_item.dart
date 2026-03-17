class NotificationItem {
  NotificationItem({
    required this.type,
    required this.id,
    required this.title,
    required this.content,
    required this.lang,
    required this.createdAt,
    this.extra,
  });

  final String type;
  final int id;
  final String title;
  final String content;
  final String lang;
  final DateTime? createdAt;
  final Map<String, dynamic>? extra;

  factory NotificationItem.fromSse(Map<String, dynamic> payload) {
    final extra = payload['extra'];
    final extraMap =
        extra is Map ? Map<String, dynamic>.from(extra) : <String, dynamic>{};
    final title = extraMap['title']?.toString() ?? '';
    final content = extraMap['content']?.toString() ?? '';
    final lang = extraMap['lang']?.toString() ?? '';
    final createdAtRaw = payload['created_at']?.toString() ??
        extraMap['publish_at']?.toString();
    return NotificationItem(
      type: payload['type']?.toString() ?? '',
      id: _toInt(payload['id']),
      title: title,
      content: content,
      lang: lang,
      createdAt: DateTime.tryParse(
        createdAtRaw?.replaceFirst(' ', 'T') ?? '',
      ),
      extra: extraMap,
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
