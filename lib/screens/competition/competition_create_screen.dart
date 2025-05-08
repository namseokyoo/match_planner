import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:matches_table/models/competition.dart';
import 'package:matches_table/services/competition_service.dart';
import 'package:matches_table/widgets/match_card.dart';
import 'package:matches_table/widgets/schedule_table_widget.dart';
import 'package:matches_table/widgets/statistics_table_widget.dart';
import '../league_screen/league_generator_screen.dart';
import '../tournament_screen/tournament_generator_screen.dart';
import 'competition_summary_screen.dart';

class CompetitionCreateScreen extends StatefulWidget {
  final String matchCode;

  CompetitionCreateScreen({required this.matchCode});

  @override
  _CompetitionCreateScreenState createState() =>
      _CompetitionCreateScreenState();
}

class _CompetitionCreateScreenState extends State<CompetitionCreateScreen> {
  final List<List<Map<String, dynamic>>> _leagueResults = [];
  final List<List<Map<String, dynamic>>> _leagueStatistics = [];
  final List<List<List<Map<String, dynamic>>>> _tournamentResults = [];

  final TextEditingController _competitionNameController =
      TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  final TextEditingController _competitionLocationController =
      TextEditingController();
  final TextEditingController _organizerPasswordController =
      TextEditingController();
  final TextEditingController _participantPasswordController =
      TextEditingController();

  DateTime _selectedStartDate = DateTime.now();
  TimeOfDay _selectedStartTime = TimeOfDay.now();
  DateTime _selectedEndDate = DateTime.now().add(Duration(hours: 2));
  TimeOfDay _selectedEndTime = TimeOfDay(
    hour: TimeOfDay.now().hour + 2,
    minute: TimeOfDay.now().minute,
  );

  @override
  void initState() {
    super.initState();
    _startDateController.text =
        DateFormat('yyyy-MM-dd').format(_selectedStartDate);
    _startTimeController.text = DateFormat('h:mm a').format(_selectedStartDate);
    _endDateController.text = DateFormat('yyyy-MM-dd').format(_selectedEndDate);
    _endTimeController.text = DateFormat('h:mm a').format(_selectedEndDate);
  }

