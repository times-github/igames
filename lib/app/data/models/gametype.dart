class gametype {
  int? code;
  String? msg;
  Data? data;

  gametype({this.code, this.msg, this.data});

  gametype.fromJson(Map<String, dynamic> json) {
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
  List<GameList>? list;
  int? page;
  int? size;
  int? total;

  Data({this.list, this.page, this.size, this.total});

  Data.fromJson(Map<String, dynamic> json) {
    if (json['list'] != null) {
      list = <GameList>[];
      json['list'].forEach((v) {
        list!.add(new GameList.fromJson(v));
      });
    }
    page = json['page'];
    size = json['size'];
    total = json['total'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.list != null) {
      data['list'] = this.list!.map((v) => v.toJson()).toList();
    }
    data['page'] = this.page;
    data['size'] = this.size;
    data['total'] = this.total;
    return data;
  }
}

class GameList {
  int? id;
  String? gamehall;
  String? gamecode;
  String? gametype;
  String? gametech;
  String? status;
  String? maintain;
  String? name;
  String? iconUrl;
  String? lang;
  bool? isFavorite;  // 新增：是否收藏

  GameList(
      {this.id,
      this.gamehall,
      this.gamecode,
      this.gametype,
      this.gametech,
      this.status,
      this.maintain,
      this.name,
      this.iconUrl,
      this.lang,
      this.isFavorite});

  GameList.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    gamehall = json['gamehall'];
    gamecode = json['gamecode'];
    gametype = json['gametype'];
    gametech = json['gametech'];
    status = json['status'];
    maintain = json['maintain'];
    name = json['name'];
    iconUrl = json['icon_url'];
    lang = json['lang'];
    isFavorite = json['is_favorite'] ?? false;  // 新增：解析 is_favorite 字段
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['gamehall'] = this.gamehall;
    data['gamecode'] = this.gamecode;
    data['gametype'] = this.gametype;
    data['gametech'] = this.gametech;
    data['status'] = this.status;
    data['maintain'] = this.maintain;
    data['name'] = this.name;
    data['icon_url'] = this.iconUrl;
    data['lang'] = this.lang;
    data['is_favorite'] = this.isFavorite;  // 新增
    return data;
  }
}
