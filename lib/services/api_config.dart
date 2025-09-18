class ApiConfig {
  static const String baseUrl = "http://192.168.2.28:3000";
  static String getDetectUrl() => "$baseUrl/api/detect";
  static String? _token;

  static String getBaseUrl() => baseUrl;
  static void setToken(String token) {
    _token = token;
  }

  static String? getToken() => _token;
  static Map<String, String> get headers => {
    "Content-Type": "application/json",
    if (_token != null && _token!.isNotEmpty) "Authorization": "Bearer $_token",
  };
}
