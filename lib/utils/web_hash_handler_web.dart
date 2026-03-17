import 'dart:html';

void ensureHomeHash() {
  final hash = window.location.hash;
  if (hash.isNotEmpty && hash != '#/') {
    window.location.hash = '#/';
  }
}
