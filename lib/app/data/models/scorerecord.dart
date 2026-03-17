class scorerecord {
  int? code;
  String? msg;
  Data? data;

  scorerecord({this.code, this.msg, this.data});

  scorerecord.fromJson(Map<String, dynamic> json) {
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
  List<GameScoreRecord>? gameScoreRecord;
  int? page;
  int? size;
  int? total;

  Data({this.gameScoreRecord, this.page, this.size, this.total});

  Data.fromJson(Map<String, dynamic> json) {
    if (json['game_score_record'] != null) {
      gameScoreRecord = <GameScoreRecord>[];
      json['game_score_record'].forEach((v) {
        gameScoreRecord!.add(new GameScoreRecord.fromJson(v));
      });
    }
    page = json['page'];
    size = json['size'];
    total = json['total'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.gameScoreRecord != null) {
      data['game_score_record'] =
          this.gameScoreRecord!.map((v) => v.toJson()).toList();
    }
    data['page'] = this.page;
    data['size'] = this.size;
    data['total'] = this.total;
    return data;
  }
}

class GameScoreRecord {
  int? id;
  double? balanceBefore;
  String? changeType;
  double? changeAmount;
  double? balanceAfter;
  String? eventType;
  int? eventId;
  String? remark;
  String? createdAt;
  String? updatedAt;

  GameScoreRecord(
      {this.id,
      this.balanceBefore,
      this.changeType,
      this.changeAmount,
      this.balanceAfter,
      this.eventType,
      this.eventId,
      this.remark,
      this.createdAt,
      this.updatedAt});

  GameScoreRecord.fromJson(Map<String, dynamic> json) {
    id = json['Id'];
    balanceBefore = json['BalanceBefore'];
    changeType = json['ChangeType'];
    changeAmount = json['ChangeAmount'];
    balanceAfter = json['BalanceAfter'];
    eventType = json['EventType'];
    eventId = json['EventId'];
    remark = json['Remark'];
    createdAt = _formatTimeValue(json['CreatedAt']);
    updatedAt = _formatTimeValue(json['UpdatedAt']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['Id'] = this.id;
    data['BalanceBefore'] = this.balanceBefore;
    data['ChangeType'] = this.changeType;
    data['ChangeAmount'] = this.changeAmount;
    data['BalanceAfter'] = this.balanceAfter;
    data['EventType'] = this.eventType;
    data['EventId'] = this.eventId;
    data['Remark'] = this.remark;
    data['CreatedAt'] = this.createdAt;
    data['UpdatedAt'] = this.updatedAt;
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
