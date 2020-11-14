import 'dart:io';

import 'package:flutter/material.dart';
import '../controller/notification.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../const.dart';
import 'package:provider/provider.dart';
import '../controller/data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TextEditingController _itemNameController = TextEditingController();
  TextEditingController _itemLocationController = TextEditingController();
  int notificationCount;

  Future<void> _configureLocalTimeZone() async {
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterNativeTimezone.getLocalTimezone();

    tz.setLocalLocation(tz.getLocation(timeZoneName));
  }

  @override
  void initState() {
    //get the users timeZone to have accurate timed notifications
    _configureLocalTimeZone();
  }

  //This modal allows user to add an item to the database

  Future<dynamic> addItemModal(context, {Function onPressed}) {
    _itemLocationController.clear();
    _itemNameController.clear();
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
          FlatButton(
            child: Text("Add Item"),
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }

  Future<dynamic> locatedItemModal(context, {Function onPressed}) {
    _itemLocationController.clear();
    return showDialog(
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
          FlatButton(
            child: Text("Add Location"),
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }

  // this modal controls whether you add or delete an  item

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

  //this modal controls what happens when notification is clicked
  Future<dynamic> notificationModal(context,
      {Function idealLocation,
      Function otherLocation,
      Function lost,
      String item,
      String location}) {
    return showDialog(
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
          SimpleDialogOption(
            child: FlatButton(
              child: Text("Lost Item"),
              onPressed: lost,
            ),
          ),
        ],
      ),
    );
  }

  // give a congratulatory message to the user for knowing where their item is
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

  void setNotificationCount(notification) async {
    int temp = await notification.getHighestNotificationId() + 1;
    setState(() {
      notificationCount = temp;
    });
  }

  @override
  Widget build(BuildContext context) {
    //initialize provider and get the user
    Data provider = Provider.of<Data>(context);
    String user = provider.getUser();

    // initialize the notification provider
    LocalNotifications notification = Provider.of<LocalNotifications>(context);

    // delete item
    void lost(Data provider, String item, String user, int id) {
      provider.deleteItem(item, user);
      notification.cancelNotification(id);
      Navigator.of(context, rootNavigator: true).pop();
    }

    // onSelectNotification callback method to route the clicked notification
    Future<dynamic> onSelectNotification(String payload) async {
      // get the payload
      Map<String, dynamic> itemInfo = jsonDecode(payload);
      int id = await notification
          .getNotificationId("Where is your " + itemInfo['item']);
      notificationModal(context,
          idealLocation: () async {
            //remove control modal
            Navigator.of(context, rootNavigator: true).pop();

            await congratulationModal(context,
                item: itemInfo['item'],
                location: itemInfo['location'], onTap: () {
              Navigator.of(context, rootNavigator: true).pop();
            });
          },
          otherLocation: () {
            Navigator.of(context, rootNavigator: true).pop();
            locatedItemModal(
              context,
              onPressed: () {
                provider.uploadLocation(
                    itemInfo['item'], _itemLocationController.text, user);
                Navigator.of(context, rootNavigator: true).pop();
              },
            );
          },
          lost: () => lost(provider, itemInfo['item'], user, id),
          item: itemInfo['item'],
          location: itemInfo['location']);
    }

    // set the onSelectNotification method
    notification.initializeNotifications((payload) => onSelectNotification(
        '{ "item": "${_itemNameController.text}", "location": "${_itemLocationController.text}"}'));

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
                          print('tapped');
                          //go to modal to add item
                          controlModal(
                            context,
                            add: () {
                              print('in the add function');
                              //remove control modal
                              Navigator.of(context, rootNavigator: true).pop();

                              // run add item method
                              addItemModal(context, onPressed: () {
                                provider.uploadItem(_itemNameController.text,
                                    _itemLocationController.text, user);
                                setNotificationCount(notification);
                                notification.scheduledNotification(
                                  // schedule notification for item
                                  channelID: "channel id",
                                  channelName: "channel name",
                                  channelDesc: "channel",
                                  notificationId: notificationCount,
                                  notificationTitle: "Where is your " +
                                      _itemNameController.text,
                                  notificationBody:
                                      "is your ${_itemNameController.text} located: ${_itemLocationController.text}?",
                                  notificationTime:
                                      tz.TZDateTime.now(tz.local).add(
                                    Duration(seconds: 10),
                                  ),
                                );
                                //close modal when finished
                                Navigator.of(context, rootNavigator: true)
                                    .pop();
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
                      addItemModal(context, onPressed: () {
                        provider.uploadItem(_itemNameController.text,
                            _itemLocationController.text, user);
                        setNotificationCount(notification);
                        notification.scheduledNotification(
                          // schedule notification for item
                          channelID: "channel id",
                          channelName: "channel name",
                          channelDesc: "channel",
                          notificationId: notificationCount,
                          notificationTitle:
                              "Where is your " + _itemNameController.text,
                          notificationBody:
                              "is your ${_itemNameController.text} located: ${_itemLocationController.text}?",
                          notificationTime: tz.TZDateTime.now(tz.local).add(
                            Duration(seconds: 10),
                          ),
                        );
                        Navigator.of(context, rootNavigator: true).pop();
                      });
                    },
                  );
          }
        },
      ),
    );
  }
}

// this item is the tile that is dynamically built in the list view builder.
class ItemListTile extends StatelessWidget {
  final Widget image;
  final Widget itemName;
  final Widget itemLocation;
  final Function onTap;
  const ItemListTile(
      {this.image, this.itemName, this.itemLocation, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: 25, top: 25, right: 25),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: kBlueColor,
      ),
      child: GestureDetector(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              image == null ? SizedBox() : image,
              itemName,
              itemLocation,
            ],
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
