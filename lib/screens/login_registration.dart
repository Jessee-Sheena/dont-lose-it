import 'package:flutter/material.dart';
import '../const.dart';
import '../controller/data.dart';

class LogIn extends StatefulWidget {
  LogIn(this.provider);

  final Data provider;

  @override
  _LogInState createState() => _LogInState();
}

class _LogInState extends State<LogIn> {
  final _formKey = new GlobalKey<FormState>();
  bool _isLogInForm;
  String _password;

  String _email;

  String _name;
  String _emessage;
  String _message;
  Data provider;

  @override
  void initState() {
    super.initState();
    provider = widget.provider;
    _emessage = "";
    _isLogInForm = true;
    _password = '';
    _email = '';
    _name = '';
  }

  //saves the form information so the data can be sent to the firebase authentication.
  bool validateAndSave() {
    final form = _formKey.currentState;
    if (form.validate()) {
      form.save();
      return true;
    }
    return false;
  }

  // sends the data to the firebase authentication.
  void validateAndSubmit() async {
    if (validateAndSave()) {
      if (_isLogInForm) {
        _message = await provider.signIn(_email, _password);

        setState(() {
          _emessage = _message;
        });
      } else {
        _message = await provider.createAccount(_email, _password);
        setState(() {
          _emessage = _message;
        });
      }
    }
  }

  //toggles the login/and create account functionality.
  void toggleForm() {
    setState(() {
      _isLogInForm = !_isLogInForm;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: kPrimaryColor,
        child: Stack(
          children: [
            Center(
              child: Form(
                key: _formKey,
                child: Container(
                  padding: EdgeInsets.all(16.0),
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      Image.asset('images/logo.png'),
                      loginForm(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Container loginForm() {
    return Container(
      decoration: BoxDecoration(
        color: kBlueColor,
        borderRadius: BorderRadius.circular(5.0),
      ),
      child: Column(
        children: [
          formBoxTopBar(),
          !_isLogInForm
              ? appTextField(
                  hintText: 'Name',
                  type: TextInputType.text,
                  obscure: false,
                  validate: (String value) =>
                      value.trim().isEmpty ? "Name must not be empty." : null,
                  save: (String value) {
                    _name = value;
                  },
                )
              : SizedBox(),
          appTextField(
            hintText: 'Email',
            type: TextInputType.emailAddress,
            obscure: false,
            validate: (String value) {
              Pattern pattern =
                  r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
              RegExp regex = new RegExp(pattern);

              if (value.trim().isEmpty) {
                return "Email must not be empty.";
              } else if (!regex.hasMatch(value)) {
                return "Not a valid email.";
              }
              return null;
            },
            save: (String value) {
              _email = value;
            },
          ),
          appTextField(
            type: TextInputType.text,
            hintText: 'Password',
            validate: (String value) {
              if (value.trim().isEmpty) {
                return "Password must not be empty.";
              }
              return null;
            },
            obscure: true,
            save: (String value) {
              setState(() {
                _password = value;
              });
            },
          ),
          showErrorMessage(),
          submitButton(),
          toggledButton(),
        ],
      ),
    );
  }

  Container formBoxTopBar() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: kYellowColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(5.0),
          topRight: Radius.circular(5.0),
        ),
      ),
    );
  }

  RaisedButton submitButton() {
    return RaisedButton(
      color: kYellowColor,
      child: Text(
        _isLogInForm ? "Login" : "Create Account",
        style: ButtonStyle,
      ),
      onPressed: validateAndSubmit,
    );
  }

  FlatButton toggledButton() {
    return FlatButton(
      child: Text(
        !_isLogInForm ? "Already have an account? Login!" : "Create Account",
        style: ButtonStyle,
      ),
      onPressed: toggleForm,
    );
  }

  // this is the text field base, each text field uses individual parameters based on the type of field.
  Widget appTextField(
      {String hintText,
      bool obscure,
      Function validate,
      TextInputType type,
      Function save}) {
    return Padding(
      padding: EdgeInsets.all(10),
      child: TextFormField(
        keyboardType: type,
        autofocus: false,
        style: TextStyle(fontSize: 15.0, color: Colors.black),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.only(left: 14.0, bottom: 6.0, top: 8.0),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: kOrangeColor),
            borderRadius: BorderRadius.circular(5.0),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
            borderRadius: BorderRadius.circular(5.0),
          ),
        ),
        obscureText: obscure,
        onChanged: (value) {
          setState(() {
            _emessage = "";
          });
        },
        validator: validate,
        onSaved: save,
      ),
    );
  }

//shows error messages received from exception handling.
  Widget showErrorMessage() {
    if (_emessage != null && _emessage.length > 0) {
      return Text(
        _emessage,
        style: TextStyle(
          fontSize: 13.0,
          color: Colors.red,
          height: 1.0,
          fontWeight: FontWeight.w300,
        ),
      );
    } else {
      return Container(
        height: 0.0,
      );
    }
  }
}
