class withdrawapi {
  int? code;
  String? msg;
  Data? data;

  withdrawapi({this.code, this.msg, this.data});

  withdrawapi.fromJson(Map<String, dynamic> json) {
    code = json['code'];
    msg = json['msg'];
    data = json['data'] != null ? new Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['code'] = this.code;
    data['msg'] = this.msg;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  String? account;
  String? amount;
  int? id;

  Data({this.account, this.amount, this.id});

  Data.fromJson(Map<String, dynamic> json) {
    account = json['account'];
    amount = json['amount'];
    id = json['id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['account'] = this.account;
    data['amount'] = this.amount;
    data['id'] = this.id;
    return data;
  }
}
