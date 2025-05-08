import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

class ScheduleTable extends StatelessWidget {
  final List<Map<String, dynamic>> schedule;
  final int numberOfStadiums;
  final bool isDetailView;
  final bool canEdit;
  final VoidCallback onResultSaved; // 콜백 추가

  ScheduleTable({
    required this.schedule,
    required this.numberOfStadiums,
    this.isDetailView = false,
    this.canEdit = false,
    required this.onResultSaved, // 콜백 함수 받기
  });

  @override
  Widget build(BuildContext context) {
    List<DataColumn> columns = [
      DataColumn(
          label: Text('라운드',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
      DataColumn(
          label: Text('시간',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
    ];

    for (int i = 1; i <= numberOfStadiums; i++) {
      columns.add(DataColumn(
          label: Text('경기장 $i',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))));
    }

    columns.add(DataColumn(
        label: Text('연속 경기 팀',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: columns,
        rows: schedule.map((row) {
          List<DataCell> cells = [
            DataCell(
                Text(row['round'].toString(), style: TextStyle(fontSize: 10))),
            DataCell(
                Text(row['time'].toString(), style: TextStyle(fontSize: 10))),
          ];

          for (int i = 1; i <= numberOfStadiums; i++) {
            String stadiumKey = 'stadium $i';
            String displayValue = row[stadiumKey]?.toString() ?? 'N/A';

            if (isDetailView && row['result'] != null) {
              displayValue += ' (${row['result']})';
            }

            cells.add(DataCell(
              GestureDetector(
                onTap: canEdit ? () => _showResultDialog(context, row) : null,
                child: Text(displayValue, style: TextStyle(fontSize: 10)),
              ),
            ));
          }

          cells.add(DataCell(Text(row['consecutive_team'].toString(),
              style: TextStyle(fontSize: 10))));

          return DataRow(cells: cells);
        }).toList(),
      ),
    );
  }

  void _showResultDialog(BuildContext context, Map<String, dynamic> game) {
    final TextEditingController _team1ScoreController = TextEditingController();
    final TextEditingController _team2ScoreController = TextEditingController();

    String team1 = game['team1'] ?? '팀 1';
    String team2 = game['team2'] ?? '팀 2';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('경기 결과 입력'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text('$team1:', style: TextStyle(fontSize: 16)), // 팀 1 이름 표시
                  SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _team1ScoreController,
                      decoration: InputDecoration(
                        hintText: '점수 입력',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Text('$team2:', style: TextStyle(fontSize: 16)), // 팀 2 이름 표시
                  SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _team2ScoreController,
                      decoration: InputDecoration(
                        hintText: '점수 입력',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                _saveGameResult(
                  context,
                  game,
                  int.tryParse(_team1ScoreController.text) ?? 0,
                  int.tryParse(_team2ScoreController.text) ?? 0,
                );
                Navigator.of(context).pop();
              },
              child: Text('저장'),
            ),
          ],
        );
      },
    );
  }

  void _saveGameResult(BuildContext context, Map<String, dynamic> game,
      int team1Score, int team2Score) async {
    try {
      String leagueId =
          game['leagueId']; // Ensure this is '1_1' and not just '1'
      String groupId = game['groupId'];
      String matchId = game['matchId'];
      String competitionCode = game['competitionCode'];

      await FirebaseFirestore.instance
          .collection('competitions')
          .doc(competitionCode)
          .collection('leagues')
          .doc(leagueId) // Use the correct leagueId like '1_1'
          .collection('groups')
          .doc(groupId)
          .collection('matches')
          .doc(matchId)
          .update({
        'result': '$team1Score:$team2Score',
        'team1Score': team1Score,
        'team2Score': team2Score,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('경기 결과가 저장되었습니다.')),
      );

      onResultSaved(); // 결과 저장 후 콜백 호출로 상태 갱신
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('경기 결과 저장 실패: $e')),
      );
    }
  }
}
