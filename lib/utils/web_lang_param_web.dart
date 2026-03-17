import 'dart:html';

void setWebHashParams(Map<String, String?> params) {
  if (params.isEmpty) return;
  final uri = Uri.parse(window.location.href);
  final hash = window.location.hash;
  var fragmentValue = hash.startsWith('#') ? hash.substring(1) : hash;
  if (fragmentValue.isEmpty) {
    fragmentValue = '/';
  }
  if (!fragmentValue.startsWith('/')) {
    fragmentValue = '/$fragmentValue';
  }

  final fragmentUri = Uri.tryParse(fragmentValue);
  final mergedQuery =
      Map<String, String>.from(fragmentUri?.queryParameters ?? const {});
  for (final entry in params.entries) {
    final value = entry.value;
    if (value == null || value.isEmpty) {
      mergedQuery.remove(entry.key);
    } else {
      mergedQuery[entry.key] = value;
    }
  }
  final updatedFragment = (fragmentUri ?? Uri(path: '/')).replace(
    queryParameters: mergedQuery.isEmpty ? null : mergedQuery,
  );

  final updatedUri = uri.replace(fragment: updatedFragment.toString());
  window.history.replaceState(null, document.title, updatedUri.toString());
}

void setWebLangParam(String code) {
  final normalized = code.trim().toLowerCase();
  if (normalized.isEmpty) return;
  setWebHashParams({'lang': normalized});
}
