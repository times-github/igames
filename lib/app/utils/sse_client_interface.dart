typedef SseDataHandler = void Function(String line);
typedef SseErrorHandler = void Function(Object error);
typedef SseOpenHandler = void Function();
typedef SseDoneHandler = void Function();

abstract class SseClient {
  void connect({
    required String url,
    required Map<String, String> headers,
    required SseDataHandler onData,
    SseOpenHandler? onOpen,
    SseDoneHandler? onDone,
    SseErrorHandler? onError,
  });

  void disconnect();
}
