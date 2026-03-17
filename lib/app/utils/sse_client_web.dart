import 'dart:html';
import 'sse_client_interface.dart';

SseClient getSseClient() => _WebSseClient();

class _WebSseClient implements SseClient {
  HttpRequest? _request;
  int _lastIndex = 0;
  String _buffer = '';
  bool _connectedLogged = false;
  late SseDataHandler _onData;
  SseErrorHandler? _onError;

  @override
  void connect({
    required String url,
    required Map<String, String> headers,
    required SseDataHandler onData,
    SseErrorHandler? onError,
  }) {
    disconnect();
    _onData = onData;
    _onError = onError;
    _lastIndex = 0;
    _buffer = '';
    _connectedLogged = false;
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
        print('SSE connected');
      }
    });

    request.onError.listen((event) {
      _onError?.call(event);
    });

    request.onAbort.listen((event) {
      _onError?.call(event);
    });

    request.send();
  }

  void _flushBuffer() {
    final lines = _buffer.split('\n');
    if (!_buffer.endsWith('\n')) {
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
    _request?.abort();
    _request = null;
    _lastIndex = 0;
    _buffer = '';
  }
}
