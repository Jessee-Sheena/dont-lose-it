import 'package:flutter/material.dart';
import 'const.dart';
import 'package:provider/provider.dart';
import 'controller/data.dart';
import "package:firebase_core/firebase_core.dart";
import 'screens/rootscreen.dart';
import 'controller/notification.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(DontLoseIt());
}

class DontLoseIt extends StatelessWidget {
  // This widget is the root of your application.

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => Data()),
        ChangeNotifierProvider(create: (context) => LocalNotifications()),
      ],
      child: MaterialApp(
        title: 'Don\'t Lose It',
        theme: ThemeData(
          primaryColor: kPrimaryColor,
          accentColor: kBlueColor,
          // This makes the visual density adapt to the platform that you run
          // the app on. For desktop platforms, the controls will be smaller and
          // closer together (more dense) than on mobile platforms.
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        initialRoute: '/',
        routes: <String, WidgetBuilder>{
          '/': (BuildContext context) => RootScreen(),
        },
      ),
    );
  }
}
