class transactions {
  int? code;
  String? msg;
  Data? data;

  transactions({this.code, this.msg, this.data});

  transactions.fromJson(Map<String, dynamic> json) {
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
  List<TransactionsRecord>? transactionsRecord;
  int? page;
  int? size;
  int? total;

  Data({this.transactionsRecord, this.page, this.size, this.total});

  Data.fromJson(Map<String, dynamic> json) {
    if (json['transactions_record'] != null) {
      transactionsRecord = <TransactionsRecord>[];
      json['transactions_record'].forEach((v) {
        transactionsRecord!.add(new TransactionsRecord.fromJson(v));
      });
    }
    page = json['page'];
    size = json['size'];
    total = json['total'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.transactionsRecord != null) {
      data['transactions_record'] =
          this.transactionsRecord!.map((v) => v.toJson()).toList();
    }
    data['page'] = this.page;
    data['size'] = this.size;
    data['total'] = this.total;
    return data;
  }
}

class TransactionsRecord {
  int? id;
  String? account;
  String? actionType;
  int? amount;
  String? remark;
  String? currency;
  String? gameorderNum;
  String? orderStatus;
  String? createdAt;
  String? updatedAt;
  Null? deletedAt;

  TransactionsRecord(
      {this.id,
      this.account,
      this.actionType,
      this.amount,
      this.remark,
      this.currency,
      this.gameorderNum,
      this.orderStatus,
      this.createdAt,
      this.updatedAt,
      this.deletedAt});

  TransactionsRecord.fromJson(Map<String, dynamic> json) {
    id = json['Id'];
    account = json['Account'];
    actionType = json['ActionType'];
    amount = json['Amount'];
    remark = json['Remark'];
    currency = json['Currency'];
    gameorderNum = json['GameorderNum'];
    orderStatus = json['OrderStatus'];
    createdAt = _formatTimeValue(json['CreatedAt']);
    updatedAt = _formatTimeValue(json['UpdatedAt']);
    deletedAt = json['DeletedAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['Id'] = this.id;
    data['Account'] = this.account;
    data['ActionType'] = this.actionType;
    data['Amount'] = this.amount;
    data['Remark'] = this.remark;
    data['Currency'] = this.currency;
    data['GameorderNum'] = this.gameorderNum;
    data['OrderStatus'] = this.orderStatus;
    data['CreatedAt'] = this.createdAt;
    data['UpdatedAt'] = this.updatedAt;
    data['DeletedAt'] = this.deletedAt;
    return data;
  }
}

String _formatTimeValue(dynamic value) {
  if (value == null) return '';
  if (value is num) {
    return _formatMillis(value);
  }
  final text = value.toString().trim();
  if (text.isEmpty) return '';
  final asNum = num.tryParse(text);
  if (asNum != null) {
    return _formatMillis(asNum);
  }
  final normalized = text.contains('T') ? text : text.replaceFirst(' ', 'T');
  final dt = DateTime.tryParse(normalized);
  if (dt == null) return text;
  return _formatDateTime(dt);
}

String _formatMillis(num value) {
  final ms = value > 100000000000 ? value : value * 1000;
  final dt = DateTime.fromMillisecondsSinceEpoch(ms.toInt());
  return _formatDateTime(dt);
}

String _formatDateTime(DateTime dt) {
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  final hh = dt.hour.toString().padLeft(2, '0');
  final mm = dt.minute.toString().padLeft(2, '0');
  return '$y-$m-$d $hh:$mm';
}
