// schedule_table_widget.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
          label: Center(
        child: Text('라운드',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      )),
      DataColumn(
          label: Center(
        child: Text('시간',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      )),
    ];

    for (int i = 1; i <= numberOfStadiums; i++) {
      columns.add(DataColumn(
          label: Center(
        child: Text('경기장 $i',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      )));
    }

    columns.add(DataColumn(
        label: Center(
      child: Text('연속 경기 팀',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    )));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: columns,
        rows: schedule.map((row) {
          List<DataCell> cells = [
            DataCell(Center(
                child: Text(row['round'].toString(),
                    style: TextStyle(fontSize: 10)))),
            DataCell(Center(
                child: Text(row['time'].toString(),
                    style: TextStyle(fontSize: 10)))),
          ];

          for (int i = 1; i <= numberOfStadiums; i++) {
            String stadiumKey = 'stadium $i';
            String displayValue = row[stadiumKey]?.toString() ?? 'N/A';

            // 경기 결과 표시
            String scoreDisplay = '';
            if (row['${stadiumKey}_team1Score'] != null &&
                row['${stadiumKey}_team2Score'] != null) {
              int team1Score = row['${stadiumKey}_team1Score'];
              int team2Score = row['${stadiumKey}_team2Score'];
              scoreDisplay = '($team1Score : $team2Score)';
            }

            // 경기 데이터 추출
            Map<String, dynamic> matchData = {};
            if (row[stadiumKey] != null &&
                row[stadiumKey].toString().isNotEmpty) {
              // 해당 경기장의 매치 데이터가 있는 경우
              matchData = {
                'matchId': row['${stadiumKey}_matchId'],
                'competitionCode': row['${stadiumKey}_competitionCode'],
                'team1': row['${stadiumKey}_team1'],
                'team2': row['${stadiumKey}_team2'],
                // 추가 필드
                'team1Score': row['${stadiumKey}_team1Score'],
                'team2Score': row['${stadiumKey}_team2Score'],
              };
            }

            cells.add(DataCell(
              GestureDetector(
                onTap: canEdit &&
                        matchData.isNotEmpty &&
                        matchData['isLunchBreak'] != true
                    ? () => _showResultDialog(context, matchData)
                    : null,
                child: Container(
                  width: double.infinity,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(displayValue, style: TextStyle(fontSize: 10)),
                      if (scoreDisplay.isNotEmpty)
                        Text(scoreDisplay, style: TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
              ),
            ));
          }
// 라운드 번호 표시 부분 수정
          String roundDisplay = row['round'].toString();
          if (roundDisplay == '999') {
            roundDisplay = '';
          }
          cells.add(DataCell(Center(
              child: Text(row['consecutive_team'].toString(),
                  style: TextStyle(fontSize: 10)))));

          return DataRow(cells: cells);
        }).toList(),
      ),
    );
  }

  void _showResultDialog(BuildContext context, Map<String, dynamic> game) {
    final TextEditingController _team1ScoreController =
        TextEditingController(text: game['team1Score']?.toString() ?? '');
    final TextEditingController _team2ScoreController =
        TextEditingController(text: game['team2Score']?.toString() ?? '');

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
                  Text('$team1:', style: TextStyle(fontSize: 16)),
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
                  Text('$team2:', style: TextStyle(fontSize: 16)),
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
      String matchId = game['matchId'];
      String competitionCode = game['competitionCode'];

      // 승자 결정
      String winner;
      if (team1Score > team2Score) {
        winner = game['team1'];
      } else if (team2Score > team1Score) {
        winner = game['team2'];
      } else {
        winner = 'draw';
      }

      await FirebaseFirestore.instance
          .collection('competitions')
          .doc(competitionCode)
          .collection('bracket') // 'bracket' 컬렉션 사용
          .doc(matchId)
          .update({
        'result': '$team1Score:$team2Score',
        'team1Score': team1Score,
        'team2Score': team2Score,
        'winner': winner,
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
