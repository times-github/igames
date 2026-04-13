import 'sse_client_interface.dart';

SseClient getSseClient() => _StubSseClient();

class _StubSseClient implements SseClient {
  @override
  void connect({
    required String url,
    required Map<String, String> headers,
    required SseDataHandler onData,
    SseOpenHandler? onOpen,
    SseDoneHandler? onDone,
    SseErrorHandler? onError,
  }) {}

  @override
  void disconnect() {}
}
