// competition_details_view_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:matches_table/widgets/schedule_table_widget.dart';
import 'package:matches_table/widgets/statistics_table_widget.dart';

class CompetitionDetailsviewScreen extends StatefulWidget {
  final Map<String, dynamic> contestData;
  final bool canEdit;

  CompetitionDetailsviewScreen({
    required this.contestData,
    required this.canEdit,
  });

  @override
  _CompetitionDetailsviewScreenState createState() =>
      _CompetitionDetailsviewScreenState();
}

class _CompetitionDetailsviewScreenState
    extends State<CompetitionDetailsviewScreen> {
  late Future<List<Map<String, dynamic>>> _leaguesFuture;

  @override
  void initState() {
    super.initState();
    _leaguesFuture = _fetchLeagues(widget.contestData['code']);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('대회 정보'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            // mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '대회 정보',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              _buildInfoRow('대회 이름:', widget.contestData['name'] ?? '정보 없음'),
              _buildInfoRow(
                  '대회 장소:', widget.contestData['location'] ?? '정보 없음'),
              _buildInfoRow(
                '시작 날짜 및 시간:',
                widget.contestData['startDateTime'] != null
                    ? DateFormat('yyyy-MM-dd h:mm a').format(
                        (widget.contestData['startDateTime'] as Timestamp)
                            .toDate())
                    : '정보 없음',
              ),
              _buildInfoRow(
                '종료 날짜 및 시간:',
                widget.contestData['endDateTime'] != null
                    ? DateFormat('yyyy-MM-dd h:mm a').format(
                        (widget.contestData['endDateTime'] as Timestamp)
                            .toDate())
                    : '정보 없음',
              ),
              _buildInfoRow('대회 코드:', widget.contestData['code'] ?? '정보 없음'),
              SizedBox(height: 20),
              if (widget.canEdit)
                ElevatedButton(
                  onPressed: () {
                    // 대회 수정 로직
                  },
                  child: Text('대회 수정'),
                ),
              SizedBox(height: 20),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _leaguesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    print(snapshot.error);
                    return Center(
                        child:
                            Text('데이터를 가져오는 중 오류가 발생했습니다: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('등록된 리그나 토너먼트가 없습니다.'));
                  } else {
                    final leagues = snapshot.data!;
                    print(snapshot.data!);
                    return _buildLeaguesAndTournaments(leagues, context);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(value.toString()),
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchLeagues(
      String competitionCode) async {
    List<Map<String, dynamic>> leagues = [];

    // 모든 매치 데이터를 가져옵니다.
    QuerySnapshot matchSnapshot = await FirebaseFirestore.instance
        .collection('competitions')
        .doc(competitionCode)
        .collection('bracket')
        .get();

    // 그룹별로 매치를 분류합니다.
    Map<int, List<Map<String, dynamic>>> matchesByGroup = {};

    for (var matchDoc in matchSnapshot.docs) {
      Map<String, dynamic> matchData = matchDoc.data() as Map<String, dynamic>;
      int group = matchData['group'];

      if (!matchesByGroup.containsKey(group)) {
        matchesByGroup[group] = [];
      }
      matchesByGroup[group]!.add(matchData);
    }

    // 각 그룹별로 일정과 통계 데이터를 구성합니다.
    for (int group in matchesByGroup.keys) {
      List<Map<String, dynamic>> matches = matchesByGroup[group]!;

      // 통계 데이터 가져오기
      DocumentSnapshot statisticsDoc = await FirebaseFirestore.instance
          .collection('competitions')
          .doc(competitionCode)
          .collection('statistics')
          .doc('${group}_stats')
          .get();

      Map<String, dynamic> statisticsData = {};
      if (statisticsDoc.exists) {
        statisticsData = statisticsDoc.data() as Map<String, dynamic>;
      }

      // StatisticsTable이 기대하는 키로 통계 데이터 조정
      Map<String, dynamic> adjustedStatisticsData = {
        'Total number of matches': statisticsData['totalMatches'] ?? 0,
        'Total number of rounds': statisticsData['totalRounds'] ?? 0,
        'Total empty slots across all rounds':
            statisticsData['totalEmptySlots'] ?? 0,
        'Number of consecutive games per team':
            statisticsData['consecutiveGamesPerTeam'] ?? {},
      };

      // 일정 데이터 재구성
      List<Map<String, dynamic>> schedule =
          _reconstructSchedule(matches, competitionCode);

      // 경기장 수 계산
      Set<String> stadiumSet = matches
          .map((match) => match['stadium'] as String)
          .map((s) => s.replaceAll('stadium ', ''))
          .toSet();
      List<String> stadiums = stadiumSet.toList()..sort();

      // 리그 데이터에 추가
      leagues.add({
        'groupId': 'group_$group',
        'name': '그룹 $group',
        'schedule': schedule,
        'statistics': adjustedStatisticsData,
        'numberOfStadiums': stadiums.length,
      });
    }

    return leagues;
  }

  List<Map<String, dynamic>> _reconstructSchedule(
      List<Map<String, dynamic>> matches, String competitionCode) {
    // 라운드별로 매치를 분류하고, 라운드별 시간을 저장합니다.
    Map<int, List<Map<String, dynamic>>> matchesByRound = {};
    Map<int, DateTime> roundTimes = {};

    // 라운드별로 연속 경기 팀 정보를 저장할 맵을 만듭니다.
    Map<int, String> consecutiveTeamsByRound = {};

    for (var match in matches) {
      int round = match['round'];
      if (!matchesByRound.containsKey(round)) {
        matchesByRound[round] = [];
      }
      matchesByRound[round]!.add(match);

      // 연속 경기 팀 파싱
      String consecutiveTeam = match['consecutiveTeam'];

      // 라운드별로 연속 경기 팀 저장
      if (consecutiveTeam.isNotEmpty) {
        consecutiveTeamsByRound[round] = consecutiveTeam;
      }

      // 시간 파싱
      String timeString = match['time'];
      DateTime? time;
      try {
        // 시간 문자열을 파싱합니다 (예: '09:00')
        time = DateFormat('HH:mm').parse(timeString);
        // 날짜 부분은 임의로 설정합니다 (예: 2000년 1월 1일)
        time = DateTime(2000, 1, 1, time.hour, time.minute);
      } catch (e) {
        // 파싱 실패 시 null로 설정
        time = null;
      }

      if (time != null) {
        if (!roundTimes.containsKey(round)) {
          roundTimes[round] = time;
        }
      }
    }

    // 전체 라운드 번호 목록 생성
    int maxRound = matchesByRound.keys.isNotEmpty
        ? matchesByRound.keys.reduce((a, b) => a > b ? a : b)
        : 0;
    List<int> allRounds = List<int>.generate(maxRound, (index) => index + 1);

    // 경기장 목록 생성
    Set<String> stadiumSet = matches
        .map((match) => match['stadium'] as String)
        .map((s) => s.replaceAll('stadium ', ''))
        .toSet();
    List<String> stadiums = stadiumSet.toList()..sort();

    // 모든 라운드에 대해 시간 설정
    Map<int, DateTime> allRoundTimes = {};

    // 기존 라운드 시간 복사
    allRoundTimes.addAll(roundTimes);

    // 라운드 간 평균 시간 간격 계산
    Duration averageInterval = _calculateAverageInterval(roundTimes);

    // 빈 라운드에 시간 할당
    for (int round in allRounds) {
      if (!allRoundTimes.containsKey(round)) {
        // 이전 및 다음 라운드 찾기
        int prevRound = round - 1;
        while (prevRound > 0 && !allRoundTimes.containsKey(prevRound)) {
          prevRound--;
        }
        int nextRound = round + 1;
        while (nextRound <= maxRound && !allRoundTimes.containsKey(nextRound)) {
          nextRound++;
        }

        if (prevRound > 0 && nextRound <= maxRound) {
          // 이전 및 다음 라운드 모두 시간이 있는 경우
          DateTime prevTime = allRoundTimes[prevRound]!;
          DateTime nextTime = allRoundTimes[nextRound]!;
          int roundsBetween = nextRound - prevRound;
          Duration timeDiff = nextTime.difference(prevTime);
          Duration timePerRound = Duration(
              milliseconds: (timeDiff.inMilliseconds / roundsBetween).round());
          // 현재 라운드 시간 계산
          allRoundTimes[round] =
              prevTime.add(timePerRound * (round - prevRound));
        } else if (prevRound > 0) {
          // 이전 라운드만 시간이 있는 경우
          allRoundTimes[round] = allRoundTimes[prevRound]!.add(averageInterval);
        } else if (nextRound <= maxRound) {
          // 다음 라운드만 시간이 있는 경우
          allRoundTimes[round] = allRoundTimes[nextRound]!
              .subtract(averageInterval * (nextRound - round));
        } else {
          // 이전 및 다음 라운드 모두 시간이 없는 경우
          // 기본 시간 설정
          allRoundTimes[round] =
              DateTime(2000, 1, 1, 9, 0).add(averageInterval * (round - 1));
        }
      }
    }

    // 일정 데이터 생성
    List<Map<String, dynamic>> schedule = [];

    for (int round in allRounds) {
      List<Map<String, dynamic>> roundMatches = matchesByRound[round] ?? [];

      DateTime roundTime = allRoundTimes[round]!;
      String formattedTime = DateFormat('HH:mm').format(roundTime);

      // 해당 라운드의 연속 경기 팀 가져오기
      String consecutiveTeam = consecutiveTeamsByRound[round] ?? '';

      Map<String, dynamic> row = {
        'round': round,
        'time': formattedTime,
        'consecutive_team': consecutiveTeam,
      };

      for (var stadium in stadiums) {
        String stadiumKey = 'stadium $stadium';
        Map<String, dynamic>? matchInStadium = roundMatches.firstWhere(
            (match) => match['stadium'] == stadiumKey,
            orElse: () => {});

        if (matchInStadium.isNotEmpty) {
          String matchDetail =
              '${matchInStadium['team1']} vs ${matchInStadium['team2']}';
          row[stadiumKey] = matchDetail;
          row['${stadiumKey}_matchId'] = matchInStadium['matchId'];
          row['${stadiumKey}_competitionCode'] = competitionCode;
          row['${stadiumKey}_team1'] = matchInStadium['team1'];
          row['${stadiumKey}_team2'] = matchInStadium['team2'];
          row['${stadiumKey}_team1Score'] = matchInStadium['team1Score'];
          row['${stadiumKey}_team2Score'] = matchInStadium['team2Score'];
        } else {
          row[stadiumKey] = '';
        }
      }

      schedule.add(row);
    }

    return schedule;
  }

  // 라운드 간 평균 시간 간격을 계산하는 함수
  Duration _calculateAverageInterval(Map<int, DateTime> roundTimes) {
    if (roundTimes.length < 2) {
      // 시간 정보가 두 개 미만이면 기본 간격 1시간 반환
      return Duration(hours: 1);
    }

    // 라운드 번호로 정렬
    List<int> sortedRounds = roundTimes.keys.toList()..sort();

    // 시간 간격 리스트
    List<Duration> intervals = [];

    for (int i = 1; i < sortedRounds.length; i++) {
      int prevRound = sortedRounds[i - 1];
      int currentRound = sortedRounds[i];

      DateTime prevTime = roundTimes[prevRound]!;
      DateTime currentTime = roundTimes[currentRound]!;

      Duration interval = currentTime.difference(prevTime);
      intervals.add(interval);
    }

    // 평균 시간 간격 계산
    int totalMilliseconds =
        intervals.fold(0, (sum, interval) => sum + interval.inMilliseconds);
    int averageMilliseconds = (totalMilliseconds / intervals.length).round();

    return Duration(milliseconds: averageMilliseconds);
  }

  Widget _buildLeaguesAndTournaments(
      List<Map<String, dynamic>> leagues, BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: leagues.length,
      itemBuilder: (context, index) {
        final league = leagues[index];
        final groupId = league['groupId'];
        final groupName = league['name'];
        final schedule = league['schedule'];
        final statistics = league['statistics'];
        final numberOfStadiums = league['numberOfStadiums'];

        return Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildGroupDetails(
                schedule, context, groupId, statistics, numberOfStadiums),
          ),
        );
      },
    );
  }

  Widget _buildGroupDetails(
      List<Map<String, dynamic>> schedule,
      BuildContext context,
      String groupId,
      Map<String, dynamic> statistics,
      int numberOfStadiums) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '그룹: $groupId',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        StatisticsTable(
          statistics: statistics,
          primaryColor: Theme.of(context).primaryColor,
        ),
        SizedBox(height: 20),
        ScheduleTable(
          schedule: schedule,
          numberOfStadiums: numberOfStadiums,
          isDetailView: true,
          canEdit: widget.canEdit,
          onResultSaved: _onResultSaved,
        ),
      ],
    );
  }

  // 경기 결과 저장 후 상태 갱신을 위한 함수
  void _onResultSaved() {
    setState(() {
      _leaguesFuture = _fetchLeagues(widget.contestData['code']);
    });
  }
}
