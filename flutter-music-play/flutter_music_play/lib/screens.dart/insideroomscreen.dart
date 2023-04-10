

import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
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

    try {
      roomRef = referencedatabase.ref('rooms').child(widget.roomName);


      // Listen for changes to the room data
      roomSubscription = roomRef.onValue.listen((event) async {
        final roomData = event.snapshot.value as Map<dynamic, dynamic>;
        print("Room data has been converted to map");


        final usersData = roomData['users'] as Map<dynamic,dynamic>;
        final users = usersData.entries.map((entry) => RoomUser.fromMap(entry.value)).toList();

        if (users.length==2) {
          // Room is full, lock the room
          roomRef.update({'isLocked': true});
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

            final users = usersData.entries.map((entry) => RoomUser.fromMap(entry.value)).toList();

            if (users.isEmpty) {
              // Room is empty, remove the room
              roomRef.remove();
              Navigator.pop(context);
              return SizedBox.shrink();
            }
            else {
              return Column(
                children: [
                  SizedBox(height: 20,),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      ElevatedButton(onPressed: onFillingStateChanged, child: const Text('Change Fillng State')),
                      ElevatedButton(onPressed: onCupIsUpStateChanged, child: const Text('Change Cup is Up State')),                    
                      ElevatedButton(onPressed: onDrinkStateChanged, child: const Text('Change Drink State')),
                    ],
                  ),                  
                  const SizedBox(height: 16),
                  Text('You are ${widget.userId}'), // display the current user's ID
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(users[index].name),
                        subtitle: Column(
                          children: [
                            Text("Joined at:${users[index].joinedAt}"),
                            const SizedBox(height: 3,),
                            Text("Filling:${users[index].filling}"),
                            const SizedBox(height: 3,),
                            Text("Cup is up:${users[index].cup_is_up}"),
                            const SizedBox(height: 3,),
                            Text("Drinking:${users[index].drinking}"),
                            const SizedBox(height: 3,),

                          ],
                        ),
                        
                      );
                    },
                  ) 
                  ),

                ],
              ) ;
            }
            
            //return SizedBox(height: 5,);
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }
  void onDrinkStateChanged() async {
    try {
      var DrinkRef=referencedatabase.ref('rooms').child(widget.roomName).child("users").child(widget.userId).child("Drinking");
      final snapshot = await DrinkRef.once();
      String newValue = snapshot.snapshot.value.toString()=="No" ? "Yes" : "No";
      DrinkRef.set(newValue);
    }
    catch(ex) {
      print(ex);
    }
  }
  void onFillingStateChanged() async {
    try {
      var FilingRef=referencedatabase.ref('rooms').child(widget.roomName).child("users").child(widget.userId).child("Filling");
      final snapshot = await FilingRef.once();
      String newValue = snapshot.snapshot.value.toString()=="No" ? "Yes" : "No";
      FilingRef.set(newValue);
    }
    catch(ex) {
      print(ex);
    }

  }
  void onCupIsUpStateChanged() async {
    try {
      var CupIsUp=referencedatabase.ref('rooms').child(widget.roomName).child("users").child(widget.userId).child("Cup is up");
      final snapshot = await CupIsUp.once();
      String newValue = snapshot.snapshot.value.toString()=="No" ? "Yes" : "No";
      CupIsUp.set(newValue);
    }
    catch(ex) {
      print(ex);
    }    

  }
}