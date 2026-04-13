import 'dart:html';
import 'sse_client_interface.dart';

SseClient getSseClient() => _WebSseClient();

class _WebSseClient implements SseClient {
  HttpRequest? _request;
  int _lastIndex = 0;
  String _buffer = '';
  bool _connectedLogged = false;
  bool _isDisconnecting = false;
  bool _didComplete = false;
  late SseDataHandler _onData;
  SseOpenHandler? _onOpen;
  SseDoneHandler? _onDone;
  SseErrorHandler? _onError;

  @override
  void connect({
    required String url,
    required Map<String, String> headers,
    required SseDataHandler onData,
    SseOpenHandler? onOpen,
    SseDoneHandler? onDone,
    SseErrorHandler? onError,
  }) {
    disconnect();
    _onData = onData;
    _onOpen = onOpen;
    _onDone = onDone;
    _onError = onError;
    _lastIndex = 0;
    _buffer = '';
    _connectedLogged = false;
    _isDisconnecting = false;
    _didComplete = false;
    final request = HttpRequest();
    _request = request;
    request
      ..open('GET', url)
      ..setRequestHeader('Accept', 'text/event-stream');

    headers.forEach((key, value) {
      if (value.isNotEmpty) {
        request.setRequestHeader(key, value);
      }
    });

    request.onProgress.listen((_) {
      final text = request.responseText ?? '';
      if (text.length <= _lastIndex) return;
      final chunk = text.substring(_lastIndex);
      _lastIndex = text.length;
      _buffer += chunk;
      _flushBuffer();
    });

    request.onReadyStateChange.listen((_) {
      if (_connectedLogged) return;
      if (request.readyState >= HttpRequest.HEADERS_RECEIVED &&
          request.status == 200) {
        _connectedLogged = true;
        _onOpen?.call();
      }
    });

    request.onError.listen((event) {
      if (_didComplete || _isDisconnecting) return;
      _didComplete = true;
      _onError?.call(event);
      _onDone?.call();
    });

    request.onAbort.listen((event) {
      if (_didComplete || _isDisconnecting) return;
      _didComplete = true;
      _onDone?.call();
    });

    request.onLoadEnd.listen((_) {
      if (_didComplete || _isDisconnecting) return;
      _didComplete = true;
      _flushBuffer(flushAll: true);
      if (request.status != 200) {
        _onError?.call(
          'SSE request failed with status ${request.status}: ${request.statusText}',
        );
      }
      _onDone?.call();
    });

    request.send();
  }

  void _flushBuffer({bool flushAll = false}) {
    final lines = _buffer.split('\n');
    if (!flushAll && !_buffer.endsWith('\n')) {
      _buffer = lines.removeLast();
    } else {
      _buffer = '';
    }
    for (final line in lines) {
      _onData(line);
    }
  }

  @override
  void disconnect() {
    _isDisconnecting = true;
    _didComplete = true;
    _request?.abort();
    _request = null;
    _lastIndex = 0;
    _buffer = '';
    _connectedLogged = false;
  }
}
