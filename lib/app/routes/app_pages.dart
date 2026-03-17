import 'package:get/get.dart';

import '../modules/gameStart/bindings/game_start_binding.dart';
import '../modules/gameStart/views/game_start_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home.dart';
import '../modules/message/bindings/message_binding.dart';
import '../modules/message/views/message_view.dart';
import '../modules/message/views/message_detail_view.dart';
import '../modules/favorites/bindings/favorites_binding.dart';
import '../modules/favorites/views/favorites_view.dart';
import '../modules/recently_played/bindings/recently_played_binding.dart';
import '../modules/recently_played/views/recently_played_view.dart';
import '../modules/settings/bindings/settings_binding.dart';
import '../modules/settings/controllers/device_info_controller.dart';
import '../modules/settings/views/about_view.dart';
import '../modules/settings/views/device_info_view.dart';
import '../modules/settings/views/settings_view.dart';
import '../modules/userProfile/bindings/user_profile_binding.dart';
import '../modules/userProfile/views/transaction_history_view.dart';
import '../modules/userProfile/views/user_profile_view.dart';
import '../modules/home/views/withdraw_view.dart';
import '../modules/home/views/account_security_view.dart';
import '../modules/home/views/account_management_view.dart';
import '../modules/home/views/bank_card_view.dart';
import '../modules/home/views/bank_card_add_view.dart';
import '../modules/home/views/bank_selector_view.dart';
import '../modules/home/views/crypto_address_view.dart';
import '../modules/home/views/crypto_address_add_view.dart';
import '../modules/home/views/real_name_view.dart';
import '../modules/home/views/pay_password_view.dart';
import '../modules/home/views/login_password_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.HOME;

  static final routes = [
    GetPage(
      name: _Paths.HOME,
      page: () => Home(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.GAME_START,
      page: () => const GameStartView(),
      binding: GameStartBinding(),
    ),
    GetPage(
      name: _Paths.USER_PROFILE,
      page: () => UserProfileView(),
      binding: UserProfileBinding(),
    ),
    GetPage(
      name: _Paths.TRANSACTION_HISTORY,
      page: () => const TransactionHistoryView(),
      binding: UserProfileBinding(),
    ),
    GetPage(
      name: _Paths.WITHDRAW,
      page: () => const WithdrawView(),
    ),
    GetPage(
      name: _Paths.ACCOUNT_SECURITY,
      page: () => const AccountSecurityView(),
    ),
    GetPage(
      name: _Paths.ACCOUNT_MANAGEMENT,
      page: () => const AccountManagementView(),
    ),
    GetPage(
      name: _Paths.BANK_CARD,
      page: () => const BankCardView(),
    ),
    GetPage(
      name: _Paths.BANK_CARD_ADD,
      page: () => const BankCardAddView(),
    ),
    GetPage(
      name: _Paths.BANK_SELECTOR,
      page: () => const BankSelectorView(),
    ),
    GetPage(
      name: _Paths.CRYPTO_ADDRESS,
      page: () => const CryptoAddressView(),
    ),
    GetPage(
      name: _Paths.CRYPTO_ADDRESS_ADD,
      page: () => const CryptoAddressAddView(),
    ),
    GetPage(
      name: _Paths.REAL_NAME,
      page: () => const RealNameView(),
    ),
    GetPage(
      name: _Paths.PAY_PASSWORD,
      page: () => const PayPasswordView(),
    ),
    GetPage(
      name: _Paths.LOGIN_PASSWORD,
      page: () => const LoginPasswordView(),
    ),
    GetPage(
      name: _Paths.SETTINGS,
      page: () => const SettingsView(),
      binding: SettingsBinding(),
    ),
    GetPage(
      name: Routes.DEVICE_INFO,
      page: () => const DeviceInfoView(),
      binding: BindingsBuilder(
        () => Get.lazyPut<DeviceInfoController>(() => DeviceInfoController()),
      ),
    ),
    GetPage(
      name: Routes.ABOUT,
      page: () => const AboutView(),
    ),
    GetPage(
      name: _Paths.MESSAGE,
      page: () => const MessageView(),
      binding: MessageBinding(),
    ),
    GetPage(
      name: Routes.MESSAGE_DETAIL,
      page: () => const MessageDetailView(),
      binding: MessageBinding(),
    ),
    GetPage(
      name: Routes.FAVORITES,
      page: () => const FavoritesView(),
      binding: FavoritesBinding(),
    ),
    GetPage(
      name: Routes.RECENTLY_PLAYED,
      page: () => const RecentlyPlayedView(),
      binding: RecentlyPlayedBinding(),
    ),
  ];
}
