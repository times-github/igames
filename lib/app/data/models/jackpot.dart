class JackpotRecord {
  final String? account;
  final String? gameName;
  final String? gamehall;
  final String? gamecode;
  final String? iconUrl;
  final num? betAmount;
  final num? winAmount;
  final num? multiplier;
  final String? eventTime;

  JackpotRecord({
    this.account,
    this.gameName,
    this.gamehall,
    this.gamecode,
    this.iconUrl,
    this.betAmount,
    this.winAmount,
    this.multiplier,
    this.eventTime,
  });

  factory JackpotRecord.fromJson(Map<String, dynamic> json) {
    return JackpotRecord(
      account: json['account'] as String?,
      gameName: json['game_name'] as String?,
      gamehall: json['gamehall'] as String?,
      gamecode: json['gamecode'] as String?,
      iconUrl: json['icon_url'] as String?,
      betAmount: json['bet_amount'] as num?,
      winAmount: json['win_amount'] as num?,
      multiplier: json['multiplier'] as num?,
      eventTime: json['event_time']?.toString(),
    );
  }
}

class JackpotResponse {
  final int? code;
  final String? msg;
  final JackpotData? data;

  JackpotResponse({this.code, this.msg, this.data});

  factory JackpotResponse.fromJson(Map<String, dynamic> json) {
    return JackpotResponse(
      code: json['code'] as int?,
      msg: json['msg'] as String?,
      data: json['data'] != null
          ? JackpotData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
}

class JackpotData {
  final List<JackpotRecord>? list;

  JackpotData({this.list});

  factory JackpotData.fromJson(Map<String, dynamic> json) {
    return JackpotData(
      list: json['list'] != null
          ? (json['list'] as List)
              .map((e) => JackpotRecord.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }
}
