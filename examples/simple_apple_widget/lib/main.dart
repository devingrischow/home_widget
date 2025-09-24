import 'dart:async';
import 'dart:io';
// import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:home_widget/home_widget.dart';



//MacOS Requires format of TEAMID.TeamName.Project to work
//Signing Certificate MUST also be in Development 
//Most Reliable Operation has occured when Running through Xcode.
//  Sep 22, 2025: Note: Continue to monitor and improve reliability and stability while adding more features.
const groupID = "4DZJGNL44Y.example.widget_group";

const widgetName = "HomeWidgetExampleProvider";
const iOSWidgetName = "HomeWidgetExample";

//The main data key being updated
const countKey = 'count';


//Background callback for interactivity
//Used to controll different interaction commands
@pragma("vm:entry-point")
Future<void> interactiveCallback(Uri? data) async {
  print("Interactive Callback Called");
  print("URI Data: $data");
  
  if (data?.host == 'incrementpressed') {
    await HomeWidget.setAppGroupId(groupID);

    try{
      var data = await HomeWidget.getWidgetData<String>(countKey, defaultValue: '0');
      debugPrint("Value of Data: $data");

      int dataInt = int.parse(data ?? "0");
      //Increase the Value by 1 
      dataInt += 1;

      String newIntVal = dataInt.toString();
      //Save the value and update the widget
      await HomeWidget.saveWidgetData<String>(countKey, newIntVal);

      await HomeWidget.updateWidget(
          name: widgetName,
          iOSName: iOSWidgetName
        );


    }on PlatformException catch (exception){
      debugPrint('Error Fetching Data From Widget. $exception');
    }

  }


  //Logic for handling interaction call UR:

    //Logic for Incrementing value


    
    //Save and Update Widget logic
    // await HomeWidget.setAppGroupId(groupID);
    // ....
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MaterialApp(home: MyHomePage() ) );
}



class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  

  final String title = "Counter Widget Demo";

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });

    

  }

  Future _sendNewCountData() async {
    try{
      return Future.wait([
        HomeWidget.saveWidgetData<String>(countKey, _counter.toString()),
      ]);
    } on PlatformException catch (exception) {
      debugPrint('Error Sending Count Data. $exception');
    }
  }

  Future _updateWidgets() async {
    try{
      return Future.wait([
        HomeWidget.updateWidget(
          name: widgetName,
          iOSName: iOSWidgetName
        ),
      ]);
    }on PlatformException catch (exception) {
      debugPrint("Error Updating Widgets. $exception");
    }
  }

  Future _loadCountData() async {
    print("Loading Count Data");
    try{
      return Future.wait([
        HomeWidget.getWidgetData<String>(countKey, defaultValue: '0')
        .then( (value) => setState(() {
          _counter = int.parse(value ?? '0');
        }) )
      ]);
    }on PlatformException catch (exception) {
      debugPrint('Error Getting Count Data. $exception');
    }
  }

  Future<void> _sendAndUpdate() async {
    print("Updating widget with new Data");
    await _sendNewCountData();
    await _updateWidgets();
  }

  void _launchedFromWidget(Uri? uri) {
    print("Checked Uri: $uri");
    if (uri != null) {
      showDialog(
        context: context,
        builder: (buildContext) => AlertDialog(
          title: const Text('App started from HomeScreenWidget'),
          content: Text('Here is the URI: $uri'),
        ),
      );
    }
  }

  void _checkForWidgetLaunch() {
    HomeWidget.initiallyLaunchedFromHomeWidget().then(_launchedFromWidget);
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkForWidgetLaunch();
    HomeWidget.widgetClicked.listen(_launchedFromWidget);
  }

  @override
  void initState() {
    super.initState();
    HomeWidget.setAppGroupId(groupID);
    HomeWidget.registerInteractivityCallback(interactiveCallback);
  }

 



  

  @override
  Widget build(BuildContext context) {
   
    return Scaffold(
      appBar: AppBar(
        
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
       
        title: Text(widget.title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            //Two Buttons: 
            //1. Get Widget Button Count 
            //2. Update the Count (just updates the count, pressing it also calls the updates)
            ElevatedButton(
              onPressed: _loadCountData, 
              child: Text("Get Button Count")
            ),

            ElevatedButton(
              onPressed: _sendAndUpdate, 
              child: Text("Update Widget Count")
            ),

            ElevatedButton(
              onPressed: _checkForWidgetLaunch, 
              child: Text("Check if Launched from Widget")
            ),
          ],
        )

        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), 
    );
  }
}
