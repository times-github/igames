typedef SseDataHandler = void Function(String line);
typedef SseErrorHandler = void Function(Object error);

abstract class SseClient {
  void connect({
    required String url,
    required Map<String, String> headers,
    required SseDataHandler onData,
    SseErrorHandler? onError,
  });

  void disconnect();
}
