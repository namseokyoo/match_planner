// lib/screens/main_screen.dart
import 'package:flutter/material.dart';
import 'package:matches_table/screens/competition/competition_main_screen.dart';
import 'package:matches_table/screens/league_screen/league_generator_screen.dart';
import 'package:matches_table/screens/tournament_screen/tournament_generator_screen.dart';

class MainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 5,
        title: const Text('MatchHub',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LeagueGeneratorScreen(),
                  ),
                );
              },
              child: Text('리그 대진표 생성'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TournamentGeneratorScreen(),
                  ),
                );
              },
              child: Text('토너먼트 대진표 생성'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CompetitionMainScreen(),
                  ),
                );
              },
              child: Text('대회 개최/참가'),
            ),
          ],
        ),
      ),
    );
  }
}
