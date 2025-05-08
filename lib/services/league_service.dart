//league_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class LeagueService {
  static const String _url =
      'https://nnrgy7jp43.execute-api.ap-northeast-2.amazonaws.com/matches_table';

  static Future<Map<String, dynamic>> generateSchedule(
      Map<String, dynamic> payload) async {
    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
    };

    final response = await http
        .post(
          Uri.parse(_url),
          headers: headers,
          body: jsonEncode(payload),
        )
        .timeout(Duration(seconds: 60));

    if (response.statusCode == 200) {
      String responseBody = response.body.replaceAll('NaN', 'null');
      return jsonDecode(responseBody);
    } else {
      print(response.statusCode);

      throw Exception('Failed to generate schedule');
    }
  }
}
