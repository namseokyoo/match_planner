// match_card.dart
import 'package:flutter/material.dart';

class MatchCard extends StatelessWidget {
  final String? team1; // team2 can be null for a bye
  final String? team2; // team2 can be null for a bye
  final int? team1Score;
  final int? team2Score;
  final String winner;
  final String matchNumber;
  final VoidCallback? onTap; // onTap can be null for a bye

  MatchCard({
    required this.team1,
    required this.team2,
    this.team1Score,
    this.team2Score,
    required this.winner,
    required this.matchNumber,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // Only tappable if onTap is not null
      child: Container(
        height: 100,
        width: 200,
        margin: const EdgeInsets.symmetric(vertical: 10.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  matchNumber,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (team2 == null)
                    Text(
                      '$team1',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    )
                  else if (team1 == null)
                    Text(
                      '$team2',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$team1: ${team1Score ?? 0}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: winner == team1
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: winner.isNotEmpty && winner != team1
                                ? Colors.grey
                                : Colors.black,
                          ),
                        ),
                        Divider(),
                        Text(
                          '$team2: ${team2Score ?? 0}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: winner == team2
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: winner.isNotEmpty && winner != team2
                                ? Colors.grey
                                : Colors.black,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