  void _openLeagueModal() async {
    // 이미 리그가 추가되어 있는지 확
    if (_leagueResults.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('리그는 하나만 추가할 수 있습니다.')),
      );
      return;
    }

    final result = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: SizedBox(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.8,
            child: LeagueGeneratorScreen(isModal: true),
          ),
        );
      },
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        if (result['scheduleResults'] != null &&
            result['statisticsResults'] != null) {
          _leagueResults.add(result['scheduleResults']);
          _leagueStatistics.add(result['statisticsResults']);
        } else {
          // print('Error: Incomplete league data returned from modal.');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('리그 데이터가 불완전합니다. 다시 시도해 주세요.')),
          );
        }
      });
    }
  }

  void _openTournamentModal() async {
    // 이미 토너먼트가 추되 있는지 확인
    if (_tournamentResults.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('토너먼트는 하나만 추가할 수 있습니다.')),
      );
      return;
    }

    final result = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: SizedBox(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.8,
            child: TournamentGeneratorScreen(isModal: true),
          ),
        );
      },
    );

    if (result != null && result is List<List<List<Map<String, dynamic>>>>) {
      setState(() {
        _tournamentResults.addAll(result); // 수정된 부분
      });
    }
  }

  Future<void> _saveCompetitionToDB() async {
    if (!_validateInputs()) {
      return;
    }

    final String competitionCode = widget.matchCode;

    try {
      DateTime startDateTime = DateFormat('yyyy-MM-dd h:mm a')
          .parse('${_startDateController.text} ${_startTimeController.text}');
      DateTime endDateTime = DateFormat('yyyy-MM-dd h:mm a')
          .parse('${_endDateController.text} ${_endTimeController.text}');

      // print('groupcount: ${_leagueResults[0].length}');

      // Create Competition object
      Competition competition = Competition(
        code: competitionCode,
        name: _competitionNameController.text,
        location: _competitionLocationController.text,
        organizerPassword: _organizerPasswordController.text,
        participantPassword: _participantPasswordController.text,
        startDateTime: startDateTime,
        endDateTime: endDateTime,
        groupCount: _leagueResults[0].length,
      );

      // Prepare Statistics and Matches data
      List<LeagueStatistics> statistics = _prepareStatisticsData();
      List<LeagueMatch> matches = _prepareMatchData();

      // Create CompetitionService instance
      CompetitionService competitionService = CompetitionService();

      // Save competition info to DB
      await competitionService.saveCompetitionToDB(
        competitionCode: competition.code,
        competitionName: competition.name,
        location: competition.location,
        organizerPassword: competition.organizerPassword,
        participantPassword: competition.participantPassword,
        startDateTime: competition.startDateTime,
        endDateTime: competition.endDateTime,
        leagueResults: _leagueResults.expand((e) => e).toList(),
        groupCount: competition.groupCount,
      );

      // Save statistics and matches to DB
      await competitionService.saveStatistics(competitionCode, statistics);
      await competitionService.saveMatches(competitionCode, matches);

      // print('Competition, Statistics, and Matches saved successfully.');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Competition saved successfully!')),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CompetitionSummaryScreen(
            competition: competition,
            leagueCount: _leagueResults.length,
            tournamentCount: _tournamentResults.length,
          ),
        ),
      );
    } catch (e) {
      // print('Error saving competition: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save competition: $e')),
      );
    }
  }

  // Helper method to prepare statistics data
  List<LeagueStatistics> _prepareStatisticsData() {
    List<LeagueStatistics> statistics = [];
    for (var groupStats in _leagueStatistics) {
      for (var stat in groupStats) {
        statistics.add(LeagueStatistics(
          id: '${stat['group']}_stats',
          group: stat['group'] ?? 0,
          consecutiveGamesPerTeam: Map<String, int>.from(
              stat['statistics']['Number of consecutive games per team'] ?? {}),
          totalConsecutiveMatches:
              stat['statistics']['Total number of consecutive matches'] ?? 0,
          totalMatches: stat['statistics']['Total number of matches'] ?? 0,
          totalRounds: stat['statistics']['Total number of rounds'] ?? 0,
          totalEmptySlots:
              stat['statistics']['Total empty slots across all rounds'] ?? 0,
        ));
      }
    }
    return statistics;
  }

  // Helper method to prepare match data
  List<LeagueMatch> _prepareMatchData() {
    List<LeagueMatch> matches = [];

    for (var league in _leagueResults) {
      int groupIndex = 1;

      for (var group in league) {
        for (var schedule in group['schedule']) {
          for (String stadiumKey in schedule.keys) {
            if (stadiumKey.startsWith('stadium')) {
              String? matchDetail = schedule[stadiumKey];

              if (matchDetail != null && matchDetail.isNotEmpty) {
                String stadiumNumber = stadiumKey.replaceAll('stadium ', '');

                if (matchDetail == 'Lunch Break') {
                  // Save lunch break entry
                  matches.add(LeagueMatch(
                    matchId:
                        'group_${groupIndex}_stadium_${stadiumNumber}_lunch_break',
                    team1: '',
                    team2: '',
                    group: groupIndex,
                    round: schedule['round'] == 'Lunch Break'
                        ? 999
                        : schedule['round'],
                    time: schedule['time'],
                    consecutiveTeam: schedule['consecutive_team'],
                    stadium: stadiumKey,
                    isLunchBreak: true,
                  ));
                } else {
                  List<String> teams = matchDetail.split(' vs ');
                  if (teams.length == 2) {
                    matches.add(LeagueMatch(
                      matchId:
                          'group_${groupIndex}_match_${teams[0]}_vs_${teams[1]}',
                      team1: teams[0],
                      team2: teams[1],
                      group: groupIndex,
                      round: schedule['round'],
                      time: schedule['time'],
                      consecutiveTeam: schedule['consecutive_team'],
                      stadium: stadiumKey,
                      isLunchBreak: false,
                    ));
                  }
                }
              }
            }
          }
        }
        groupIndex++;
      }
    }

    return matches;
  }

  Future<void> _selectDate(BuildContext context,
      TextEditingController controller, DateTime initialDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _selectTime(BuildContext context,
      TextEditingController controller, TimeOfDay initialTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked != null) {
      setState(() {
        controller.text = picked.format(context);
      });
    }
  }

  bool _validateInputs() {
    if (_competitionNameController.text.isEmpty ||
        _competitionLocationController.text.isEmpty ||
        _organizerPasswordController.text.isEmpty ||
        _participantPasswordController.text.isEmpty ||
        _startDateController.text.isEmpty ||
        _startTimeController.text.isEmpty ||
        _endDateController.text.isEmpty ||
        _endTimeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('모든 필드를 입력해 주세요.')),
      );
      return false;
    }

    if (!RegExp(r'^\d{4}$').hasMatch(_organizerPasswordController.text) ||
        !RegExp(r'^\d{4}$').hasMatch(_participantPasswordController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('비밀번호는 숫자 4자리여야 합니다.')),
      );
      return false;
    }

    if (_organizerPasswordController.text ==
        _participantPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('개최자용 비밀번호와 참가자용 비밀번호는 달라야 합니다.')),
      );
      return false;
    }

    if (_leagueResults.isEmpty && _tournamentResults.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('리그 또는 토너먼트를 생성해야 합니다.')),
      );
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('대회 개최'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 100.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '새로운 대회 생성',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '(대회 코드: ${widget.matchCode})',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 20),
                      _buildCompetitionInfoForm(),
                      SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: _openLeagueModal,
                            child: Text('리그 경기 생성'),
                          ),
                          SizedBox(width: 20),
                          ElevatedButton(
                            onPressed: _openTournamentModal,
                            child: Text('토너먼트 경기 생성'),
                          ),
                        ],
                      ),
                      SizedBox(height: 30),
                      if (_leagueResults.isNotEmpty) ...[
                        Text(
                          '리그 대진표',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 10),
                        _buildLeagueResults(),
                        SizedBox(height: 30),
                      ],
                      if (_tournamentResults.isNotEmpty) ...[
                        Text(
                          '토너먼트 대진표',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 10),
                        _buildTournamentResults(),
                        SizedBox(height: 30),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveCompetitionToDB,
        child: Text('대회개최'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildLeagueResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(_leagueResults.length, (index) {
        return Container(
          width: double.infinity, // 박스의 가로 크기를 화면 전체로 설정
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(10.0),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 5,
                offset: Offset(0, 3), // 그림자 위치
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '리그 ${index + 1}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _leagueResults.removeAt(index);
                        _leagueStatistics.removeAt(index);
                      });
                    },
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:
                    List.generate(_leagueResults[index].length, (subIndex) {
                  final statistics = _leagueStatistics.length > index &&
                          _leagueStatistics[index].length > subIndex
                      ? _leagueStatistics[index][subIndex]['statistics']
                      : null;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '그룹 ${_leagueResults[index][subIndex]['group']}',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      if (statistics != null)
                        StatisticsTable(
                          statistics: statistics,
                          primaryColor: Theme.of(context).primaryColor,
                        ),
                      SizedBox(height: 10),
                      ScheduleTable(
                        schedule: _leagueResults[index][subIndex]['schedule'],
                        numberOfStadiums: 2,
                        onResultSaved: () {},
                      ),
                      SizedBox(height: 20),
                    ],
                  );
                }),
              ),
            ],
          ),
        );
      }),
    );
  }

