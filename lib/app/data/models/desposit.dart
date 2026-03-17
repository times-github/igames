class despositapi {
  int? code;
  Data? data;
  String? msg;

  despositapi({this.code, this.data, this.msg});

  despositapi.fromJson(Map<String, dynamic> json) {
    code = json['code'];
    data = json['data'] != null ? new Data.fromJson(json['data']) : null;
    msg = json['msg'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['code'] = this.code;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    data['msg'] = this.msg;
    return data;
  }
}

class Data {
  String? account;
  String? amount;
  int? id;
  String? url;

  Data({this.account, this.amount, this.id, this.url});

  Data.fromJson(Map<String, dynamic> json) {
    account = json['account']?.toString();
    amount = json['amount']?.toString();
    final rawId = json['id'];
    if (rawId is num) {
      id = rawId.toInt();
    } else {
      id = int.tryParse(rawId?.toString() ?? '');
    }
    url = json['url'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['account'] = this.account;
    data['amount'] = this.amount;
    data['id'] = this.id;
    data['url'] = this.url;
    return data;
  }
}
