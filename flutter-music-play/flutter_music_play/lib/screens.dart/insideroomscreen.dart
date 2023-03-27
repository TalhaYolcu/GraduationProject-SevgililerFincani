

import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter/material.dart';
import '../util/constants.dart';
import '../util/model/roomuser.dart';

class RoomScreen extends StatefulWidget {
  final String roomName;
  final String userId;

  RoomScreen({required this.roomName, required this.userId});

  @override
  _RoomScreenState createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  FirebaseDatabase referencedatabase = FirebaseDatabase.instanceFor(
    app: Firebase.app(),databaseURL: firebaseDatabaseUrl
  );

  late DatabaseReference roomRef;
  late StreamSubscription roomSubscription;

  @override
  void initState() {
    super.initState();
            sleep(Duration(seconds:2));

    try {
      roomRef = referencedatabase.ref('rooms').child(widget.roomName);


    // Listen for changes to the room data
      roomSubscription = roomRef.onValue.listen((event) async {
        final roomData = event.snapshot.value as Map<dynamic, dynamic>;
        print("Room data has been converted to map");
        if (roomData['isLocked']) {
          // Room is locked, show an error message and return to the previous screen
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('This room is full'),
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.pop(context);
        }
        else {
          DatabaseReference usersRef=roomRef.child('users').child('user2');
          final snapshot = await usersRef.once();
          final user2Exists = snapshot.snapshot.value!=null;
          if(user2Exists) {
            final usersData = roomData['users'] as Map<dynamic, dynamic>;
            print("Users data has been taken as map");
            final users = usersData.entries.map((entry) => RoomUser.fromMap(entry.value)).toList();
            print("Users list created");

            if (users.length < 2) {
              // Room is not full yet, add the current user to the room
              roomRef.child('users').child(widget.userId).set({
                'name': 'User ${users.length + 1}',
                'joinedAt': DateTime.now().toUtc().toString(),
              });
            } else {
              // Room is full, lock the room
              roomRef.update({'isLocked': true});
            }
          }

        }
      });
    }
    catch(ex) {
      print(ex);
    }


  }

  @override
  void dispose() {
    // Clean up the room subscription
    roomSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.roomName),
      ),
      body: StreamBuilder(
        stream: roomRef.child('users').onValue,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            
            final usersData = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
            print('usersData.entries: ${usersData.entries}');

            /*final users = usersData.entries.map((entry) => RoomUser.fromMap(entry.value as Map<String, dynamic>)).toList();

            if (users.isEmpty) {
              // Room is empty, remove the room
              roomRef.remove();
              Navigator.pop(context);
              return SizedBox.shrink();
            } else {
              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(users[index].name),
                    subtitle: Text(users[index].joinedAt.toString()),
                  );
                },
              );
            }
            */
            return SizedBox(height: 5,);
          } else {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }
}