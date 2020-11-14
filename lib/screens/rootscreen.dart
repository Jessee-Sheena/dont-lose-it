import 'package:flutter/material.dart';
import '../controller/data.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'login_registration.dart';
import 'homescreen.dart';

class RootScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Data provider = Provider.of<Data>(context);

    return StreamBuilder<User>(
        stream: provider.authStateChanged,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            User user = snapshot.data;
            if (user == null) {
              return LogIn(provider);
            }
            return HomeScreen();
          } else {
            return Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
        });
  }
}
