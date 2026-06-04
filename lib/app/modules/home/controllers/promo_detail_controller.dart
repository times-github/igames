import 'package:get/get.dart';
import 'promo_controller.dart';

@Deprecated(
    'Activity detail now comes directly from /user/activity/list items.')
class PromoDetailController extends GetxController {
  PromoDetailController({required this.activity});

  final PromoActivity activity;
}
