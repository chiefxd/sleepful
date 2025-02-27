import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sleepful/providers/user_data_provider.dart';
import 'package:sleepful/view/Pages/Profile/edit_profile.dart';

import '../home_page.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  String fullName = '';
  final UserDataProvider _userDataProvider = UserDataProvider();
  String? _profilePicturePath;

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        _fetchUserData();
      }
    });
  }

  Future<void> _fetchUserData() async {
    await _fetchFullName();
    await _loadSavedImagePath();
  }

  Future<void> _fetchFullName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        fullName = await _userDataProvider.getFullName(user.uid);
        setState(() {}); // Update new name
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching user name: $e');
      }
    }
  }

  Future<void> _loadSavedImagePath() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = '${directory.path}/profile_image.jpg';

      if (await File(imagePath).exists()) {
        setState(() {
          _profilePicturePath = imagePath;
        });
      } else {
        setState(() {
          _profilePicturePath = null;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading profile picture: $e');
      }
    }
  }

  // Function to fetch total sleep time (all-time)
  Future<double> _fetchTotalSleepTime() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return 0.0;
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .collection('Successful Plans')
        .get();

    double totalSleepTime = 0.0;
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final startTime = data['startTime'] as String;
      final endTime = data['endTime'] as String;
      final successfulDate = (data['successfulDate'] as Timestamp).toDate();

      final startDateTime = _parseTime(successfulDate, startTime);
      final endDateTime = _parseTime(successfulDate, endTime);
      final duration = endDateTime.difference(startDateTime).inMinutes / 60.0;

      totalSleepTime += duration;
    }

    return totalSleepTime;
  }

  // Function to parse time
  DateTime _parseTime(DateTime date, String time) {
    int hour = int.parse(time.split(':')[0]);
    int minute = int.parse(time.split(':')[1].split(' ')[0]);
    if (time.contains('PM') && hour != 12) hour += 12;
    if (time.contains('AM') && hour == 12) hour = 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  Widget _buildIconRow(IconData icon, String text, double fontSize,
      {required BuildContext context, required String routeName}) {
    return GestureDetector(
      onTap: () {
        if (text == 'Log Out') {
          // Show confirmation dialog
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                backgroundColor: Theme.of(context).colorScheme.onSecondary,
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      'Are you sure you want to log out?',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.tertiary,
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                actions: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(30.0),
                            border: Border.all(
                              color: const Color(0xFFB4A9D6),
                              width: 2.0,
                            ),
                          ),
                          child: TextButton(
                            onPressed: () {
                              Navigator.pop(
                                context,
                              );
                            },
                            style: TextButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.0),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.tertiary,
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const VerticalDivider(color: Colors.white),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                          child: TextButton(
                            onPressed: () {
                              // Sign out the user
                              FirebaseAuth.instance.signOut().then((value) {
                                Navigator.pushNamedAndRemoveUntil(
                                    context, '/signIn', (route) => false);
                              });
                            },
                            child: const Text(
                              'Log Out',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        } else if (text == 'Edit Profile') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditProfile(
                onProfilePictureUpdated: () {
                  _fetchUserData(); // Reload user data when profile is updated
                },
                onNameUpdated: (updatedName) {
                  setState(() {
                    fullName = updatedName; // Update the name
                  });
                },
              ),
            ),
          );
        } else {
          Navigator.pushNamed(context, routeName);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 30.0),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            SizedBox(width: 10),
            Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Montserrat',
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double titleFontSize = screenWidth * 0.06;
    double subtitleFontSize = screenWidth * 0.04;

    return Scaffold(
      // Section 1: Title and Back Button
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const HomePage()));
          },
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Image.asset(
              'assets/images/buttonBack.png',
              width: 48,
              height: 48,
            ),
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.only(left: 0),
          child: Text(
            'Profile',
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
              fontFamily: 'Montserrat',
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),

      // Section 2: Profile Contents
      body: Stack(
        children: [
          Column(
            children: <Widget>[
              SizedBox(height: 25),

              // Profile Pic
              CircleAvatar(
                radius: 75,
                backgroundImage: _profilePicturePath != null
                    ? FileImage(File(_profilePicturePath!))
                    : const AssetImage('assets/images/Contoh 1.png')
                        as ImageProvider,
              ),

              SizedBox(height: 15),

              // User's Name
              Text(
                '$fullName',
                style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Montserrat',
                    color: Theme.of(context).colorScheme.primary),
              ),

              SizedBox(height: 0),

              // Sleep Time
              FutureBuilder<double>(
                future: _fetchTotalSleepTime(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }
                  if (snapshot.hasError) {
                    return Text('Error fetching sleep time');
                  }

                  final totalSleepTime = snapshot.data ?? 0.0;

                  return Text(
                    'Your total sleep time is ${totalSleepTime.toStringAsFixed(0)} hours!',
                    style: TextStyle(
                        fontSize: subtitleFontSize,
                        fontFamily: 'Montserrat',
                        color: Theme.of(context).colorScheme.primary),
                  );
                },
              ),

              SizedBox(height: 20),

              // 5 rows
              Column(
                children: [
                  _buildIconRow(Icons.edit, 'Edit Profile', subtitleFontSize,
                      context: context, routeName: '/editProfile'),
                  _buildIconRow(Icons.lock, 'Change Password', subtitleFontSize,
                      context: context, routeName: '/change_password'),
                  _buildIconRow(Icons.palette, 'Change Theme', subtitleFontSize,
                      context: context, routeName: '/change_theme'),
                  _buildIconRow(Icons.info, 'About Us', subtitleFontSize,
                      context: context, routeName: '/about_us'),
                  _buildIconRow(Icons.logout, 'Log Out', subtitleFontSize,
                      context: context, routeName: '/logout'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
