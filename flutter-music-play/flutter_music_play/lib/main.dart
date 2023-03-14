
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'util/song.dart';

void main() {
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
  final List<Song> songs = [
    Song(name: "Song 1", path: "assets/sounds/Song1.mp3"),
    Song(name: "Song 2", path: "assets/sounds/Song2.mp3"),
    Song(name: "Song 3", path: "assets/sounds/Song3.mp3"),
    Song(name: "Kumralim", path: "assets/sounds/Kumralim.mp3")
  ];
    final player = AudioPlayer();
  @override
  Widget build(BuildContext context) {

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
              ElevatedButton(onPressed:() => onStop(), child: Text('Stop'))
            ],
          ),
        ),
    );
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
}
