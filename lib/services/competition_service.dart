import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/competition.dart';

class CompetitionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveCompetitionToDB({
    required String competitionCode,
    required String competitionName,
    required String location,
    required String organizerPassword,
    required String participantPassword,
    required DateTime startDateTime,
    required DateTime endDateTime,
    required List<Map<String, dynamic>> leagueResults, // 평면화된 리스트
    required int groupCount,
  }) async {
    // 1. 대회 정보 저장
    Competition competition = Competition(
      code: competitionCode,
      name: competitionName,
      location: location,
      organizerPassword: organizerPassword,
      participantPassword: participantPassword,
      startDateTime: startDateTime,
      endDateTime: endDateTime,
      groupCount: groupCount,
    );

    await _firestore
        .collection('competitions')
        .doc(competitionCode)
        .set(competition.toMap());
  }

  Future<void> saveStatistics(
      String competitionCode, List<LeagueStatistics> statistics) async {
    for (var stat in statistics) {
      await _firestore
          .collection('competitions')
          .doc(competitionCode)
          .collection('statistics')
          .doc(stat.id)
          .set(stat.toMap());
    }
  }

  Future<void> saveMatches(
      String competitionCode, List<LeagueMatch> matches) async {
    // Group matches by group ID
    Map<int, List<LeagueMatch>> matchesByGroup = {};

    for (var match in matches) {
      if (!matchesByGroup.containsKey(match.group)) {
        matchesByGroup[match.group] = [];
      }
      matchesByGroup[match.group]!.add(match);
    }

    // Save matches for each group
    for (var group in matchesByGroup.keys) {
      var groupMatches = matchesByGroup[group];

      if (groupMatches != null) {
        for (var match in groupMatches) {
          await _firestore
              .collection('competitions')
              .doc(competitionCode)
              .collection('bracket')
              .doc(match.matchId)
              .set(match.toMap());
        }
      }
    }
  }
}
