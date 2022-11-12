import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:restart_app/restart_app.dart';

import 'package:jiffy/jiffy.dart';
import 'package:pedometer/pedometer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DailyStepsPage extends StatefulWidget {
  @override
  _DailyStepsPageState createState() => _DailyStepsPageState();
}

class _DailyStepsPageState extends State<DailyStepsPage> {
  //Pedometer _pedometer = new Pedometer();
  Stream<StepCount> _subscription = Pedometer.stepCountStream;
  //Box<int> stepsBox = Hive.box('steps');
  var prefs;
  int todaySteps = 0;
  int yesterdaySteps = 0;
  int thisWeeksSteps = 0;
  String todayDayNo = (Jiffy(DateTime.now()).year).toString() + ((Jiffy(DateTime.now()).month).toString()).padLeft(2,'0') + ((Jiffy(DateTime.now()).date).toString()).padLeft(2,'0');
  String _status = 'stopped';
  String savedStepsCountKey = '999999';
  String lastDaySavedKey = '888888';
  String bufferKey = '777777';
  int tempSavedSteps = 0;
  bool phoneRestarted = false;

  final Color carbonBlack = Color(0xff1a1a1a);

  @override
  void initState() {
    super.initState();
    //if (_subscription == null) {
      startListening();
   // }
    Stream<PedestrianStatus> _pedestrianStatusStream = Pedometer.pedestrianStatusStream;
    _pedestrianStatusStream
        .listen(onPedestrianStatusChanged)
        .onError(onPedestrianStatusError);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('LOCOPED'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                "This Week's Steps:",
                style: TextStyle(fontSize: 30),
              ),
              Text(
                  (thisWeeksSteps + todaySteps).toString(),
                style: TextStyle(fontSize: 60),
              ),
              Divider(
                height: 100,
                thickness: 0,
                color: Colors.white,
              ),
              Text(
                "Today's Steps:",
                style: TextStyle(fontSize: 30),
              ),
              Text(
                todaySteps.toString(),
                style: TextStyle(fontSize: 60),
              ),
              Divider(
                height: 100,
                thickness: 0,
                color: Colors.white,
              ),
              Text(
                'Pedestrian status:',
                style: TextStyle(fontSize: 30),
              ),
              Icon(
                _status == 'walking'
                    ? Icons.directions_walk
                    : _status == 'stopped'
                    ? Icons.accessibility_new
                    : Icons.error,
                size: 100,
              ),
              Center(
                child: Text(
                  _status,
                  style: _status == 'walking' || _status == 'stopped'
                      ? TextStyle(fontSize: 30)
                      : TextStyle(fontSize: 20, color: Colors.red),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }

  Widget gradientShaderMask({required Widget child}) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: [
          Colors.orange,
          Colors.deepOrange.shade900,
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
      child: child,
    );
  }

  void startListening() async {
   // _pedometer = Pedometer();
    prefs = await SharedPreferences.getInstance();
    _subscription.listen(
      getTodaySteps,
      onError: _onError,
      onDone: _onDone,
      cancelOnError: true,
    );

  }

  void _onDone() => print("Finished pedometer tracking");
  void _onError(error) => print("Flutter Pedometer Error: $error");

  void getTodaySteps(StepCount value) async {
    print(value);//Just printing the latest step count data (since last restart of the device)
    //await prefs.setInt(((Jiffy(DateTime.now()).subtract(days: 1)).year).toString() + ((Jiffy(DateTime.now()).subtract(days: 1)).dayOfYear).toString(),prefs.getInt('286'));
    //stepsBox = await Hive.openBox<int>('steps');

    //int savedStepsCount = int.parse(stepsBox.get(savedStepsCountKey, defaultValue: 0).toString());
    if(prefs.getInt(savedStepsCountKey)!=null) {
      print(prefs.getInt(savedStepsCountKey));
      //printing how many of device returned step count is from previous dates
    } else {
      print("0");
    }
    int savedStepsCount = prefs.getInt(savedStepsCountKey)??0;
    /*the above part of device returned step count is from past dates and needs to be subtracted
    to get today's count
     */
    if (Jiffy(DateTime.now()).day == 1) {
      thisWeeksSteps = 0;
      print("today is sunday. Day of week is " + (Jiffy(DateTime.now()).day).toString());
    } else {
      thisWeeksSteps = 0;
      print("today is not sunday. It is " + (Jiffy(DateTime.now()).day).toString() + " No day of this week");
      for (var i = 1; i <= (Jiffy(DateTime.now()).day - 1); i++) {
        thisWeeksSteps += int.parse((prefs.getInt(((Jiffy(DateTime.now()).subtract(days: i)).year).toString() + (((Jiffy(DateTime.now()).subtract(days: i)).month).toString()).padLeft(2,'0') + (((Jiffy(DateTime.now()).subtract(days: i)).date).toString()).padLeft(2,'0'))??0).toString());
        print("Jiffy DateTime.now().subtract(days:i): " + (Jiffy(DateTime.now()).subtract(days: i)).toString());
        print((Jiffy(DateTime.now()).day - i).toString() + " No day of this week is " + ((Jiffy(DateTime.now()).subtract(days: i)).year).toString() + (((Jiffy(DateTime.now()).subtract(days: i)).month).toString()).padLeft(2,'0') + (((Jiffy(DateTime.now()).subtract(days: i)).date).toString()).padLeft(2,'0'));
        print("Steps on day " + (Jiffy(DateTime.now()).day - i).toString() + " of this week: " + (prefs.getInt(((Jiffy(DateTime.now()).subtract(days: i)).year).toString() + (((Jiffy(DateTime.now()).subtract(days: i)).month).toString()).padLeft(2,'0') + (((Jiffy(DateTime.now()).subtract(days: i)).date).toString()).padLeft(2,'0'))??0).toString());
      }
    }

    //int bufferSteps = int.parse(stepsBox.get(bufferKey, defaultValue: 0).toString());
    // load the last day saved using a package of your choice here

    //int lastDaySaved = int.parse(stepsBox.get(lastDaySavedKey, defaultValue: 0).toString());
    //prefs.setString(lastDaySavedKey,"20221111");
    //prefs.setInt(bufferKey,2937);
    String lastDaySaved = prefs.getString(lastDaySavedKey)??"0";
    /*print("Last day Saved is "+ lastDaySaved);
    print("Saved step count: " + prefs.getInt(savedStepsCountKey).toString());
    print("Steps saved for last day: " + prefs.getInt(lastDaySaved).toString());
    print("Buffer step count: " + prefs.getInt(bufferKey).toString());*/
    // When the day changes, reset the daily steps count 👇👇
    // and Update the last day saved as the day changes. 👇👇
    if (int.parse(todayDayNo) > int.parse(lastDaySaved)) {
      savedStepsCount = prefs.getInt(savedStepsCountKey) + prefs.getInt(lastDaySaved) - prefs.getInt(bufferKey);
      print("Steps saved for last day calculated: " + savedStepsCount.toString());
      /*👆👆 the steps of the lastDaySaved will now accumulate to savedStepsCount that needs
      to be subtracted for today Step count */
      await prefs.setInt(savedStepsCountKey, savedStepsCount);
      print("Steps saved for last day: " + prefs.getInt(lastDaySaved).toString());
      /*👆👆 portion of the device returned steps that belong to a previous date - being updated with
      lastDaySaved steps */
      lastDaySaved = todayDayNo;
      await prefs.setString(lastDaySavedKey, lastDaySaved);
      /*👆👆 The above line makes sure date change code piece is not called during today*/
      //savedStepsCount = value.steps; //old faulty code line which buried today's Steps before app started
      print("date changed");
      //stepsBox
      // ..put(lastDaySavedKey, lastDaySaved)
      // ..put(savedStepsCountKey, savedStepsCount);


      await prefs.setInt(bufferKey, 0);
      /*value referenced by bufferKey are steps of today before a device restart.
      Making them 0 as the date changed.
       */
    } else {
      if ((value.steps < int.parse(savedStepsCount.toString())) || ((value.steps == 0) && int.parse(savedStepsCount.toString()) == 0)) {
        // Upon device reboot, pedometer resets. When this happens, the saved counter must be reset as well.
        tempSavedSteps = int.parse(savedStepsCount.toString());
        savedStepsCount = 0;
        phoneRestarted = true;
        // persist this value using a package of your choice here
        //stepsBox.put(savedStepsCountKey, savedStepsCount);
        await prefs.setInt(savedStepsCountKey, savedStepsCount);
        //stepsBox.put(bufferKey,int.parse(stepsBox.get(todayDayNo, defaultValue: 0).toString()));
        await prefs.setInt(bufferKey, prefs.getInt(todayDayNo)??0);
      }
    }




    setState(() {
      todayDayNo = (Jiffy(DateTime.now()).year).toString() + ((Jiffy(DateTime.now()).month).toString()).padLeft(2,'0') + ((Jiffy(DateTime.now()).date).toString()).padLeft(2,'0');
      String lastDaySaved = prefs.getString(lastDaySavedKey)??"0";
      if (int.parse(todayDayNo) > int.parse(lastDaySaved)) {
        Restart.restartApp();
      }
      todaySteps = prefs.getInt(bufferKey) + value.steps - int.parse(savedStepsCount.toString());
      prefs.setInt(todayDayNo, todaySteps);
        //thisWeeksSteps += todaySteps;
        //yesterdaySteps = prefs.getInt((int.parse(todayDayNo) - 1).toString());
        //yesterdaySteps = prefs.getInt(((Jiffy(DateTime.now()).subtract(days: 1)).year).toString() + (((Jiffy(DateTime.now()).subtract(days: 1)).month).toString()).padLeft(2,'0') + (((Jiffy(DateTime.now()).subtract(days: 1)).date).toString()).padLeft(2,'0'));
        print("phone hasn't restarted.\n Android step count is "+ value.steps.toString());
        print("\n Temp Saved Steps count is " + tempSavedSteps.toString());
        print("\n Buffered Steps count is " + prefs.getInt(bufferKey).toString());
        print("Today Day No: " + todayDayNo);
        print("Last Saved Day: " + prefs.getString(lastDaySavedKey));
        print("Yesterday as per Jiffy formula: " + ((Jiffy(DateTime.now()).subtract(days: 1)).year).toString() + (((Jiffy(DateTime.now()).subtract(days: 1)).month).toString()).padLeft(2,'0') + (((Jiffy(DateTime.now()).subtract(days: 1)).date).toString()).padLeft(2,'0'));
        //print("March 5th, 2010 as per Jiffy formula on October 14th 2022: " + ((Jiffy(DateTime.now()).subtract(years: 12, months: 7, days: 9)).year).toString() + (((Jiffy(DateTime.now()).subtract(years: 12, months: 7, days: 9)).month).toString()).padLeft(2,'0') + (((Jiffy(DateTime.now()).subtract(years: 12, months: 7, days: 9)).date).toString()).padLeft(2,'0'));
        //}
    });
    //stepsBox.put(todayDayNo, todaySteps);
    await prefs.setInt(todayDayNo, todaySteps);
    //return todaySteps; // this is your daily steps value.
  }

  void stopListening() {
    //_subscription.cancel();
  }
  void onPedestrianStatusChanged(PedestrianStatus event) {
    print(event);
    setState(() {
      _status = event.status;
    });
  }

  void onPedestrianStatusError(error) {
    print('onPedestrianStatusError: $error');
    setState(() {
      _status = 'Pedestrian Status not available';
    });
    print(_status);
  }
}