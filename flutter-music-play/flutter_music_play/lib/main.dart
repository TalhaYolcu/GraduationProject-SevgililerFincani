
import 'dart:ffi';
import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_music_play/screens/ble_scan_screen.dart';
import 'package:flutter_music_play/screens/insideroomscreen.dart';
import 'package:flutter_music_play/screens/joinroomscreen.dart';
import 'package:flutter_music_play/util/btdata.dart';
import 'dart:io';
import 'util/song.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'util/constants.dart';

//notificationchannel
const AndroidNotificationChannel channel=AndroidNotificationChannel(
  'high_importance_channel', //id
  'High Importance Notifications', //title
  description: 'This channel is used for important notifications.',
  importance: Importance.high,
  playSound: true);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin=FlutterLocalNotificationsPlugin(

);


//initialize firebase when notification is received in background
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('A bg message just showed up : ${message.messageId}');
}



Future<void> main() async {
  
  WidgetsFlutterBinding.ensureInitialized();
  
  //init firebase
  await Firebase.initializeApp();

  //handle in background
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await flutterLocalNotificationsPlugin
    .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
    ?.createNotificationChannel(channel);


  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(

        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;


  

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String fillingstr='Empty';
  String updownstr='Down';
  String drinkstr='Not drinking';
  String roomText="";
  String userIdText="";
  final FirebaseDatabase referencedatabase = FirebaseDatabase.instanceFor(
    app: Firebase.app(),databaseURL: firebaseDatabaseUrl);
  
  
  



  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    roomtextController.dispose();
    userIdController.dispose();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? androidNotification=message.notification?.android;
      if(notification!=null && androidNotification!=null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              color: Colors.blue,
              playSound: true,
              icon: '@mipmap/ic_launcher'
            )
          )
        );
      }
     });
     FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) { 
      print('A new onMessageOpenedApp event was published');
      RemoteNotification? notification=message.notification;
      AndroidNotification? androidNotification=message.notification?.android;
      if(notification!=null && androidNotification!=null) {
        showDialog(context: context,
          builder: (_) {
          return AlertDialog(
            title: Text(notification.title??'Null'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Text(notification.body??'Null')
              ]),
            ),

          );
        });
      }
     });
  }

  final List<Song> songs = [
    Song(name: "Song 1", path: "assets/sounds/Song1.mp3"),
    Song(name: "Song 2", path: "assets/sounds/Song2.mp3"),
    Song(name: "Song 3", path: "assets/sounds/Song3.mp3"),
    Song(name: "Kumralim", path: "assets/sounds/Kumralim.mp3")
  ];

  TextEditingController roomtextController = TextEditingController();
  TextEditingController userIdController = TextEditingController();

  final player = AudioPlayer();
  @override
  Widget build(BuildContext context) {

    /*FirebaseMessaging.instance.getToken().then((value) {
      print("Firebase token is: ");
      print(value);
    });*/
    return Scaffold(appBar: AppBar(
          title: Text("Sevgililer Fincanı"),
        ),
        body: Container(
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment:MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 75,),
                  Image(image: AssetImage('assets/images/mugs.png'),width: 120,height: 120,),
                  SizedBox(height: 50,),
                  TextField(
                      controller: userIdController,
                      decoration: InputDecoration(labelText: "Username")
                  ),                 
                  SizedBox(height: 5,),
                   TextField(
                      controller: roomtextController,
                      decoration: InputDecoration(labelText: "A room number to join/create")
                  ),
                  SizedBox(height: 10,),              
                  ElevatedButton(
                    onPressed: roomEntered,
                    child: Text('Create/Join Room')
                  ),
                  SizedBox(height: 20,),
                  ElevatedButton(
                    onPressed: _scanBLEScreen,
                    child: Text('Scan BLE')
                  ),                  
                
                ],
               ),
            ),
          )
        ),
    );
    /*
    return Scaffold(
      appBar: AppBar(
          title: Text("Song Player"),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              buildButton(0),
              buildButton(1),
              buildButton(2),
              buildButton(3),
              ElevatedButton(onPressed:() => onStop(), child: Text('Stop')),
              SizedBox(height: 15,),
              ElevatedButton(onPressed: detectCurrentState, child: Text('Detect')),
              SizedBox(height: 15,),
              Text('Status: Filling:$fillingstr Up/Down: $updownstr, Drinking: $drinkstr')
            ],
          ),
        ),
    );*/
  }

  void roomEntered() {
    setState(() {
      roomText=roomtextController.text;
      userIdText=userIdController.text;
    });
    searchforRooms();
  }
  String _generatePassword() {
    // Generate a random 6-digit numeric password
    final random = Random();
    return random.nextInt(999999).toString().padLeft(6, '0');
  }  
  void searchforRooms() async {
    print("Room name:"+roomText);
    print("User Id:"+userIdText);

    try {
      final roomRef= referencedatabase.ref('rooms').child(roomText);
      final snapshot = await roomRef.once();
      final roomExists = snapshot.snapshot.value!=null;
      if(roomExists) {
        print('Room Exists');

        //check room is locked or not

        final snapshot = await roomRef.once();
        final roomData = snapshot.snapshot.value as Map<dynamic, dynamic>;
        if(roomData['isLocked']) {
          print('Room is locked');
          // Room is locked, show an error message and return to the previous screen
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('This room is full'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        else {
          print('Joining to the room ${roomText}');
          Navigator.push(context, MaterialPageRoute(builder: (context) => JoinRoomPasswordScreen(roomName: roomText,userId:userIdText)));

        }
      }  
      else {
        print('Room does not exists');
        // Room does not exist, create a new room and generate a password
        final password = _generatePassword();
        await roomRef.set({
          'password': password,
          'createdAt': DateTime.now().toUtc().toString(),
          'isLocked': false,
          'users': {
            // Add the first user who created the room
            '${userIdText}': {
              'name': '${userIdText}',
              'joinedAt': DateTime.now().toUtc().toString(),
              'Filling':'No',
              'Cup is up':'No',
              'Drinking':'No'
            },
          },
        });   
        Navigator.push(context, MaterialPageRoute(builder: (context) => RoomScreen(roomName: roomText, userId: userIdText)));
            
      }         
    }
    catch(ex) {
      print('EXX');
      print(ex);
    }

       
   
  }

  Widget buildButton(int index) {
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: ElevatedButton(
        onPressed: () => playSong(songs[index].path),
        child: Text(songs[index].name),
      ),
    );
  }

  void onStop() async {
    await player.pause();
  }

  void playSong(String path) async {

    /*if (!File(path).existsSync()) {
      print("Path does exists\n");
      return;
    }*/
    ByteData bytes = await rootBundle.load(path);
    Uint8List soundbytes=bytes.buffer.asUint8List(bytes.offsetInBytes,bytes.lengthInBytes);
  
    await player.playBytes(soundbytes);
      
  }  

  void detectCurrentState() {
    BluetoothData bluetoothData = new BluetoothData(incomingData: '0 1 1');
    bluetoothData.parseIncomingData();


    if(bluetoothData.filling) {
      setState(() {
        fillingstr='Not empty';
      });  
    }
    if(bluetoothData.updown) {
      setState(() {
        updownstr='Up';
      });
    }
    if(bluetoothData.drinkstate) {
      setState(() {
        drinkstr='Drinking';
      });
    }

    flutterLocalNotificationsPlugin.show(0, 'Testing $fillingstr', "How you doin", NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        importance: Importance.high,
        color: Colors.blue,
        playSound: true,
        icon: '@mipmap/ic_launcher' 
      )
    ));


  }
  void _scanBLEScreen() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => BTScanScreen()) );
  }
}
