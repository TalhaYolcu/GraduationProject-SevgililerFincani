import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_music_play/screens.dart/insideroomscreen.dart';
import '../util/constants.dart';
import '../util/model/roomuser.dart';

class JoinRoomPasswordScreen extends StatefulWidget {
  final String roomName;

  JoinRoomPasswordScreen({required this.roomName});

  @override
  _JoinRoomPasswordScreenState createState() => _JoinRoomPasswordScreenState();
}

class _JoinRoomPasswordScreenState extends State<JoinRoomPasswordScreen> {
  final passwordController = TextEditingController();
  FirebaseDatabase referencedatabase=FirebaseDatabase.instanceFor(
    app: Firebase.app(),databaseURL: firebaseDatabaseUrl);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enter Room Password'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Room: ${widget.roomName}'),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: 'Room Password',
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () async {
                final roomName = widget.roomName;
                final password = passwordController.text;
                final roomRef = referencedatabase.ref('rooms').child(roomName);
                final snapshot = await roomRef.once();
                final roomData = snapshot.snapshot.value as Map<dynamic, dynamic>;

                if (roomData['password'] == password) {
                  // Password is correct, join the room
                  // ...

                  var user2Ref=roomRef.child('users').child('user2');
                  

                  final snapshot = await user2Ref.once();

                  final user2Exists = snapshot.snapshot.value!=null;
                  if(!user2Exists)  {
                    final user2 = RoomUser(name: 'User 2', joinedAt: DateTime.now());
                    await roomRef.child('users').child('user2').set(user2.toMap());
                  }

                  Navigator.push(context, MaterialPageRoute(builder: (context) => RoomScreen(roomName: roomName, userId: 'user2')));

                } else {
                  // Password is incorrect, show an error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Incorrect password'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: Text('Join Room'),
            ),
          ],
        ),
      ),
    );
  }
}