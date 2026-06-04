import 'package:get/get.dart';
import 'package:igames/app/utils/api_client.dart';
import 'package:igames/app/data/models/desposit.dart';
import 'package:igames/app/data/models/withdraw.dart';

class PaymentServices {
  static final ApiClient _apiClient = ApiClient();

  /// 充值接口
  /// [amount] 充值金额
  /// [remark] 备注信息
  static Future<despositapi> deposit({
    required String amount,
    String remark = '',
  }) async {
    try {
      // 构建请求参数
      final params = {
        'amount': amount,
        'remark': remark,
      };

      // 发送请求
      final response = await _apiClient.post(
        '/user/pay/deposit',
        data: params,
        withAuth: true,
      );

      if (response.statusCode == 200) {
        return despositapi.fromJson(response.data);
      } else {
        throw Exception('${'depositRequestFailed'}.tr: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('${'depositFailed'}.tr + $e');
    }
  }

  /// 获取配置值
  static Future<String?> getConfigValue(
    String key, {
    bool withAuth = true,
  }) async {
    try {
      final response = await _apiClient.get(
        '/user/config/$key',
        withAuth: withAuth,
      );
      if (response.statusCode == 200) {
        final value = _extractConfigValue(response.data);
        return value?.toString();
      }
      throw Exception('getConfigFailed'.tr + ': ${response.statusCode}');
    } catch (e) {
      throw Exception('getConfigFailed'.tr + ': $e');
    }
  }

  /// USDT 充值
  static Future<Map<String, dynamic>> cryptoDeposit({
    required String chain,
    required String amount,
  }) async {
    try {
      final params = {
        'chain': chain,
        'amount': amount,
      };
      final response = await _apiClient.post(
        '/user/crypto/deposit',
        data: params,
        withAuth: true,
      );
      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic>) {
          return Map<String, dynamic>.from(response.data);
        }
        return {'code': 200, 'data': response.data};
      }
      throw Exception('depositRequestFailed'.tr + ': ${response.statusCode}');
    } catch (e) {
      throw Exception('depositFailed'.tr + ': $e');
    }
  }

