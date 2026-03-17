import 'sse_client_interface.dart';
import 'sse_client_stub.dart' if (dart.library.html) 'sse_client_web.dart';

export 'sse_client_interface.dart';

SseClient createSseClient() => getSseClient();
