import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart'; // For clipboard copy functionality
import 'package:matches_table/models/competition.dart';

class CompetitionSummaryScreen extends StatelessWidget {
  final Competition competition;
  final int leagueCount; // Number of leagues created
  final int tournamentCount; // Number of tournaments created

  CompetitionSummaryScreen({
    required this.competition,
    required this.leagueCount,
    required this.tournamentCount,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('대회 요약'),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              _copyCompetitionInfoToClipboard(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '대회 정보',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            _buildInfoRow('대회 코드:', competition.code),
            _buildInfoRow('대회 이름:', competition.name),
            _buildInfoRow('대회 장소:', competition.location),
            _buildInfoRow(
              '시작 날짜 및 시간:',
              DateFormat('yyyy-MM-dd h:mm a').format(competition.startDateTime),
            ),
            _buildInfoRow(
              '종료 날짜 및 시간:',
              DateFormat('yyyy-MM-dd h:mm a').format(competition.endDateTime),
            ),
            _buildInfoRow('개최자 비밀번호', competition.organizerPassword),
            _buildInfoRow('참가자 비밀번호:', competition.participantPassword),
            SizedBox(height: 20),
            _buildInfoRow('생성된 리그 개수:',
                leagueCount.toString()), // Display number of leagues
            _buildInfoRow('생성된 토너먼트 개수:',
                tournamentCount.toString()), // Display number of tournaments
            SizedBox(height: 30),
            Expanded(
              child: FutureBuilder(
                future: _fetchCompetitionDetails(competition.code),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('데이터를 가져오는 중 오류가 발생했습니다.'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('등록된 리그나 토너먼트가 없습니다.'));
                  } else {
                    final data = snapshot.data as Map<String, dynamic>;
                    return ListView(
                      children: [
                        // if (data['leagues'] != null)
                        //   _buildLeagueList(context, data['leagues']),
                        // if (data['tournaments'] != null)
                        // _buildTournamentList(context, data['tournaments']),
                      ],
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _fetchCompetitionDetails(
      String competitionCode) async {
    final leagueCollection = await FirebaseFirestore.instance
        .collection('competitions')
        .doc(competitionCode)
        .collection('leagues')
        .get();

    final tournamentCollection = await FirebaseFirestore.instance
        .collection('competitions')
        .doc(competitionCode)
        .collection('tournaments')
        .get();

    final leagues = leagueCollection.docs.map((doc) => doc.data()).toList();
    final tournaments =
        tournamentCollection.docs.map((doc) => doc.data()).toList();

    return {
      'leagues': leagues,
      'tournaments': tournaments,
    };
  }

  Widget _buildLeagueList(BuildContext context, List<dynamic> leagues) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '리그:',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        ...leagues.asMap().entries.map((entry) {
          int index = entry.key + 1; // For numbering leagues
          var league = entry.value;
          return Card(
            margin: EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
              title: Text('리그 $index'),
              subtitle: Text('ID: ${league['id']}'),
              onTap: () {
                // Navigate to league details page
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder: (context) => LeagueDetailsScreen(leagueId: league['id']), // Add your LeagueDetailsScreen here
                //   ),
                // );
              },
            ),
          );
        }).toList(),
        SizedBox(height: 20),
      ],
    );
  }

  // Function to copy competition information to clipboard
  void _copyCompetitionInfoToClipboard(BuildContext context) {
    String competitionInfo = '''
당신을 초대 합니다!!
대회 이름: ${competition.name}
대회 장소: ${competition.location}
시작 날짜 및 시간: ${DateFormat('yyyy-MM-dd h:mm a').format(competition.startDateTime)}
종료 날짜 및 시간: ${DateFormat('yyyy-MM-dd h:mm a').format(competition.endDateTime)}
대회 코드 : ${competition.code}
참가자 비밀번호: ${competition.participantPassword}
''';

    Clipboard.setData(ClipboardData(text: competitionInfo)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('대회 정보가 복사되었습니다!')),
      );
    });
  }
}
