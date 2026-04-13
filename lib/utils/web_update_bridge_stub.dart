typedef WebUpdateAvailableCallback = void Function(String? version);

void initializeWebUpdateBridge({
  required WebUpdateAvailableCallback onUpdateAvailable,
}) {}

Future<void> applyPendingWebUpdate() async {}

void dismissPendingWebUpdate() {}
