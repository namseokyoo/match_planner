import 'package:flutter/material.dart';
import 'package:matches_table/widgets/match_card.dart';
import 'tournament_details_screen.dart';
import 'dart:math';

class TournamentGeneratorScreen extends StatefulWidget {
  final bool isModal;
  TournamentGeneratorScreen({this.isModal = false});

  @override
  _TournamentGeneratorScreenState createState() =>
      _TournamentGeneratorScreenState();
}

class _TournamentGeneratorScreenState extends State<TournamentGeneratorScreen> {
  final TextEditingController _teamsController =
      TextEditingController(text: '9'); // 팀 수 입력 컨트롤러
  final TextEditingController _groupController =
      TextEditingController(text: '1'); // 그룹 수 입력 컨트롤러

  // 그룹별 대진표를 저장하는 리스트
  // 각 그룹은 라운드별로 매치 리스트를 포함
  List<List<List<Map<String, dynamic>>>> _groupRounds = [];
  int _matchIdCounter = 1; // 매치 ID 카운터
  int _matchNumberCounter = 1; // 매치 번호 카운터 (일반 그룹용)
  int _finalMatchNumberCounter = 1; // 'Final Tournament' 그룹 매치 번호 카운터
  // 'Final Tournament' 그룹 인덱스
  int? _finalTournamentGroupIndex;

