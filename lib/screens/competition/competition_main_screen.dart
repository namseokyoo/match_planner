import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'competition_create_screen.dart';
import 'competition_detailsview_screen.dart';

class CompetitionMainScreen extends StatelessWidget {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _passwordController =
      TextEditingController(); // New password controller
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // Firestore instance

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('대회 개회 / 참여'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: '기존 대회에 참여하려면, 대회코드 8자리를 입력하세요',
                border: OutlineInputBorder(),
              ),
              maxLength: 8, // Set max length to 8 digits
            ),
            SizedBox(height: 10), // Add space between fields
            TextField(
              controller: _passwordController,
              keyboardType: TextInputType.text,
              obscureText: true, // Hide password input
              decoration: InputDecoration(
                labelText: '비밀번호를 입력하세요',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                String enteredCode = _codeController.text;
                String enteredPassword = _passwordController.text;

                if (enteredCode.length == 8) {
                  // Check if the competition exists in Firestore
                  DocumentSnapshot competition = await _firestore
                      .collection('competitions')
                      .doc(enteredCode)
                      .get();

                  if (competition.exists) {
                    Map<String, dynamic> competitionData =
                        competition.data() as Map<String, dynamic>;
                    String storedOrganizerPassword =
                        competitionData['organizerPassword'];
                    String storedParticipantPassword =
                        competitionData['participantPassword'];

                    if (enteredPassword == storedOrganizerPassword ||
                        enteredPassword == storedParticipantPassword) {
                      _clearTextFields(); // Clear the text fields
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => CompetitionDetailsviewScreen(
                            contestData: competitionData,
                            canEdit: enteredPassword == storedOrganizerPassword,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('비밀번호가 일치하지 않습니다.')),
                      );
                      _clearTextFields(); // Clear the text fields
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('해당 코드의 대회를 찾을 수 없습니다.')),
                    );
                    _clearTextFields(); // Clear the text fields
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('대회코드 8자리를 입력해주세요.')),
                  );
                  _clearTextFields(); // Clear the text fields
                }
              },
              child: Text('기존 대회 참여하기'),
            ),

            SizedBox(height: 20), // Add space between buttons
            ElevatedButton(
              onPressed: () {
                // Generate an 8-digit random contest code
                String generatedCode = _generateRandomNumericCode(8);

                // Navigate to CreateMatchPage with the generated code
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        CompetitionCreateScreen(matchCode: generatedCode),
                  ),
                );
              },
              child: Text('새로운 대회 개최하기'),
            ),
          ],
        ),
      ),
    );
  }

  // Function to generate a random 8-digit numeric code
  String _generateRandomNumericCode(int length) {
    Random random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => '0'.codeUnitAt(0) + random.nextInt(10), // Generate numbers only
      ),
    );
  }

  void _clearTextFields() {
    _codeController.clear();
    _passwordController.clear();
  }
}
