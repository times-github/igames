import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

typedef WebUpdateAvailableCallback = void Function(String? version);

JSFunction? _updateListener;

void initializeWebUpdateBridge({
  required WebUpdateAvailableCallback onUpdateAvailable,
}) {
  if (_updateListener != null) {
    web.window.removeEventListener(
      'igames-sw-update-available',
      _updateListener,
    );
  }

  _updateListener = ((web.Event event) {
    onUpdateAvailable(_readVersionFromEvent(event));
  }).toJS;

  web.window.addEventListener('igames-sw-update-available', _updateListener);

  final pendingVersion = _currentPendingVersion();
  if (pendingVersion != null && pendingVersion.isNotEmpty) {
    scheduleMicrotask(() => onUpdateAvailable(pendingVersion));
  }
}

Future<void> applyPendingWebUpdate() async {
  final global = web.window as JSObject;
  final fn = global['__igamesApplyWebUpdate'];
  if (fn == null) {
    return;
  }

  global.callMethodVarArgs<JSAny?>(
    '__igamesApplyWebUpdate'.toJS,
    const [],
  );
}

void dismissPendingWebUpdate() {
  final global = web.window as JSObject;
  final fn = global['__igamesDismissWebUpdate'];
  if (fn == null) {
    return;
  }

  global.callMethodVarArgs<JSAny?>(
    '__igamesDismissWebUpdate'.toJS,
    const [],
  );
}

String? _currentPendingVersion() {
  final global = web.window as JSObject;
  final state = global['__igamesSwUpdateState'];
  if (state == null || state.isUndefinedOrNull) {
    return null;
  }
  final stateObject = state as JSObject;

  final available = stateObject['available'];
  if (available != true.toJS) {
    return null;
  }

  return _jsValueToString(stateObject['version']);
}

String? _readVersionFromEvent(web.Event event) {
  final detail = (event as JSObject)['detail'];
  if (detail == null) {
    return null;
  }

  try {
    final version = (detail as JSObject)['version'];
    return _jsValueToString(version) ?? _jsValueToString(detail);
  } catch (_) {}

  return _jsValueToString(detail);
}

String? _jsValueToString(JSAny? value) {
  if (value == null) {
    return null;
  }

  if (value.isUndefinedOrNull) {
    return null;
  }

  if (value case JSString jsString) {
    return jsString.toDart;
  }

  if (value == true.toJS) {
    return 'true';
  }

  if (value == false.toJS) {
    return 'false';
  }

  return value.dartify()?.toString();
}
