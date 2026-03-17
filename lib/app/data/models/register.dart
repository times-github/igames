// To parse this JSON data, do
//
//     final register = registerFromJson(jsonString);

import 'dart:convert';

Register registerFromJson(String str) => Register.fromJson(json.decode(str));

String registerToJson(Register data) => json.encode(data.toJson());

class Register {
    int? code;
    String? msg;
    Data? data;

    Register({
        this.code,
        this.msg,
        this.data,
    });

    factory Register.fromJson(Map<String, dynamic> json) => Register(
        code: json["code"],
        msg: json["msg"],
        data: json["data"] == null ? null : Data.fromJson(json["data"]),
    );

    Map<String, dynamic> toJson() => {
        "code": code,
        "msg": msg,
        "data": data?.toJson(),
    };
}

class Data {
    int? id;

    Data({
        this.id,
    });

    factory Data.fromJson(Map<String, dynamic> json) => Data(
        id: json["id"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
    };
}