  /// 取消 USDT 充值
  static Future<Map<String, dynamic>> cancelCryptoDeposit({
    required String orderNo,
  }) async {
    try {
      final response = await _apiClient.post(
        '/user/crypto/deposit/cancel',
        data: {'order_no': orderNo},
        withAuth: true,
      );
      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic>) {
          return Map<String, dynamic>.from(response.data);
        }
        return {'code': 200, 'data': response.data};
      }
      throw Exception('depositRequestFailed'.tr + ': ${response.statusCode}');
    } catch (e) {
      throw Exception('depositFailed'.tr + ': $e');
    }
  }

  static dynamic _extractConfigValue(dynamic data) {
    if (data is Map) {
      final inner = data['data'];
      if (inner is Map) {
        if (inner.containsKey('config_value')) return inner['config_value'];
        if (inner.containsKey('value')) return inner['value'];
      }
      if (inner != null && inner is! Map) return inner;
      if (data.containsKey('config_value')) return data['config_value'];
      if (data.containsKey('value')) return data['value'];
    }
    return data;
  }

  /// 提现接口
  /// [money] 提现金额
  /// [number] 银行卡号
  /// [name] 持卡人姓名
  /// [bankCode] 银行编号
  /// [mobile] 手机号（可选）
  static Future<withdrawapi> withdraw({
    required String money,
    required String number,
    required String name,
    required String bankCode,
    String mobile = '',
  }) async {
    try {
      // 构建请求参数
      final params = {
        'money': money,
        'number': number,
        'name': name,
        'bankCode': bankCode,
      };
      if (mobile.isNotEmpty) {
        params['mobile'] = mobile;
      }

      // 发送请求
      final response = await _apiClient.post(
        '/user/pay/withdraw',
        data: params,
        withAuth: true,
      );

      if (response.statusCode == 200) {
        return withdrawapi.fromJson(response.data);
      } else {
        throw Exception(
            'withdrawRequestFailed'.tr + ': ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('withdrawFailed'.tr + ': $e');
    }
  }

  /// 获取银行列表
  static Future<List<Map<String, dynamic>>> getBankList() async {
    try {
      final result = await _tryBankList([
        '/user/pay/bankList',
        '/pay/bankList',
      ]);
      if (result != null) return result;
      throw Exception('getBankListFailed'.tr);
    } catch (e) {
      throw Exception('getBankListFailed'.tr + ': $e');
    }
  }

  /// 获取提现账户（银行卡/虚拟币地址）
  static Future<Map<String, dynamic>> getWithdrawAccounts() async {
    try {
      final response = await _apiClient.get('/user/pay/withdraw/accounts');
      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map;
        if (data['code'] == 1 && data['data'] is Map) {
          return Map<String, dynamic>.from(data['data']);
        }
      }
      throw Exception('networkError'.tr);
    } catch (e) {
      throw Exception('networkError'.tr + ': $e');
    }
  }

  /// 删除虚拟币提现地址
  static Future<bool> deleteCryptoWithdrawAddress(dynamic id) async {
    try {
      final response = await _apiClient.post(
        '/user/crypto/withdraw-address/delete',
        data: {'id': id},
        withAuth: true,
      );
      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map;
        return data['code'] == 1;
      }
    } catch (_) {}
    return false;
  }

  /// 新增虚拟币提现地址
  static Future<Map<String, dynamic>> createCryptoWithdrawAddress({
    required String address,
    required bool isDefault,
  }) async {
    try {
      final response = await _apiClient.post(
        '/user/crypto/withdraw-address/create',
        data: {
          'address': address,
          'is_default': isDefault ? 1 : 0,
        },
        withAuth: true,
      );
      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map;
        return {
          'ok': data['code'] == 1,
          'code': data['code'],
          'msg': data['msg'],
        };
      }
    } catch (_) {}
    return {'ok': false};
  }

  /// USDT 提现
  static Future<Map<String, dynamic>> cryptoWithdraw({
    required String amount,
    required String chain,
    String token = '',
    String addressId = '',
    String address = '',
  }) async {
    try {
      final params = <String, dynamic>{
        'amount': amount,
        'money': amount,
        'chain': chain,
      };
      if (token.isNotEmpty) {
        params['token'] = token;
      }
      if (addressId.isNotEmpty) {
        params['address_id'] = addressId;
      }
      if (address.isNotEmpty) {
        params['address'] = address;
      }
      final response = await _apiClient.post(
        '/user/crypto/withdraw',
        data: params,
        withAuth: true,
      );
      if (response.statusCode == 200) {
        if (response.data is Map) {
          return Map<String, dynamic>.from(response.data as Map);
        }
        return {'code': 0, 'msg': 'withdrawFailed'};
      }
      return {
        'code': response.statusCode ?? 0,
        'msg': 'withdrawRequestFailed',
      };
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
    }
    return {'code': 0, 'msg': 'withdrawFailed'};
  }

  /// 设置默认虚拟币提现地址
  static Future<Map<String, dynamic>> setCryptoWithdrawAddressDefault(
      dynamic id) async {
    try {
      final response = await _apiClient.post(
        '/user/crypto/withdraw-address/default',
        data: {'id': id},
        withAuth: true,
      );
      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map;
        return {
          'ok': data['code'] == 1,
          'code': data['code'],
          'msg': data['msg'],
        };
      }
    } catch (_) {}
    return {'ok': false};
  }

  /// 新增银行卡
  static Future<Map<String, dynamic>> createBankCard({
    required String bankCode,
    required String bankName,
    String bankShortName = '',
    required String cardNumber,
    required String holderName,
    required bool isDefault,
  }) async {
    try {
      final payload = {
        'bank_code': bankCode,
        'bank_name': bankName,
        'card_number': cardNumber,
        'holder_name': holderName,
        'is_default': isDefault ? 1 : 0,
      };
      if (bankShortName.isNotEmpty) {
        payload['bank_short_name'] = bankShortName;
      }
      final response = await _apiClient.post(
        '/user/bank-card/create',
        data: payload,
        withAuth: true,
      );
      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map;
        return {
          'ok': data['code'] == 1,
          'code': data['code'],
          'msg': data['msg'],
        };
      }
    } catch (_) {}
    return {'ok': false};
  }

  /// 删除银行卡
  static Future<Map<String, dynamic>> deleteBankCard(dynamic id) async {
    try {
      final response = await _apiClient.post(
        '/user/bank-card/delete',
        data: {'id': id},
        withAuth: true,
      );
      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map;
        return {
          'ok': data['code'] == 1,
          'code': data['code'],
          'msg': data['msg'],
        };
      }
    } catch (_) {}
    return {'ok': false};
  }

  /// 设置默认银行卡
  static Future<Map<String, dynamic>> setDefaultBankCard(dynamic id) async {
    try {
      final response = await _apiClient.post(
        '/user/bank-card/default',
        data: {'id': id},
        withAuth: true,
      );
      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map;
        return {
          'ok': data['code'] == 1,
          'code': data['code'],
          'msg': data['msg'],
        };
      }
    } catch (_) {}
    return {'ok': false};
  }

  static Future<List<Map<String, dynamic>>?> _tryBankList(
      List<String> paths) async {
    for (final path in paths) {
      try {
        final response = await _apiClient.get(path);
        if (response.statusCode == 200) {
          final data = response.data;
          if (data['code'] == 200 || data['code'] == 1) {
            return List<Map<String, dynamic>>.from(
                data['data']['bankList'] ?? []);
          }
        }
      } catch (_) {}
    }
    return null;
  }
}
