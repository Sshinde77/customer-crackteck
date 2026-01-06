import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  static Future<dynamic> get(String url, {String? token}) async {
    final response = await http.get(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("API Error ${response.statusCode}");
    }
  }
}
