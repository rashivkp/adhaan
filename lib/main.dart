// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(AdhaanApp());
}

class AdhaanApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _AdhaanAppState();
}

class _AdhaanAppState extends State<AdhaanApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Welcome to Flutter',
      theme: ThemeData(fontFamily: 'Roboto'),
      home: Scaffold(
          appBar: AppBar(
            title: const Text("Adhaan Vengara"),
          ),
          body: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/mosque.jpg"),
                  fit: BoxFit.cover,
                ),
              ),
              child: FutureBuilder<Adhaan?>(
                  future: DatabaseHelper.instance.getAdhaanTimings(),
                  builder:
                      (BuildContext context, AsyncSnapshot<Adhaan?> snapshot) {
                    if (!snapshot.hasData) {
                      return Center(child: Text("No data"));
                    }
                    var adhaan = snapshot.data!;
                    return Center(
                        child: ListView(
                      children: [
                        Row(
                          children: <Widget>[
                            Expanded(
                                child: Text(adhaan.date,
                                    style: const TextStyle(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18))),
                          ],
                        ),
                        Row(
                          children: <Widget>[
                            Padding(padding: EdgeInsets.all(40.0)),
                            Expanded(
                                child: Text('Subh',
                                    textAlign: TextAlign.left,
                                    style: const TextStyle(fontSize: 18))),
                            Expanded(
                                child: Text(adhaan.subh,
                                    style: const TextStyle(fontSize: 18))),
                          ],
                        ),
                        Row(
                          children: <Widget>[
                            Padding(padding: EdgeInsets.all(40.0)),
                            Expanded(
                                child: Text('Zuhr',
                                    textAlign: TextAlign.left,
                                    style: const TextStyle(fontSize: 18))),
                            Expanded(
                                child: Text(adhaan.zuhr,
                                    style: const TextStyle(fontSize: 18))),
                          ],
                        ),
                        Row(
                          children: <Widget>[
                            Padding(padding: EdgeInsets.all(40.0)),
                            Expanded(
                                child: Text('Asr',
                                    textAlign: TextAlign.left,
                                    style: const TextStyle(fontSize: 18))),
                            Expanded(
                                child: Text(adhaan.asr,
                                    style: const TextStyle(fontSize: 18))),
                          ],
                        ),
                        Row(
                          children: <Widget>[
                            Padding(padding: EdgeInsets.all(40.0)),
                            Expanded(
                                child: Text('Magrib',
                                    textAlign: TextAlign.left,
                                    style: const TextStyle(fontSize: 18))),
                            Expanded(
                                child: Text(adhaan.magrib,
                                    style: const TextStyle(fontSize: 18))),
                          ],
                        ),
                        Row(
                          children: <Widget>[
                            Padding(padding: EdgeInsets.all(40.0)),
                            Expanded(
                                child: Text('Isha',
                                    textAlign: TextAlign.left,
                                    style: const TextStyle(fontSize: 18))),
                            Expanded(
                                child: Text(adhaan.isha,
                                    style: const TextStyle(fontSize: 18))),
                          ],
                        ),
                        Row(
                          children: <Widget>[
                            Padding(padding: EdgeInsets.all(40.0)),
                            Expanded(
                                child: Text('Sunrise',
                                    textAlign: TextAlign.left,
                                    style: const TextStyle(fontSize: 18, color: Colors.white70))),
                            Expanded(
                                child: Text(adhaan.dawn,
                                    style: const TextStyle(fontSize: 18))),
                          ],
                        ),
                      ],
                    ));
                  }))),
    );
  }
}

class Adhaan {
  final String date;
  final String subh;
  final String dawn;
  final String zuhr;
  final String asr;
  final String magrib;
  final String isha;

  Adhaan(
      {required this.date,
      required this.subh,
      required this.dawn,
      required this.zuhr,
      required this.asr,
      required this.magrib,
      required this.isha});

  factory Adhaan.fromMap(Map<String, dynamic> json) => new Adhaan(
        date: json['date'],
        subh: json['subh'],
        dawn: json['dawn'],
        zuhr: json['zuhr'],
        asr: json['asr'],
        magrib: json['magrib'],
        isha: json['isha'],
      );

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'subh': subh,
      'dawn': dawn,
      'zuhr': zuhr,
      'asr': asr,
      'magrib': magrib,
      'isha': isha,
    };
  }
}

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async => _database ??= await _initDatabase();

  Future<Database> _initDatabase() async {
    var databasesPath = await getDatabasesPath();
    var path = join(databasesPath, "adhaan.db");
    await copyDb(path);
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future copyDb(path) async {
    var exists = await databaseExists(path);
    // Only copy if the database doesn't exist
    if (exists) {
      return;
    }
    // Load database from asset and copy
    ByteData data = await rootBundle.load(join('assets', 'adhaan.db'));
    List<int> bytes =
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    await File(path).writeAsBytes(bytes, flush: true);
  }

  Future _onCreate(Database db, int version) async {
    var databasesPath = await getDatabasesPath();
    var path = join(databasesPath, "adhaan.db");
    await copyDb(path);
  }

  Future<Adhaan?> getAdhaanTimings() async {
    var currentDate = new DateTime.now();
    var day = currentDate.day.toString();
    var month = currentDate.month.toString().padLeft(2, "0");
    Database db = await instance.database;
    var adhaans =
        await db.query('adhaan', orderBy: 'date', where: 'date="$month-$day"');
    var adhaanList = [];
    if (adhaans.isNotEmpty) {
      adhaanList = adhaans.map((c) => Adhaan.fromMap(c)).toList();
    }
    if (adhaanList.isNotEmpty) {
      return adhaanList[0];
    }
    return null;
  }
}
