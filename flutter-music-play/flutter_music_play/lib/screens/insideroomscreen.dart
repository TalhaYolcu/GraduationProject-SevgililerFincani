

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import '../util/constants.dart';
import '../util/model/roomuser.dart';
import 'package:flutter/widgets.dart';

class MyScreenObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // The app is now in the foreground (screen is visible).
      // Add your logic here.
    } else if (state == AppLifecycleState.inactive) {
      // The app is still active but not in the foreground (e.g., a phone call).
      // Add your logic here.
    } else if (state == AppLifecycleState.paused) {
      // The app is in the background (screen is not visible).
      // Add your logic here.
    } else if (state == AppLifecycleState.detached) {
      // The app is being terminated by the system.
      // Add your logic here.
    }
  }
}




class _Message {
  int whom;
  String text;

  _Message(this.whom, this.text);
}

class RoomScreen extends StatefulWidget {
  final String roomName;
  final String userId;
  BluetoothDevice server;

  RoomScreen({required this.roomName, required this.userId,required this.server});

  @override
  _RoomScreenState createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  FirebaseDatabase referencedatabase = FirebaseDatabase.instanceFor(
    app: Firebase.app(),databaseURL: firebaseDatabaseUrl
  );

  late DatabaseReference roomRef;
  late StreamSubscription roomSubscription;
  static final clientID = 0;
  BluetoothConnection? connection;

  List<_Message> messages = List<_Message>.empty(growable: true);
  String _messageBuffer = '';

  final TextEditingController textEditingController = new TextEditingController();

  bool isConnecting = true;
  bool get isConnected => (connection?.isConnected ?? false);

  bool isDisconnecting = false;

  String _lastMessage=' ';
  int receivedDistance=-1;
  bool firstMessageSent=false;




  @override
  void initState() {
    super.initState();
    BluetoothConnection.toAddress(widget.server.address).then((_connection) {
      print('Connected to the device');
      connection = _connection;
      setState(() {
        isConnecting = false;
        isDisconnecting = false;
      });
    
      connection!.input!.listen(_onDataReceived).onDone(() {
        // Example: Detect which side closed the connection
        // There should be `isDisconnecting` flag to show are we are (locally)
        // in middle of disconnecting process, should be set before calling
        // `dispose`, `finish` or `close`, which all causes to disconnect.
        // If we except the disconnection, `onDone` should be fired as result.
        // If we didn't except this (no flag set), it means closing by remote.
        if (isDisconnecting) {
          print('Disconnecting locally!');
        } else {
          print('Disconnected remotely!');
        }
        if (this.mounted) {
          setState(() {});
        }
      });
    }).catchError((error) {
      print('Cannot connect, exception occured');
      print(error);
    });


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
        // Avoid memory leak (`setState` after dispose) and disconnect
    if (isConnected) {
      isDisconnecting = true;
      connection?.dispose();
      connection = null;
    }
    textEditingController.dispose();
    messages.clear();
    roomRef.remove();
    
    super.dispose();
  }
  
