// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(AdhaanApp());
}

class AdhaanApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Adhaan Vengara',
        theme: ThemeData(fontFamily: 'Roboto'),
        home: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.blueGrey,
            title: const Text("Adhaan Vengara"),
          ),
          body: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/mosque.jpg"),
                fit: BoxFit.cover,
              ),
            ),
            child: HomePage(),
          ),
        ));
  }
}

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _AdhaanAppState();
}

class _AdhaanAppState extends State<HomePage> {
  static const String dateFormat = 'd MMM y, EEEE';
  DateTime? date = DateTime.now();
  Adhaan? adhaan;

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        width: double.infinity,
        child: FutureBuilder<Adhaan?>(
            future: DatabaseHelper.instance.getAdhaanTimings(date!),
            builder: (BuildContext context, AsyncSnapshot<Adhaan?> snapshot) {
              return getAdhaanFutureBuilder(context, snapshot);
            }));
  }

  adhaanText(String text) {
    return Text(text, style: TextStyle(color: Colors.white70, fontSize: 16));
  }

  adhanEntry(String title, String time) {
    return Padding(
        padding: EdgeInsets.all(5.0),
        child: ListTile(
          tileColor: Colors.white30,
          leading: Icon(Icons.access_time, color: Colors.white54),
          title: adhaanText(title),
          subtitle: adhaanText(time),
        ));
  }

  Widget adhaanDatePicker(BuildContext context) {
    return TextButton(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.all(16.0),
          primary: Colors.white70,
          textStyle: const TextStyle(fontSize: 20),
        ),
        onPressed: () async {
          var newDate = await showDatePicker(
              context: context,
              initialDate: date!,
              firstDate: DateTime(2021),
              lastDate: DateTime(2022));
          if (newDate != null) {
            setState(() {
              date = newDate;
            });
          }
        },
        child: Row(children: [
          Icon(Icons.today, color: Colors.white70),
          Text("  " + DateFormat(dateFormat).format(date!).toString()),
        ]));
  }

  Widget getAdhaanFutureBuilder(
      BuildContext context, AsyncSnapshot<Adhaan?> snapshot) {
    if (!snapshot.hasData) {
      return adhaanDatePicker(context);
    }

    adhaan = snapshot.data!;
    // return Text(adhaan.zuhr);
    return SingleChildScrollView(
        child: Column(
      children: <Widget>[
        adhaanDatePicker(context),
        Card(
          clipBehavior: Clip.hardEdge,
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              adhanEntry("Subh", "${adhaan!.subh} AM"),
              adhanEntry("Fajr", "${adhaan!.dawn} AM"),
              adhanEntry("Dhuhr", "${adhaan!.zuhr} PM"),
              adhanEntry("Asr", "${adhaan!.asr} PM"),
              adhanEntry("Maghrib", "${adhaan!.magrib} PM"),
              adhanEntry("Isha", "${adhaan!.isha} PM"),
            ],
          ),
        ),
      ],
    ));
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

  Future<Adhaan?> getAdhaanTimings(DateTime date) async {
    var day = date.day.toString();
    var month = date.month.toString().padLeft(2, "0");
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
