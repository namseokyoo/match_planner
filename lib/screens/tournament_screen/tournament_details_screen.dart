import 'package:flutter/material.dart';

class TournamentDetailsScreen extends StatefulWidget {
  final String initialTeam1;
  final String initialTeam2;
  final int initialTeam1Score;
  final int initialTeam2Score;
  final String initialWinner;
  final Function(String, String, String, int, int) onSave;

  TournamentDetailsScreen({
    required this.initialTeam1,
    required this.initialTeam2,
    required this.initialTeam1Score,
    required this.initialTeam2Score,
    required this.initialWinner,
    required this.onSave,
  });

  @override
  _TournamentDetailsScreenState createState() =>
      _TournamentDetailsScreenState();
}

class _TournamentDetailsScreenState extends State<TournamentDetailsScreen> {
  late TextEditingController _team1Controller;
  late TextEditingController _team2Controller;
  late int _team1Score;
  late int _team2Score;
  late String _winner;

  @override
  void initState() {
    super.initState();
    _team1Controller = TextEditingController(text: widget.initialTeam1);
    _team2Controller = TextEditingController(text: widget.initialTeam2);
    _team1Score = widget.initialTeam1Score;
    _team2Score = widget.initialTeam2Score;
    _winner = widget.initialWinner;
  }

  @override
  void dispose() {
    _team1Controller.dispose();
    _team2Controller.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _team1Controller.text = widget.initialTeam1;
      _team2Controller.text = widget.initialTeam2;
      _team1Score = 0; // 점수를 0으로 초기화
      _team2Score = 0; // 점수를 0으로 초기화
      _winner = ''; // 결과 선택 해제
    });
  }

  void _save() {
    widget.onSave(
      _team1Controller.text,
      _team2Controller.text,
      _winner,
      _team1Score,
      _team2Score,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Game Details'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _reset, // 초기화 함수 연결
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Table(
              columnWidths: {
                0: FlexColumnWidth(3), // 팀 이름 칼럼
                1: FlexColumnWidth(1), // 점수 칼럼
                2: FlexColumnWidth(2), // 결과 칼럼
              },
              border: TableBorder.all(width: 1, color: Colors.grey),
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey[200]),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('팀',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('스코어',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('결과',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: _team1Controller,
                        decoration: InputDecoration(border: InputBorder.none),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(Icons.remove),
                            onPressed: () {
                              setState(() {
                                if (_team1Score > 0) _team1Score--;
                              });
                            },
                          ),
                          Text('$_team1Score'),
                          IconButton(
                            icon: Icon(Icons.add),
                            onPressed: () {
                              setState(() {
                                _team1Score++;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: RadioListTile<String>(
                        title: Text(''),
                        value: _team1Controller.text,
                        groupValue: _winner,
                        onChanged: (String? value) {
                          setState(() {
                            _winner = value!;
                          });
                        },
                        // contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: _team2Controller,
                        decoration: InputDecoration(border: InputBorder.none),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(Icons.remove),
                            onPressed: () {
                              setState(() {
                                if (_team2Score > 0) _team2Score--;
                              });
                            },
                          ),
                          Text('$_team2Score'),
                          IconButton(
                            icon: Icon(Icons.add),
                            onPressed: () {
                              setState(() {
                                _team2Score++;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: RadioListTile<String>(
                        title: Text(''),
                        value: _team2Controller.text,
                        groupValue: _winner,
                        onChanged: (String? value) {
                          setState(() {
                            _winner = value!;
                          });
                        },
                        // contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _save,
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