  // 대진표 생성 함수
  void _createBracket() {
    _matchIdCounter = 1; // 매치 ID 초기화
    _matchNumberCounter = 1; // 매치 번호 초기화
    _finalMatchNumberCounter = 1; // 'Final Tournament' 매치 번호 초기화
    int numberOfTeams = int.parse(_teamsController.text);
    int numberOfGroups = int.parse(_groupController.text);

    // 팀 수와 그룹 수 유효성 검사
    if (numberOfTeams < numberOfGroups || numberOfGroups < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('팀 수가 그룹 수보다 많아야 합니다.')),
      );
      return;
    }

    // 팀 리스트 생성
    List<String> teams =
        List.generate(numberOfTeams, (index) => 'Team ${index + 1}');
    teams.shuffle(Random()); // 팀 섞기

    // 그룹별로 팀 나누기
    List<List<String>> groups = [];
    int baseTeamsPerGroup = numberOfTeams ~/ numberOfGroups;
    int remainder = numberOfTeams % numberOfGroups;
    int currentIndex = 0;
    for (int i = 0; i < numberOfGroups; i++) {
      int teamsInThisGroup = baseTeamsPerGroup + (i < remainder ? 1 : 0);
      groups.add(
          teams.sublist(currentIndex, currentIndex + teamsInThisGroup)); // 팀 할당
      currentIndex += teamsInThisGroup;
    }

    // 기존 그룹들의 대진표 생성
    List<List<List<Map<String, dynamic>>>> allGroupRounds = [];
    for (int groupIndex = 0; groupIndex < groups.length; groupIndex++) {
      List<String> groupTeams = List.from(groups[groupIndex]);

      // 팀 수가 홀수인 경우 'Bye' 추가
      if (groupTeams.length % 2 != 0) {
        groupTeams.add('Bye');
      }

      groupTeams.shuffle(Random()); // 그룹 내 팀 섞기
      List<List<Map<String, dynamic>>> rounds = [];
      Set<String> teamsWithBye = {}; // 부전승을 받은 팀 추적

      // 첫 번째 라운드 매치 생성
      List<Map<String, dynamic>> currentRound = [];
      for (int i = 0; i < groupTeams.length; i += 2) {
        String team1 = groupTeams[i];
        String team2 = groupTeams[i + 1];
        String matchNumber;
        if (team1 == 'Bye' || team2 == 'Bye') {
          matchNumber = '부전승 진출';
        } else {
          matchNumber = 'Match ${_matchNumberCounter++}';
        }
        currentRound.add({
          'id': _matchIdCounter++, // 매치 ID
          'team1': team1,
          'team2': team2,
          'matchNumber': matchNumber,
          'winner': team1 == 'Bye'
              ? team2
              : (team2 == 'Bye' ? team1 : ''), // 초기 승자 설정
          'team1Score': 0,
          'team2Score': 0,
          'fromMatchIds': <int>[], // 첫 라운드는 이전 매치 없음
        });
        // 부전승 처리
        if (team1 == 'Bye' || team2 == 'Bye') {
          String byeTeam = team1 == 'Bye' ? team2 : team1;
          teamsWithBye.add(byeTeam);
        }
      }
      rounds.add(currentRound);

      // 이후 라운드 생성
      while (currentRound.length > 1) {
        List<Map<String, dynamic>> nextRound = [];

        // 홀수 매치 수일 경우 부전승 매치 삽입
        if (currentRound.length % 2 != 0) {
          List<int> eligibleMatchIndices = [];
          for (int i = 0; i < currentRound.length; i++) {
            String team = currentRound[i]['winner'];
            if (team != 'Bye' && !teamsWithBye.contains(team)) {
              eligibleMatchIndices.add(i);
            }
          }
          // 부전승 받을 매치가 없을 경우 모든 팀을 대상으로
          if (eligibleMatchIndices.isEmpty) {
            teamsWithBye.clear();
            for (int i = 0; i < currentRound.length; i++) {
              String team = currentRound[i]['winner'];
              if (team != 'Bye') {
                eligibleMatchIndices.add(i);
              }
            }
          }
          // 랜덤하게 매치 선택하여 부전승 매치 삽입
          int selectedMatchIndex = eligibleMatchIndices[
              Random().nextInt(eligibleMatchIndices.length)];
          int insertPosition = selectedMatchIndex + Random().nextInt(2);
          currentRound.insert(insertPosition, {
            'id': _matchIdCounter++,
            'team1': 'Bye',
            'team2': 'Bye',
            'matchNumber': '',
            'winner': 'Bye',
            'team1Score': 0,
            'team2Score': 0,
            'fromMatchIds': <int>[],
          });
          String byeTeam = currentRound[insertPosition + 1]['winner'];
          if (byeTeam != 'Bye') {
            teamsWithBye.add(byeTeam);
          }
        }

        // 다음 라운드 매치 생성
        for (int i = 0; i < currentRound.length; i += 2) {
          Map<String, dynamic> match1 = currentRound[i];
          Map<String, dynamic> match2 = currentRound[i + 1];
          String team1 = match1['winner'].isNotEmpty
              ? match1['winner']
              : 'Winner of ${match1['matchNumber']}';
          String team2 = match2['winner'].isNotEmpty
              ? match2['winner']
              : 'Winner of ${match2['matchNumber']}';
          String matchNumber;
          if (team1 == 'Bye' || team2 == 'Bye') {
            matchNumber = '부전승 진출';
          } else {
            matchNumber = 'Match ${_matchNumberCounter++}';
          }
          nextRound.add({
            'id': _matchIdCounter++, // 매치 ID
            'team1': team1,
            'team2': team2,
            'matchNumber': matchNumber,
            'winner': team1 == 'Bye'
                ? team2
                : (team2 == 'Bye' ? team1 : ''), // 초기 승자 설정
            'team1Score': 0,
            'team2Score': 0,
            'fromMatchIds': [match1['id'], match2['id']],
          });
        }
        // 'Bye'로 승리한 매치 제거
        currentRound.removeWhere((match) => match['winner'] == 'Bye');
        rounds.add(nextRound);
        currentRound = nextRound;
      }

      // 매치 위치 계산
      _calculateMatchPositions(rounds);

      // 그룹별 대진표에 추가
      allGroupRounds.add(rounds);
    }

    // 그룹 수가 2 이상인 경우 'Final Tournament' 그룹 추가
    if (numberOfGroups >= 2) {
      // 'Final Tournament' 그룹 생성
      List<String> finalTeams = List.generate(numberOfGroups, (index) {
        // 각 그룹의 마지막 매치 가져오기
        var lastRound = allGroupRounds[index].last;
        var lastMatch = lastRound.last;
        return 'Winner of ${lastMatch['matchNumber']}';
      });

      // 팀 수가 홀수인 경우 'Bye' 추가
      if (finalTeams.length % 2 != 0) {
        finalTeams.add('Bye');
      }

      // 'Final Tournament' 그룹의 라운드 리스트
      List<List<Map<String, dynamic>>> finalGroupRounds = [];
      List<Map<String, dynamic>> currentRound = [];

      // 첫 번째 라운드 매치 생성
      for (int i = 0; i < finalTeams.length; i += 2) {
        String team1 = finalTeams[i];
        String team2 = finalTeams[i + 1];
        String matchNumber;
        if (team1 == 'Bye' || team2 == 'Bye') {
          matchNumber = '부전승 진출';
        } else {
          matchNumber = 'Final Match ${_finalMatchNumberCounter++}';
        }
        currentRound.add({
          'id': _matchIdCounter++, // 매치 ID
          'team1': team1,
          'team2': team2,
          'matchNumber': matchNumber,
          'winner': team1 == 'Bye'
              ? team2
              : (team2 == 'Bye' ? team1 : ''), // 초기 승자 설정
          'team1Score': 0,
          'team2Score': 0,
          'fromMatchIds': <int>[], // 첫 라운드는 이전 매치 없음
        });
      }
      finalGroupRounds.add(currentRound);

      // 이후 라운드 생성
      while (currentRound.length > 1) {
        List<Map<String, dynamic>> nextRound = [];

        // 홀수 매치 수일 경우 부전승 매치 삽입
        if (currentRound.length % 2 != 0) {
          int selectedMatchIndex =
              Random().nextInt(currentRound.length); // 임의 선택
          currentRound.insert(selectedMatchIndex, {
            'id': _matchIdCounter++,
            'team1': 'Bye',
            'team2': 'Bye',
            'matchNumber': '',
            'winner': 'Bye',
            'team1Score': 0,
            'team2Score': 0,
            'fromMatchIds': <int>[],
          });
        }

        // 다음 라운드 매치 생성
        for (int i = 0; i < currentRound.length; i += 2) {
          Map<String, dynamic> match1 = currentRound[i];
          Map<String, dynamic> match2 = currentRound[i + 1];
          String team1 = match1['winner'].isNotEmpty
              ? match1['winner']
              : 'Winner of ${match1['matchNumber']}';
          String team2 = match2['winner'].isNotEmpty
              ? match2['winner']
              : 'Winner of ${match2['matchNumber']}';
          String matchNumber;
          if (team1 == 'Bye' || team2 == 'Bye') {
            matchNumber = '부전승 진출';
          } else {
            matchNumber = 'Final Match ${_finalMatchNumberCounter++}';
          }
          nextRound.add({
            'id': _matchIdCounter++, // 매치 ID
            'team1': team1,
            'team2': team2,
            'matchNumber': matchNumber,
            'winner': team1 == 'Bye'
                ? team2
                : (team2 == 'Bye' ? team1 : ''), // 초기 승자 설정
            'team1Score': 0,
            'team2Score': 0,
            'fromMatchIds': [match1['id'], match2['id']],
          });
        }
        // 'Bye'로 승리한 매치 제거
        currentRound.removeWhere((match) => match['winner'] == 'Bye');
        finalGroupRounds.add(nextRound);
        currentRound = nextRound;
      }

      // 매치 위치 계산
      _calculateMatchPositions(finalGroupRounds);

      // 'Final Tournament' 그룹 인덱스 저장
      _finalTournamentGroupIndex = allGroupRounds.length;
      // 'Final Tournament' 그룹 대진표 추가
      allGroupRounds.add(finalGroupRounds);
    }

    // 상태 업데이트
    setState(() {
      _groupRounds = allGroupRounds;
    });
  }

  // 매치 위치 계산 함수
  void _calculateMatchPositions(List<List<Map<String, dynamic>>> rounds) {
    Map<int, double> matchPositions = {};
    Map<int, Map<String, dynamic>> matchIdToMatch = {};
    double cardHeight = 100.0; // 매치 카드 높이
    double verticalSpacing = 20.0; // 카드 간 간격

    for (int roundIndex = 0; roundIndex < rounds.length; roundIndex++) {
      double currentTopPosition = 0.0;
      for (var match in rounds[roundIndex]) {
        double topPosition;
        // 매치를 ID로 매핑
        matchIdToMatch[match['id']] = match;
        List<int> fromMatchIds =
            List<int>.from(match['fromMatchIds'].cast<int>());
        // 이전 매치의 위치를 기반으로 현재 매치의 위치 계산
        List<double> prevPositions = fromMatchIds
            .where((int id) {
              Map<String, dynamic>? prevMatch = matchIdToMatch[id];
              return prevMatch != null && prevMatch['winner'] != 'Bye';
            })
            .map((int id) => matchPositions[id] ?? currentTopPosition)
            .toList();
        double desiredPosition = prevPositions.isNotEmpty
            ? prevPositions.reduce((a, b) => a + b) / prevPositions.length
            : currentTopPosition;
        topPosition = max(desiredPosition, currentTopPosition);
        matchPositions[match['id']] = topPosition;
        match['topPosition'] = topPosition;
        currentTopPosition =
            max(currentTopPosition, topPosition + cardHeight + verticalSpacing);
      }
    }
  }

  // 다음 라운드 업데이트 함수 (그룹 인덱스 추가)
  void _updateNextRounds(int groupIndex, int roundIndex, int matchId) {
    if (groupIndex >= _groupRounds.length ||
        roundIndex + 1 >= _groupRounds[groupIndex].length) return;

    // 현재 매치에서 승자 가져오기
    Map<String, dynamic> currentMatch = _groupRounds[groupIndex][roundIndex]
        .firstWhere((match) => match['id'] == matchId);
    String winner = currentMatch['winner'];

    // 다음 라운드의 매치들 순회
    for (var nextMatch in _groupRounds[groupIndex][roundIndex + 1]) {
      List<int> fromMatchIds = nextMatch['fromMatchIds'].cast<int>();
      if (fromMatchIds.contains(matchId)) {
        int indexInFromMatchIds = fromMatchIds.indexOf(matchId);
        // team1 또는 team2 업데이트
        if (indexInFromMatchIds == 0) {
          nextMatch['team1'] = winner.isNotEmpty
              ? winner
              : 'Winner of ${currentMatch['matchNumber']}';
        } else if (indexInFromMatchIds == 1) {
          nextMatch['team2'] = winner.isNotEmpty
              ? winner
              : 'Winner of ${currentMatch['matchNumber']}';
        }
        // 부전승 처리
        if (nextMatch['team1'] == 'Bye') {
          nextMatch['winner'] = nextMatch['team2'];
          nextMatch['matchNumber'] = '부전승 진출';
        } else if (nextMatch['team2'] == 'Bye') {
          nextMatch['winner'] = nextMatch['team1'];
          nextMatch['matchNumber'] = '부전승 진출';
        } else {
          // 둘 다 부전승이 아닌 경우 초기화
          nextMatch['winner'] = '';
          nextMatch['team1Score'] = 0;
          nextMatch['team2Score'] = 0;
          if (_finalTournamentGroupIndex != null &&
              groupIndex == _finalTournamentGroupIndex) {
            // 'Final Tournament' 그룹일 경우
            nextMatch['matchNumber'] =
                'Final Match ${_finalMatchNumberCounter++}';
          } else {
            nextMatch['matchNumber'] = 'Match ${_matchNumberCounter++}';
          }
        }
        // 매치 위치 재계산 필요
        _calculateMatchPositions(_groupRounds[groupIndex]);

        // 재귀적으로 다음 라운드를 업데이트합니다.
        _updateNextRounds(groupIndex, roundIndex + 1, nextMatch['id']);
      }
    }

    // 'Final Tournament' 그룹 업데이트 필요 여부 확인
    int numberOfGroups = int.parse(_groupController.text);
    if (groupIndex < numberOfGroups &&
        roundIndex == _groupRounds[groupIndex].length - 1) {
      _regenerateFinalTournament();
    }
  }

  // 'Final Tournament' 그룹 재생성 함수
  void _regenerateFinalTournament() {
    if (_groupRounds.length < int.parse(_groupController.text) + 1) {
      // 'Final Tournament' 그룹이 존재하지 않음
      return;
    }

    // 각 그룹의 최종 매치의 winner를 사용하여 finalTeams 생성
    List<String> finalTeams = [];
    int numberOfGroups = int.parse(_groupController.text);
    for (int i = 0; i < numberOfGroups; i++) {
      var lastRound = _groupRounds[i].last;
      var finalMatch = lastRound.last;
      String winner = finalMatch['winner'];
      if (winner.isEmpty) {
        winner = 'Winner of ${finalMatch['matchNumber']}';
      } else if (winner.startsWith('Winner of')) {
        // 이미 'Winner of Match {number}' 형식인 경우 유지
      } else {
        // 실제 팀 이름인 경우
      }
      finalTeams.add(winner);
    }

    // 'Final Tournament' 그룹 팀 갱신
    int finalGroupIndex = _finalTournamentGroupIndex!;
    List<String> finalGroupTeams = List.from(finalTeams);

    // 홀수인 경우 'Bye' 추가
    if (finalGroupTeams.length % 2 != 0) {
      finalGroupTeams.add('Bye');
    }

    // 'Final Tournament' 그룹의 기존 라운드 제거
    _groupRounds.removeAt(finalGroupIndex);

    // 'Final Tournament' 그룹의 새로운 라운드 생성
    List<List<Map<String, dynamic>>> finalGroupRounds = [];
    List<Map<String, dynamic>> currentRound = [];

    // 첫 번째 라운드 매치 생성
    for (int i = 0; i < finalGroupTeams.length; i += 2) {
      String team1 = finalGroupTeams[i];
      String team2 = finalGroupTeams[i + 1];
      String matchNumber;
      if (team1 == 'Bye' || team2 == 'Bye') {
        matchNumber = '부전승 진출';
      } else {
        matchNumber = 'Final Match ${_finalMatchNumberCounter++}';
      }
      currentRound.add({
        'id': _matchIdCounter++, // 매치 ID
        'team1': team1,
        'team2': team2,
        'matchNumber': matchNumber,
        'winner':
            team1 == 'Bye' ? team2 : (team2 == 'Bye' ? team1 : ''), // 초기 승자 설정
        'team1Score': 0,
        'team2Score': 0,
        'fromMatchIds': <int>[], // 첫 라운드는 이전 매치 없음
      });
    }
    finalGroupRounds.add(currentRound);

    // 이후 라운드 생성
    while (currentRound.length > 1) {
      List<Map<String, dynamic>> nextRound = [];

      // 홀수 매치 수일 경우 부전승 매치 삽입
      if (currentRound.length % 2 != 0) {
        int selectedMatchIndex = Random().nextInt(currentRound.length);
        currentRound.insert(selectedMatchIndex, {
          'id': _matchIdCounter++,
          'team1': 'Bye',
          'team2': 'Bye',
          'matchNumber': '',
          'winner': 'Bye',
          'team1Score': 0,
          'team2Score': 0,
          'fromMatchIds': <int>[],
        });
      }

      // 다음 라운드 매치 생성
      for (int i = 0; i < currentRound.length; i += 2) {
        Map<String, dynamic> match1 = currentRound[i];
        Map<String, dynamic> match2 = currentRound[i + 1];
        String team1 = match1['winner'].isNotEmpty
            ? match1['winner']
            : 'Winner of ${match1['matchNumber']}';
        String team2 = match2['winner'].isNotEmpty
            ? match2['winner']
            : 'Winner of ${match2['matchNumber']}';
        String matchNumber;
        if (team1 == 'Bye' || team2 == 'Bye') {
          matchNumber = '부전승 진출';
        } else {
          matchNumber = 'Final Match ${_finalMatchNumberCounter++}';
        }
        nextRound.add({
          'id': _matchIdCounter++, // 매치 ID
          'team1': team1,
          'team2': team2,
          'matchNumber': matchNumber,
          'winner': team1 == 'Bye'
              ? team2
              : (team2 == 'Bye' ? team1 : ''), // 초기 승자 설정
          'team1Score': 0,
          'team2Score': 0,
          'fromMatchIds': [match1['id'], match2['id']],
        });
      }
      // 'Bye'로 승리한 매치 제거
      currentRound.removeWhere((match) => match['winner'] == 'Bye');
      finalGroupRounds.add(nextRound);
      currentRound = nextRound;
    }

    // 매치 위치 계산
    _calculateMatchPositions(finalGroupRounds);

    // 'Final Tournament' 그룹 대진표 갱신
    _groupRounds.insert(finalGroupIndex, finalGroupRounds);

    // 상태 업데이트
    setState(() {});
  }

  // 게임 상세 정보 열기 함수 (그룹 인덱스 추가)
  void _openGameDetails(int groupIndex, Map<String, dynamic> match,
      int roundIndex, int matchIndex) async {
    // 'Bye'인 매치는 건너뜀
    if (match['team1'] == null ||
        match['team2'] == null ||
        match['matchNumber'] == '부전승 진출') return;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: TournamentDetailsScreen(
            initialTeam1: match['team1'],
            initialTeam2: match['team2'],
            initialTeam1Score: match['team1Score'],
            initialTeam2Score: match['team2Score'],
            initialWinner: match['winner'],
            onSave: (team1, team2, winner, team1Score, team2Score) {
              setState(() {
                _groupRounds[groupIndex][roundIndex][matchIndex]['team1'] =
                    team1;
                _groupRounds[groupIndex][roundIndex][matchIndex]['team2'] =
                    team2;
                _groupRounds[groupIndex][roundIndex][matchIndex]['winner'] =
                    winner;
                _groupRounds[groupIndex][roundIndex][matchIndex]['team1Score'] =
                    team1Score;
                _groupRounds[groupIndex][roundIndex][matchIndex]['team2Score'] =
                    team2Score;
                _updateNextRounds(groupIndex, roundIndex,
                    _groupRounds[groupIndex][roundIndex][matchIndex]['id']);
              });
            },
          ),
        );
      },
    );
  }

  // FAB 클릭 시 대진표 적용
  void _applyBracket() {
    if (_groupRounds.isNotEmpty) {
      Navigator.pop(context, _groupRounds);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('대진표를 먼저 생성해주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 매치 카드 높이 및 간격 설정
    double cardWidth = 150.0;
    double cardHeight = 100.0;
    double verticalSpacing = 20.0;
    double horizontalSpacing = 20.0;

    return Scaffold(
      appBar: AppBar(
        title: Text('토너먼트 대진표'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 팀 수와 그룹 수 입력 필드
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _teamsController,
                          decoration: InputDecoration(
                            labelText: '경기에 참여하는 팀 수',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      SizedBox(width: 20),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: int.parse(_groupController.text),
                          decoration: InputDecoration(
                            labelText: '그룹 수',
                            border: OutlineInputBorder(),
                          ),
                          items: [1, 2, 4, 8, 16].map((int value) {
                            return DropdownMenuItem<int>(
                              value: value,
                              child: Text(value.toString()),
                            );
                          }).toList(),
                          onChanged: (int? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _groupController.text = newValue.toString();
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  // 대진표 생성 버튼
                  ElevatedButton(
                    onPressed: _createBracket,
                    child: Text('대진표 생성'),
                  ),
                  SizedBox(height: 20),
                  Divider(),
                  SizedBox(height: 20),
                  // 그룹별 대진표 표시
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(_groupRounds.length, (groupIndex) {
                      // 각 그룹의 총 높이와 너비 계산
                      double totalHeight = 0.0;
                      for (var round in _groupRounds[groupIndex]) {
                        for (var match in round) {
                          double matchBottom = (match['topPosition'] ?? 0.0) +
                              cardHeight +
                              verticalSpacing;
                          if (matchBottom > totalHeight) {
                            totalHeight = matchBottom;
                          }
                        }
                      }

                      int numRounds = _groupRounds[groupIndex].length;
                      double totalWidth = numRounds * cardWidth +
                          (numRounds - 1) * horizontalSpacing;

                      // 그룹 이름 설정
                      String groupName;
                      if (_finalTournamentGroupIndex != null &&
                          groupIndex == _finalTournamentGroupIndex) {
                        groupName = 'Final Tournament';
                      } else {
                        groupName = '그룹 ${groupIndex + 1}';
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 40.0),
                        child: Container(
                          width: double.infinity,
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
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 그룹 제목
                              Text(
                                groupName,
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 10),
                              // 전체 그룹의 대진표를 포함하는 Stack
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minWidth: constraints.maxWidth,
                                  ),
                                  child: IntrinsicWidth(
                                    child: Column(
                                      children: [
                                        Container(
                                          width: totalWidth,
                                          height: totalHeight,
                                          child: Stack(
                                            children: [
                                              // BracketPainter를 그룹 전체에 대해 사용
                                              CustomPaint(
                                                size: Size(
                                                    totalWidth, totalHeight),
                                                painter: BracketPainter(
                                                  groupRounds:
                                                      _groupRounds[groupIndex],
                                                  cardWidth: cardWidth,
                                                  cardHeight: cardHeight,
                                                  horizontalSpacing:
                                                      horizontalSpacing,
                                                ),
                                              ),
                                              // 각 라운드와 매치 카드 배치
                                              ...List.generate(
                                                  _groupRounds[groupIndex]
                                                      .length, (roundIndex) {
                                                return Positioned(
                                                  left: (cardWidth +
                                                          horizontalSpacing) *
                                                      roundIndex,
                                                  child: Column(
                                                    children: List.generate(
                                                      _groupRounds[groupIndex]
                                                              [roundIndex]
                                                          .length,
                                                      (matchIndex) {
                                                        final match = _groupRounds[
                                                                    groupIndex]
                                                                [roundIndex]
                                                            [matchIndex];
                                                        return Padding(
                                                          padding:
                                                              EdgeInsets.only(
                                                            top: match[
                                                                    'topPosition'] ??
                                                                0.0,
                                                          ),
                                                          child: MatchCard(
                                                            team1:
                                                                match['team1'] ==
                                                                        'Bye'
                                                                    ? null
                                                                    : match[
                                                                        'team1'],
                                                            team2:
                                                                match['team2'] ==
                                                                        'Bye'
                                                                    ? null
                                                                    : match[
                                                                        'team2'],
                                                            team1Score: match[
                                                                'team1Score'],
                                                            team2Score: match[
                                                                'team2Score'],
                                                            winner:
                                                                match['winner'],
                                                            matchNumber: match[
                                                                'matchNumber'],
                                                            onTap: match['team1'] ==
                                                                        'Bye' ||
                                                                    match['team2'] ==
                                                                        'Bye'
                                                                ? null
                                                                : () =>
                                                                    _openGameDetails(
                                                                      groupIndex,
                                                                      match,
                                                                      roundIndex,
                                                                      matchIndex,
                                                                    ),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                );
                                              }),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      // 플로팅 액션 버튼 (모달일 경우에만 표시)
      floatingActionButton: widget.isModal
          ? FloatingActionButton(
              onPressed: _applyBracket,
              child: Icon(Icons.check),
              backgroundColor: Theme.of(context).primaryColor,
            )
          : null,
    );
  }
}

class BracketPainter extends CustomPainter {
  final List<List<Map<String, dynamic>>> groupRounds;
  final double cardWidth;
  final double cardHeight;
  final double horizontalSpacing;

  BracketPainter({
    required this.groupRounds,
    required this.cardWidth,
    required this.cardHeight,
    required this.horizontalSpacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 2.0;

    for (var roundIndex = 0;
        roundIndex < groupRounds.length - 1;
        roundIndex++) {
      var currentRound = groupRounds[roundIndex];
      var nextRound = groupRounds[roundIndex + 1];

      for (var match in currentRound) {
        // 현재 라운드 카드의 오른쪽 가운데 좌표
        final currentX =
            (cardWidth + horizontalSpacing) * roundIndex + cardWidth;
        final currentY = (match['topPosition'] ?? 0.0) + cardHeight / 2;

        // 해당 매치와 연결된 다음 라운드의 매치 찾기
        for (var nextMatch in nextRound) {
          if (nextMatch['fromMatchIds'].contains(match['id'])) {
            // 다음 라운드 카드의 왼쪽 가운데 좌표
            final nextX = (cardWidth + horizontalSpacing) * (roundIndex + 1);
            final nextY = (nextMatch['topPosition'] ?? 0.0) + cardHeight / 2;

            // 선 그리기
            canvas.drawLine(
              Offset(currentX, currentY),
              Offset(nextX, nextY),
              paint,
            );
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant BracketPainter oldDelegate) {
    return false;
  }
}
