import 'package:cloud_firestore/cloud_firestore.dart';

class Competition {
  final String code;
  final String name;
  final String location;
  final String organizerPassword;
  final String participantPassword;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final int groupCount;

  Competition({
    required this.code,
    required this.name,
    required this.location,
    required this.organizerPassword,
    required this.participantPassword,
    required this.startDateTime,
    required this.endDateTime,
    required this.groupCount,
  });

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name': name,
      'location': location,
      'organizerPassword': organizerPassword,
      'participantPassword': participantPassword,
      'startDateTime': Timestamp.fromDate(startDateTime),
      'endDateTime': Timestamp.fromDate(endDateTime),
      'groupCount': groupCount
    };
  }

  static Competition fromMap(Map<String, dynamic> map) {
    return Competition(
      code: map['code'],
      name: map['name'],
      location: map['location'],
      organizerPassword: map['organizerPassword'],
      participantPassword: map['participantPassword'],
      startDateTime: (map['startDateTime'] as Timestamp).toDate(),
      endDateTime: (map['endDateTime'] as Timestamp).toDate(),
      groupCount: map['groupCount'],
    );
  }
}

class LeagueStatistics {
  final String id; // Unique identifier for Firestore document
  final int group;
  final Map<String, int> consecutiveGamesPerTeam;
  final int totalConsecutiveMatches;
  final int totalMatches;
  final int totalRounds;
  final int totalEmptySlots;

  LeagueStatistics({
    required this.id,
    required this.group,
    required this.consecutiveGamesPerTeam,
    required this.totalConsecutiveMatches,
    required this.totalMatches,
    required this.totalRounds,
    required this.totalEmptySlots,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'group': group,
      'consecutiveGamesPerTeam': consecutiveGamesPerTeam,
      'totalConsecutiveMatches': totalConsecutiveMatches,
      'totalMatches': totalMatches,
      'totalRounds': totalRounds,
      'totalEmptySlots': totalEmptySlots,
    };
  }

  static LeagueStatistics fromMap(Map<String, dynamic> map) {
    return LeagueStatistics(
      id: map['id'],
      group: map['group'],
      consecutiveGamesPerTeam:
          Map<String, int>.from(map['consecutiveGamesPerTeam']),
      totalConsecutiveMatches: map['totalConsecutiveMatches'],
      totalMatches: map['totalMatches'],
      totalRounds: map['totalRounds'],
      totalEmptySlots: map['totalEmptySlots'],
    );
  }
}

class LeagueMatch {
  final String matchId;
  final String team1;
  final String team2;
  final int group;
  final int round;
  final String time;
  final String consecutiveTeam;
  final String stadium;
  final bool isLunchBreak;

  LeagueMatch({
    required this.matchId,
    required this.team1,
    required this.team2,
    required this.group,
    required this.round,
    required this.time,
    required this.consecutiveTeam,
    required this.stadium,
    this.isLunchBreak = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'matchId': matchId,
      'team1': team1,
      'team2': team2,
      'group': group,
      'round': round,
      'time': time,
      'consecutiveTeam': consecutiveTeam,
      'stadium': stadium,
      'isLunchBreak': isLunchBreak,
    };
  }
}
