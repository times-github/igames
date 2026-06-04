import 'package:get/get.dart';
import 'package:igames/app/modules/auth/controllers/auth_controller.dart';

enum UserStatusErrorType {
  banned,
  frozen,
}

class UserStatusError {
  const UserStatusError({
    required this.type,
    required this.code,
    required this.message,
  });

  final UserStatusErrorType type;
  final int? code;
  final String? message;

  bool get isBanned => type == UserStatusErrorType.banned;
  bool get isFrozen => type == UserStatusErrorType.frozen;

  String get messageKey {
    switch (type) {
      case UserStatusErrorType.banned:
        return 'user_banned';
      case UserStatusErrorType.frozen:
        return 'user_frozen';
    }
  }

  String get localizedMessage => messageKey.tr;
}

UserStatusError? parseUserStatusError({
  dynamic code,
  String? message,
}) {
  final parsedCode = code is int ? code : int.tryParse(code?.toString() ?? '');

  if (parsedCode == 3103) {
    return UserStatusError(
      type: UserStatusErrorType.banned,
      code: parsedCode,
      message: message,
    );
  }

  if (parsedCode == 3104) {
    return UserStatusError(
      type: UserStatusErrorType.frozen,
      code: parsedCode,
      message: message,
    );
  }

  return null;
}

Future<bool> handleUserStatusError({
  dynamic code,
  String? message,
  String? titleKey,
  bool showMessage = true,
  bool redirectToLoginOnBanned = true,
}) async {
  final statusError = parseUserStatusError(code: code, message: message);
  if (statusError == null) {
    return false;
  }

  if (showMessage) {
    Get.snackbar(
      (titleKey ?? 'tip').tr,
      statusError.localizedMessage,
      snackPosition: SnackPosition.TOP,
    );
  }

  if (statusError.isBanned && Get.isRegistered<AuthController>()) {
    final auth = Get.find<AuthController>();
    await auth.handleUserBanned(
      openLogin: redirectToLoginOnBanned,
    );
  }

  return true;
}