// Inside CompetitionCreateScreen

  Widget _buildTournamentResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_tournamentResults.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '토너먼트 대진표',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  setState(() {
                    _tournamentResults.clear();
                  });
                },
              ),
            ],
          ),
          SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(_tournamentResults.length, (index) {
              List<List<Map<String, dynamic>>> rounds =
                  _tournamentResults[index];
              double cardHeight = 100.0;
              double verticalSpacing = 20.0;
              double totalHeight = 0.0;

              for (var round in rounds) {
                for (var match in round) {
                  double matchBottom = (match['topPosition'] ?? 0.0) +
                      cardHeight +
                      verticalSpacing;
                  if (matchBottom > totalHeight) {
                    totalHeight = matchBottom;
                  }
                }
              }

              String groupName = index == _tournamentResults.length - 1
                  ? 'Final Tournament'
                  : '그룹 ${index + 1}';

              return Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Container(
                  width: double.infinity, // 박스의 가로 크기를 화면 전체로 설정
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: Offset(0, 3), // 그림자 위치
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        groupName,
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(rounds.length, (roundIndex) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 20.0),
                              child: Column(
                                children: [
                                  Text(
                                    'Round ${roundIndex + 1}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: 150,
                                    height: totalHeight,
                                    child: Stack(
                                      children: List.generate(
                                        rounds[roundIndex].length,
                                        (matchIndex) {
                                          final match =
                                              rounds[roundIndex][matchIndex];
                                          return Positioned(
                                            top: match['topPosition'] ?? 0.0,
                                            child: MatchCard(
                                              team1: match['team1'] == 'Bye'
                                                  ? null
                                                  : match['team1'],
                                              team2: match['team2'] == 'Bye'
                                                  ? null
                                                  : match['team2'],
                                              team1Score: match['team1Score'],
                                              team2Score: match['team2Score'],
                                              winner: match['winner'],
                                              matchNumber: match['matchNumber'],
                                              onTap: null, // 터치 이벤트 필요 시 추가 가능
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  Widget _buildCompetitionInfoForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        TextField(
          controller: _competitionNameController,
          decoration: InputDecoration(
            labelText: '대회 이름',
            hintText: '예: 전국 축구 대회',
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 20),
        TextField(
          controller: _competitionLocationController,
          decoration: InputDecoration(
            labelText: '대회 장소',
            hintText: '예: 서울 월드컵 경기장',
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: TextField(
                controller: _startDateController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: '시작 날짜',
                  hintText: '예: 2024-09-01',
                  border: OutlineInputBorder(),
                ),
                onTap: () => _selectDate(
                    context, _startDateController, _selectedStartDate),
              ),
            ),
            SizedBox(width: 20),
            Expanded(
              child: TextField(
                controller: _startTimeController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: '시작 시간',
                  hintText: '예: 15:30',
                  border: OutlineInputBorder(),
                ),
                onTap: () => _selectTime(
                    context, _startTimeController, _selectedStartTime),
              ),
            ),
          ],
        ),
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: TextField(
                controller: _endDateController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: '종료 날짜',
                  hintText: '예: 2024-09-01',
                  border: OutlineInputBorder(),
                ),
                onTap: () =>
                    _selectDate(context, _endDateController, _selectedEndDate),
              ),
            ),
            SizedBox(width: 20),
            Expanded(
              child: TextField(
                controller: _endTimeController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: '종료 시간',
                  hintText: '예: 18:00',
                  border: OutlineInputBorder(),
                ),
                onTap: () =>
                    _selectTime(context, _endTimeController, _selectedEndTime),
              ),
            ),
          ],
        ),
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: TextField(
                controller: _organizerPasswordController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '개최자용 비밀번호',
                  hintText: '4자리 숫자',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(width: 20),
            Expanded(
              child: TextField(
                controller: _participantPasswordController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '참가자용 비밀번호',
                  hintText: '4자리 숫자',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
