class LaunchParams {
  static String? _registerCode;
  static bool _autoOpenAuth = false;
  static bool _autoOpenConsumed = false;
  static String? _langCode;

  static void captureFromUri(Uri uri) {
    _langCode = _extractLang(uri);
    final code = _extractCode(uri);
    if (code != null) {
      setRegisterCode(code, autoOpenAuth: true);
      return;
    }

    final path = uri.path;
    final fragmentPath = _parseFragmentUri(uri)?.path;
    if (path == '/register' || fragmentPath == '/register') {
      _autoOpenAuth = true;
    }
  }

  static String? get registerCode => _registerCode;
  static String? get langCode => _langCode;
  static void setRegisterCode(String? code, {bool autoOpenAuth = false}) {
    final normalized = _normalizeParam(code);
    _registerCode = normalized;
    if (autoOpenAuth && normalized != null) {
      _autoOpenAuth = true;
    }
  }

  static void clearRegisterCode() {
    _registerCode = null;
    _autoOpenAuth = false;
    _autoOpenConsumed = false;
  }

  static bool consumeAutoOpenAuth() {
    if (_autoOpenConsumed) return false;
    _autoOpenConsumed = true;
    return _autoOpenAuth;
  }

  static String? _extractCode(Uri uri) {
    final fragmentUri = _parseFragmentUri(uri);
    if (fragmentUri == null) return null;
    return _normalizeParam(fragmentUri.queryParameters['invite_code']);
  }

  static String? _extractLang(Uri uri) {
    final fragmentUri = _parseFragmentUri(uri);
    if (fragmentUri == null) return null;
    return _normalizeLangParam(fragmentUri.queryParameters['lang']);
  }

//
  static String? _normalizeParam(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return trimmed;
  }

  static String? _normalizeLangParam(String? value) {
    if (value == null) return null;
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    if (normalized == 'en' || normalized == 'en-us' || normalized == 'en_us') {
      return 'en';
    }
    if (normalized == 'id' || normalized == 'id-id' || normalized == 'id_id') {
      return 'id';
    }
    if (normalized == 'cn' ||
        normalized == 'zh' ||
        normalized == 'zh-cn' ||
        normalized == 'zh_cn') {
      return 'zh';
    }
    return null;
  }

  static Uri? _parseFragmentUri(Uri uri) {
    final fragment = uri.fragment;
    if (fragment.isEmpty) return null;
    final normalized = fragment.startsWith('/') ? fragment : '/$fragment';
    return Uri.tryParse(normalized);
  }
}
