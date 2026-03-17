class loginres {
  int? code;
  String? msg;
  Data? data;

  loginres({this.code, this.msg, this.data});

  loginres.fromJson(Map<String, dynamic> json) {
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
  String? token;
  String? avatar;
  String? nickname;

  Data({this.token, this.avatar, this.nickname});

  Data.fromJson(Map<String, dynamic> json) {
    token = json['token'];
    avatar = json['avatar'];
    nickname = json['nickname'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['token'] = this.token;
    data['avatar'] = this.avatar;
    data['nickname'] = this.nickname;
    return data;
  }
}
