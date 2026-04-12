String normalizeApiLang(String? raw, {String fallback = 'id'}) {
  final normalized = (raw == null || raw.trim().isEmpty ? fallback : raw.trim())
      .toLowerCase()
      .replaceAll('_', '-');

  if (normalized == 'zh' || normalized == 'zh-cn') {
    return 'zh-cn';
  }
  if (normalized == 'id' || normalized == 'id-id') {
    return 'id';
  }
  if (normalized == 'en' || normalized == 'en-us') {
    return 'en';
  }
  return normalized;
}
