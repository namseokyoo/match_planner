// statistics_table_widget.dart

import 'package:flutter/material.dart';

class StatisticsTable extends StatelessWidget {
  final Map<String, dynamic> statistics;
  final Color primaryColor;

  StatisticsTable({required this.statistics, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    // 'Number of consecutive games per team' 값 가져오기
    var consecutiveGamesPerTeam =
        statistics['Number of consecutive games per team'];

    // totalConsecutiveGames 초기화
    int totalConsecutiveGames = 0;

    if (consecutiveGamesPerTeam != null &&
        consecutiveGamesPerTeam is Map<String, dynamic>) {
      // Ensure all values are integers
      totalConsecutiveGames = consecutiveGamesPerTeam.values
          .fold<int>(0, (int sum, dynamic value) => sum + (value as int));
    } else {
      consecutiveGamesPerTeam = {}; // null인 경우 빈 맵으로 초기화
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Card(
          color: primaryColor,
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('대진표 요약',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('총 경기 수: ${statistics['Total number of matches'] ?? 0}',
                    style: TextStyle(fontSize: 12)),
                Text('라운드 수: ${statistics['Total number of rounds'] ?? 0}',
                    style: TextStyle(fontSize: 12)),
                Text(
                    '비어있는 경기 수 (점심시간 포함): ${statistics['Total empty slots across all rounds'] ?? 0}',
                    style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ),
        SizedBox(width: 10),
        Card(
          color: primaryColor,
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('팀별 연속경기 수',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ...consecutiveGamesPerTeam.entries.map((entry) {
                  return Text('${entry.key}: ${entry.value}',
                      style: TextStyle(fontSize: 12));
                }).toList(),
                SizedBox(height: 5),
                Text('총 연속 경기 수: $totalConsecutiveGames',
                    style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
