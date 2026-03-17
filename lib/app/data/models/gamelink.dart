class gamelink {
  Data? data;
  Status? status;

  gamelink({this.data, this.status});

  gamelink.fromJson(Map<String, dynamic> json) {
    data = json['data'] != null ? new Data.fromJson(json['data']) : null;
    status =
        json['status'] != null ? new Status.fromJson(json['status']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    if (this.status != null) {
      data['status'] = this.status!.toJson();
    }
    return data;
  }
}

class Data {
  String? url;
  String? token;

  Data({this.url, this.token});

  Data.fromJson(Map<String, dynamic> json) {
    url = json['url'];
    token = json['token'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['url'] = this.url;
    data['token'] = this.token;
    return data;
  }
}

class Status {
  String? code;
  String? message;
  String? datetime;
  String? traceCode;
  String? latency;

  Status(
      {this.code, this.message, this.datetime, this.traceCode, this.latency});

  Status.fromJson(Map<String, dynamic> json) {
    code = json['code'];
    message = json['message'];
    datetime = json['datetime'];
    traceCode = json['traceCode'];
    latency = json['latency'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['code'] = this.code;
    data['message'] = this.message;
    data['datetime'] = this.datetime;
    data['traceCode'] = this.traceCode;
    data['latency'] = this.latency;
    return data;
  }
}