  Future<bool> _onWillPop() async {
       return (await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Are you sure?'),
        content: const Text('Do you want to exit?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: sendBeforeExit ,
            child: const Text('Yes'),
          ),
        ],
      ),
    )) ?? false; 
  }

  @override
  Widget build(BuildContext context) {
      final serverName = widget.server.name ?? "Unknown";

      if(!firstMessageSent && isConnected) {
        try {
          _sendMessage('+');

          firstMessageSent=true;
        }
        catch(ex) {
          print(ex.toString());
        }
      }


    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
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
                        ElevatedButton(onPressed: seeRoomPassword, child: const Text("See Room Password")),
                      ],
                    ),                  
                    const SizedBox(height: 16),
                    Text('You are ${widget.userId}'), // display the current user's ID
                    const SizedBox(height: 16),
                    Text('Incoming data: {$receivedDistance}'),
                    const SizedBox(height: 3,),
                    Expanded(
                      child: ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text("User "+users[index].name+" 's info:"),
                          subtitle: Column(
                            children: [
                              const SizedBox(height: 2,),
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
      ),
    );
  }
  void sendBeforeExit() async {
    print("- Message is sending...");
    _sendMessage('-');
    print("- Message has been sent");
    Navigator.of(context).pop(true);
  }
  void _onDataReceived(Uint8List data) {
    print("Ondata received");
    // Allocate buffer for parsed data
    int backspacesCounter = 0;
    data.forEach((byte) {
      if (byte == 8 || byte == 127) {
        backspacesCounter++;
      }
    });
    Uint8List buffer = Uint8List(data.length - backspacesCounter);
    int bufferIndex = buffer.length;

    // Apply backspace control character
    backspacesCounter = 0;
    for (int i = data.length - 1; i >= 0; i--) {
      if (data[i] == 8 || data[i] == 127) {
        backspacesCounter++;
      } else {
        if (backspacesCounter > 0) {
          backspacesCounter--;
        } else {
          buffer[--bufferIndex] = data[i];
        }
      }
    }

    // Create message if there is new line character
    String dataString = String.fromCharCodes(buffer);
    int index = buffer.indexOf(13);
    if (~index != 0) {
      setState(() {
        messages.add(
          _Message(
            1,
            backspacesCounter > 0
                ? _messageBuffer.substring(
                    0, _messageBuffer.length - backspacesCounter)
                : _messageBuffer + dataString.substring(0, index),
          ),
        );
        _messageBuffer = dataString.substring(index);
      });
    } else {
      _messageBuffer = (backspacesCounter > 0
          ? _messageBuffer.substring(
              0, _messageBuffer.length - backspacesCounter)
          : _messageBuffer + dataString);
    }
    print("Last message : ");
    try {
      print(messages.last.text);
      _lastMessage=messages.last.text;
    }
    catch(ex) {
      print(ex.toString());
    }


    setState(() {
    try {
        if(_lastMessage.trim()=="UP") {
          if(receivedDistance==0) {
            makeCupIsUpStateOn();
          }
          receivedDistance=1;
          
        }
        else if (_lastMessage.trim()=="DOWN" && receivedDistance==1) {
          if(receivedDistance==1) {
            makeCupIsUpStateOff();
            
          }
          receivedDistance=0;
          
        }
    }
    catch (Ex) {
      print('Couldnt parse\n');
    }      
    });

    setState(() {

    });
  }
  void seeRoomPassword() async {
    roomRef = referencedatabase.ref('rooms').child(widget.roomName);

    final snapshot = await roomRef.once();
    final roomData = snapshot.snapshot.value as Map<dynamic, dynamic>;
    String roomPassword = roomData['password'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Room Password'),
        content:  SafeArea(
          child: Row(
            children: [
              Text('Room Pasword is : $roomPassword',style: const TextStyle(fontSize: 15),),
              IconButton(icon: const Icon(Icons.copy),onPressed:() {
                Clipboard.setData(ClipboardData(text:roomPassword));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Text copied to clipboard')),
                );              
              } ,iconSize:20),
            
            ],
          ),
        ) ,
        actions: <Widget>[
      TextButton(
        onPressed: () {
          Navigator.of(context).pop(); // Close the dialog
        },
        child: const Text('OK'),
      ),
        ],
      ),);
  }

  void _sendMessage(String text) async {
    print("Message send start");
    text = text.trim();
    textEditingController.clear();

    if (text.length > 0) {
      try {
        connection!.output.add(ascii.encode('+'));
        //connection!.output.add(Uint8List.fromList(utf8.encode(text + "\r\n")));
        await connection!.output.allSent;

      } catch (e) {
        // Ignore error, but notify state
        setState(() {});
      }
    }
    print("Message has been send");

  }
  void makeFillingStateOn() async {
    try {
      var FilingRef=referencedatabase.ref('rooms').child(widget.roomName).child("users").child(widget.userId).child("Filling");
      final snapshot = await FilingRef.once();
      String newValue = "Yes";
      FilingRef.set(newValue);
    }
    catch(ex) {
      print(ex);
    }
  }
  void makeCupIsUpStateOn() async {
    try {
      var CupIsUp=referencedatabase.ref('rooms').child(widget.roomName).child("users").child(widget.userId).child("Cup is up");
      final snapshot = await CupIsUp.once();
      String newValue = "Yes";
      CupIsUp.set(newValue);
    }
    catch(ex) {
      print(ex);
    } 
  }
  void makeCupIsUpStateOff() async {
    try {
      var CupIsUp=referencedatabase.ref('rooms').child(widget.roomName).child("users").child(widget.userId).child("Cup is up");
      final snapshot = await CupIsUp.once();
      String newValue = "No";
      CupIsUp.set(newValue);
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