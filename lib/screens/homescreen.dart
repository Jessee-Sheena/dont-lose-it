import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import '../controller/notification.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../const.dart';
import 'package:provider/provider.dart';
import '../controller/data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'dart:convert';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';

import 'package:keep_stuff/components/itemListTile.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TextEditingController _itemNameController = TextEditingController();
  TextEditingController _itemLocationController = TextEditingController();
  Duration _duration = Duration(hours: 24, minutes: 0, seconds: 0);

  // we need to get the time zone of the phone for accurate notification times.
  Future<void> _configureLocalTimeZone() async {
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterNativeTimezone.getLocalTimezone();

    tz.setLocalLocation(tz.getLocation(timeZoneName));
  }

  @override
  void initState() {
    super.initState();
    //get the users timeZone to have accurate timed notifications
    _configureLocalTimeZone();
  }

  Future<dynamic> addItemModal(
    context, {
    Function addItem,
    Function timePicker,
  }) {
    _itemNameController.clear();
    _itemLocationController.clear();
    return showDialog(
      context: context,
      builder: (_) => SimpleDialog(
        title: Text("Add an Item"),
        children: [
          SimpleDialogOption(
            child: TextField(
              controller: _itemNameController,
              decoration: InputDecoration(
                hintText: "Item Name",
              ),
            ),
          ),
          SimpleDialogOption(
            child: TextField(
              controller: _itemLocationController,
              decoration: InputDecoration(
                hintText: "Location Where Item is Supposed to be",
              ),
            ),
          ),
          SimpleDialogOption(
            child: Text("Set Notification Schedule"),
            onPressed: timePicker,
          ),
          FlatButton(
            child: Text("Add Item"),
            onPressed: addItem,
          ),
        ],
      ),
    );
  }

  // this modal will ask user for the location of the incorrectly located item.
  Future<dynamic> locatedItemModal(
    context, {
    Function onPressedAdd,
    Function onPressedLost,
    List locationList,
  }) {
    _itemLocationController.clear();
    return showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) => SimpleDialog(
        title: Text("Where was your Item?"),
        children: [
          SimpleDialogOption(
            child: TextField(
              controller: _itemLocationController,
              decoration: InputDecoration(
                hintText: "Item Location",
              ),
            ),
          ),
          locationList.isNotEmpty
              ? SimpleDialogOption(
                  child: Text(
                      "Your item might be in one of the locations listed below."),
                )
              : SizedBox(),
          SimpleDialogOption(
            child: locationList.isNotEmpty
                ? Container(
                    height: 200.0, // Change as per your requirement
                    width: 200.0, // Change as per your requirement
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: locationList.length,
                      itemBuilder: (BuildContext context, int index) {
                        return Text(
                          locationList[index],
                        );
                      },
                    ),
                  )
                : SizedBox(),
          ),
          Row(
            children: [
              FlatButton(
                child: Text("Add Location"),
                onPressed: onPressedAdd,
              ),
              FlatButton(
                child: Text("Lost Item"),
                onPressed: onPressedLost,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // this modal controls whether you add or delete an  item.
  Future<dynamic> controlModal(context, {Function delete, Function add}) {
    return showDialog(
      context: context,
      builder: (_) => SimpleDialog(
        title: Text("Item Controls"),
        children: [
          SimpleDialogOption(
            child: FlatButton(
              child: Text("Add Item"),
              onPressed: add,
            ),
          ),
          SimpleDialogOption(
            child: FlatButton(
              child: Text("Delete Item"),
              onPressed: delete,
            ),
          ),
        ],
      ),
    );
  }

  //this modal controls what happens when notification is clicked.
  Future<dynamic> notificationModal(context,
      {Function idealLocation,
      Function otherLocation,
      String item,
      String location}) {
    return showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) => SimpleDialog(
        title: Text("Where is your $item"),
        children: [
          SimpleDialogOption(
            child: FlatButton(
              child: Text("$location"),
              onPressed: idealLocation,
            ),
          ),
          SimpleDialogOption(
            child: FlatButton(
              child: Text("Other Location"),
              onPressed: otherLocation,
            ),
          ),
        ],
      ),
    );
  }

  // give a congratulatory message to the user for knowing where their item is.
  Future<dynamic> congratulationModal(context,
      {String item, String location, Function onTap}) {
    return showDialog(
      context: context,
      builder: (_) => SimpleDialog(
        title: ListTile(
          title: Text("Congratulations!"),
          trailing: GestureDetector(
            child: Icon(Icons.clear),
            onTap: onTap,
          ),
        ),
        titlePadding: EdgeInsets.only(left: 90),
        children: [
          SimpleDialogOption(
            child: Text(
                "You have kept your $item in it's ideal location: $location!"),
          ),
        ],
      ),
    );
  }

  // we need to set the count for the notificationCount variable based on the highest notification number.
  Future<int> setNotificationCount(notification) async {
    int temp = await notification.getHighestNotificationId();
    if (temp > 0) {
      temp++;
    } else {
      temp = 1;
    }
    return temp;
  }

  // delete item
  void lost(Data provider, LocalNotifications notification, String item,
      String user) async {
    provider.deleteItem(item, user);
    //cancel alarm notification
    int id = await notification.getHighestNotificationId();
    notification.cancelNotification(id);

    //cancel item notification
    int otherId = await notification.getNotificationId("Where is your " + item);
    notification.cancelNotification(otherId);
    Navigator.of(context, rootNavigator: true).pop();
  }

  //this functions is the callback for the addItem modal
  void addItemFunction(
    Data provider,
    user,
    LocalNotifications notification,
  ) async {
    if (_itemLocationController.text != "" &&
        _itemLocationController.text != "") {
      provider.uploadItem(
          _itemNameController.text, _itemLocationController.text, user);

      int notificationCount = await setNotificationCount(notification);
      notification.scheduledNotification(
        // schedule notification for item
        channelID: _itemNameController.text,
        channelName: _itemNameController.text,
        channelDesc: _itemLocationController.text,
        notificationId: notificationCount,
        notificationTitle: "Where is your " + _itemNameController.text,
        notificationBody:
            "is your ${_itemNameController.text} located: ${_itemLocationController.text}?",

        notificationTime: tz.TZDateTime.now(tz.local).add(
          _duration,
        ),
      );
      //close modal when finished
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  //this function is the callback for the timePickerFunction
  void timePickerFunction() {
    DatePicker.showTimePicker(context,
        theme: DatePickerTheme(
          containerHeight: 210.0,
        ),
        showTitleActions: true, onConfirm: (time) {
      setState(() {
        _duration = Duration(
            hours: time.hour, minutes: time.minute, seconds: time.second);
      });
    }, currentTime: DateTime.now(), locale: LocaleType.en);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    //initialize provider and get the user
    Data provider = Provider.of<Data>(context);
    String user = provider.getUser();

    // initialize the notification provider
    LocalNotifications notification = Provider.of<LocalNotifications>(context);

    // onSelectNotification callback method to route the clicked notification
    Future<dynamic> onSelectNotification(String payload) async {
      // get the payload
      Map<String, dynamic> itemInfo = jsonDecode(payload);

      //reschedule the notification
      int firstId = await notification
          .getNotificationId("Where is your " + itemInfo['item']);
      if (firstId == null) {
        int id = await setNotificationCount(notification) + 1;
        notification.repeatNotification(
          channelID: itemInfo['item'],
          channelName: itemInfo['item'],
          notificationTitle: "Where is your " + itemInfo['item'],
          channelDesc: itemInfo['location'],
          notificationBody:
              "is your ${itemInfo['item']} located: ${itemInfo['location']}?",
          notificationId: id,
        );
      }
      // get the modal when notification is clicked
      notificationModal(context, idealLocation: () async {
        //remove control modal
        Navigator.of(context, rootNavigator: true).pop();

        await congratulationModal(context,
            item: itemInfo['item'], location: itemInfo['location'], onTap: () {
          Navigator.of(context, rootNavigator: true).pop();
        });
      }, otherLocation: () async {
        //remove previous modal
        Navigator.of(context, rootNavigator: true).pop();

        //get the id for the alarm notification and set alarm
        int id = await setNotificationCount(notification) + 1;
        notification.repeatNotification(notificationId: id);

        // get list of locations if available
        List<dynamic> locationList =
            await provider.getLocationList(user, itemInfo['item']);

        // call the modal to insert the location
        locatedItemModal(
          context,
          locationList: locationList,
          onPressedAdd: () async {
            if (_itemLocationController.text != "") {
              provider.uploadLocation(
                  itemInfo['item'], _itemLocationController.text, user);

              notification.cancelNotification(id);
              Navigator.of(context, rootNavigator: true).pop();
            }
          },
          onPressedLost: () =>
              lost(provider, notification, itemInfo['item'], user),
        );
      }, item: itemInfo['item'], location: itemInfo['location']);
    }

    // set the onSelectNotification method in the provider
    notification
        .initializeNotifications((payload) => onSelectNotification(payload));

    //return the view

    return Scaffold(
      appBar: AppBar(
        title: Text('Don\'t Lose It'),
        backgroundColor: kPrimaryColor,
        actions: [
          FlatButton(
            child: Icon(
              Icons.exit_to_app,
              color: Colors.white,
            ),
            onPressed: () {
              provider.signOut();
            },
          ),
        ],
      ),
      body: showListOfItems(user, provider, notification),
    );
  }

// the stream builder of the lists
  Container showListOfItems(
      String user, Data provider, LocalNotifications notification) {
    return Container(
      color: Colors.white,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection(user).snapshots(),
        builder: (context, snapshot) {
          print(snapshot.connectionState);
          if (!snapshot.hasData) {
            return CircularProgressIndicator();
          } else {
            return snapshot.data.docs.isNotEmpty
                ? ListView.builder(
                    itemCount: snapshot.data.docs.length,
                    itemBuilder: (BuildContext context, int index) {
                      DocumentSnapshot ds = snapshot.data.docs[index];
                      return ItemListTile(
                        image: Icon(Icons.vpn_key),
                        itemLocation: Text(
                            "Ideal Location: ${ds.data()['itemLocation']}"),
                        itemName: Text(ds.data()['itemName']),
                        onTap: () {
                          //go to modal to add item
                          controlModal(
                            context,
                            add: () {
                              //remove control modal
                              Navigator.of(context, rootNavigator: true).pop();

                              // run add item method
                              addItemModal(context, timePicker: () {
                                timePickerFunction();
                              }, addItem: () async {
                                addItemFunction(provider, user, notification);
                              });
                            },
                            delete: () async {
                              provider.deleteItem(ds.data()['itemName'], user);
                              int id = await notification.getNotificationId(
                                  "Where is your " + ds.data()['itemName']);

                              notification.cancelNotification(id);
                              Navigator.of(context, rootNavigator: true).pop();
                            },
                          );
                        }, // onTap
                      );
                    },
                  )
                : ItemListTile(
                    image: Icon(Icons.vpn_key),
                    itemLocation: Text(" Add Item location"),
                    itemName: Text("Add Item Name"),
                    onTap: () {
                      addItemModal(context, timePicker: () {
                        timePickerFunction();
                      }, addItem: () {
                        addItemFunction(provider, user, notification);
                      });
                    },
                  );
          }
        },
      ),
    );
  }
}
