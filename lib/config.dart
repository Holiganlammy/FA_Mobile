class Config {
  static const Map<String, String> headers = {
    'Content-Type': 'application/json'
  };

  static const Map<String, String> headerUploadFile = {
    'Content-Type': 'multipart/form-data'
  };

  static const String appName = "แจ้งเตือน";
  static const String apiURL_Home = "http://172.16.4.164:33052/api";
  static const String apiURL_Local =
      "http://10.20.100.29:33052/api"; //Ipconfig 49.0.64.71:32001
  static const String apiURL_Server = "http://10.15.100.227:32001/api";
  static const String apiURL = apiURL_Server;
}
