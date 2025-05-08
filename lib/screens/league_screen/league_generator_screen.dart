import 'package:flutter/material.dart';
import 'package:matches_table/widgets/statistics_table_widget.dart';
import '../../services/league_service.dart';
import 'package:matches_table/widgets/schedule_table_widget.dart';

class LeagueGeneratorScreen extends StatefulWidget {
  final bool isModal; // Add this parameter

  LeagueGeneratorScreen({this.isModal = false}); // Update constructor

  @override
  _LeagueGeneratorScreenState createState() => _LeagueGeneratorScreenState();
}

class _LeagueGeneratorScreenState extends State<LeagueGeneratorScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _groupsController =
      TextEditingController(text: '1');
  final TextEditingController _gamesPerTeamController =
      TextEditingController(text: '5');
  final TextEditingController _teamsController =
      TextEditingController(text: '8');
  final TextEditingController _stadiumsController =
      TextEditingController(text: '2');
  final TextEditingController _gameDurationController =
      TextEditingController(text: '20');
  final TextEditingController _gameIntervalController =
      TextEditingController(text: '5');
  final TextEditingController _lunchStartTimeController =
      TextEditingController(text: '12:00');
  final TextEditingController _lunchBreakDurationController =
      TextEditingController(text: '60');
  final TextEditingController _startTimeController =
      TextEditingController(text: '10:00');
  final TextEditingController _maxConsecutiveGamesController =
      TextEditingController(text: '2');

  List<Map<String, dynamic>>? _scheduleResults;
  List<Map<String, dynamic>>? _statisticsResults;
  bool _isLoading = false;
  bool _isSemiLeagueMode = false; // 세미 리그 모드 체크박스 상태

  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 초기화
      _scheduleResults = [];
      _statisticsResults = [];

      int nGroups = int.parse(_groupsController.text);
      int totalTeams = int.parse(_teamsController.text);

      // 팀을 그룹으로 나누기
      List<int> teamsPerGroup = List.filled(nGroups, totalTeams ~/ nGroups);
      int remainder = totalTeams % nGroups;
      for (int i = 0; i < remainder; i++) {
        teamsPerGroup[i] += 1;
      }

      for (int i = 0; i < nGroups; i++) {
        final payload = {
          'n_groups': 1, // 각 그룹별로 처리하므로 1로 고정
          'n_games_per_team': int.parse(_gamesPerTeamController.text),
          'n_teams': teamsPerGroup[i], // 각 그룹에 할당된 팀 수
          'm_stadiums': int.parse(_stadiumsController.text),
          'game_duration': int.parse(_gameDurationController.text),
          'game_interval': int.parse(_gameIntervalController.text),
          'lunch_start_time': _lunchStartTimeController.text,
          'lunch_break_duration': int.parse(_lunchBreakDurationController.text),
          'start_time': _startTimeController.text,
          'max_consecutive_games':
              int.parse(_maxConsecutiveGamesController.text),
          'num_attempts': 1000,
          'semi_league_mode': _isSemiLeagueMode, // 세미 리그 모드 추가
          'games_per_team':
              int.parse(_gamesPerTeamController.text), // 팀별 경기 수 추가
        };

        final response = await LeagueService.generateSchedule(payload);

        setState(() {
          _scheduleResults!.add({
            'group': i + 1,
            'schedule': List<Map<String, dynamic>>.from(response['schedule']),
          });
          _statisticsResults!.add({
            'group': i + 1,
            'statistics': response['statistics'],
          });
        });
      }
      print(_scheduleResults);
      print(_statisticsResults);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate schedule: $error')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

// Function to handle FAB click and return the generated bracket
  void _applyBracket() {
    if (_scheduleResults != null && _statisticsResults != null) {
      Navigator.pop(context, {
        'scheduleResults': _scheduleResults,
        'statisticsResults': _statisticsResults,
      }); // Return both schedule and statistics results to CreateMatchPage
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please generate a bracket first.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 5,
        title: Text(
          '리그 대진표 생성',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: _isSemiLeagueMode,
                      onChanged: (bool? value) {
                        setState(() {
                          _isSemiLeagueMode = value ?? false;
                        });
                      },
                    ),
                    Text(
                      '세미 리그 모드',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                _buildRow(
                  _groupsController,
                  '그룹 수',
                  _gamesPerTeamController,
                  '팀별 경기 수',
                  isGamesPerTeamEnabled: _isSemiLeagueMode,
                ),
                SizedBox(height: 10),
                _buildRow(
                    _teamsController, '팀 수', _stadiumsController, '경기장 수'),
                SizedBox(height: 10),
                _buildRow(_gameDurationController, '경기 시간 (분)',
                    _gameIntervalController, '경기 간격 (분)'),
                SizedBox(height: 10),
                _buildRow(_lunchStartTimeController, '점심 시작 시간 (HH:MM)',
                    _lunchBreakDurationController, '점심 시간 (분)',
                    keyboardType: TextInputType.datetime),
                SizedBox(height: 10),
                _buildRow(_startTimeController, '시작 시간 (HH:MM)',
                    _maxConsecutiveGamesController, '최대 연속 경기 수',
                    keyboardType: TextInputType.datetime),
                SizedBox(height: 15),
                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : Center(
                        child: ElevatedButton(
                          onPressed: _submitData,
                          child: Text('대진표 생성',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                SizedBox(height: 10),
                if (_scheduleResults != null && _statisticsResults != null)
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _scheduleResults!.length,
                    itemBuilder: (context, index) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '그룹 ${_scheduleResults![index]['group']}',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          StatisticsTable(
                              statistics: _statisticsResults![index]
                                  ['statistics'],
                              primaryColor: Theme.of(context).primaryColor),
                          SizedBox(height: 10),
                          ScheduleTable(
                            schedule: _scheduleResults![index]['schedule'],
                            numberOfStadiums:
                                int.parse(_stadiumsController.text),
                            onResultSaved: () {},
                          ),
                          SizedBox(height: 20),
                        ],
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
      // Show FAB only if this page is displayed as a modal
      floatingActionButton: widget.isModal
          ? FloatingActionButton(
              onPressed: _applyBracket,
              child: Icon(Icons.check),
              backgroundColor: Theme.of(context).primaryColor,
            )
          : null, // Hide FAB if not modal
    );
  }

  Widget _buildRow(TextEditingController controller1, String label1,
      TextEditingController controller2, String label2,
      {TextInputType keyboardType = TextInputType.number,
      bool isGamesPerTeamEnabled = true}) {
    return Row(
      children: [
        Expanded(
            child: _buildTextField(controller1, label1, '$label1을(를) 입력하세요',
                keyboardType: keyboardType)),
        SizedBox(width: 12),
        Expanded(
            child: _buildTextField(controller2, label2, '$label2을(를) 입력하세요',
                keyboardType: keyboardType, enabled: isGamesPerTeamEnabled)),
      ],
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, String placeholder,
      {TextInputType keyboardType = TextInputType.number,
      bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
          hintText: placeholder,
          border: OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).primaryColor),
          ),
          contentPadding: EdgeInsets.all(8.0),
        ),
        keyboardType: keyboardType,
        style: TextStyle(fontSize: 14),
        validator: (value) {
          if (enabled && (value == null || value.isEmpty)) {
            return '$label을(를) 입력하세요';
          }
          return null;
        },
      ),
    );
  }
}
