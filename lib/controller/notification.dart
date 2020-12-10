import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:timezone/timezone.dart';

class ReceivedNotification {
  final int id;
  final String title;
  final String body;
  final String payload;

  ReceivedNotification(
      {@required this.id,
      @required this.title,
      @required this.body,
      @required this.payload});
}

class LocalNotifications with ChangeNotifier {
  FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  AndroidInitializationSettings _androidInitializationSettings;
  IOSInitializationSettings _iosInitializationSettings;
  InitializationSettings _initializationSettings;

  Future<void> initializeNotifications(
      SelectNotificationCallback onSelectNotification) async {
    _androidInitializationSettings = AndroidInitializationSettings('app_icon');
    _iosInitializationSettings = IOSInitializationSettings(
        onDidReceiveLocalNotification: onDidReceiveLocalNotification);
    _initializationSettings = InitializationSettings(
        android: _androidInitializationSettings,
        iOS: _iosInitializationSettings);
    await notificationsPlugin?.initialize(_initializationSettings,
        onSelectNotification: onSelectNotification);
  }

  Future<dynamic> onDidReceiveLocalNotification(
      int id, String title, String body, String payload) async {
    return ReceivedNotification(
        id: id, title: title, body: body, payload: payload);
  }

  Future<dynamic> showNotifications(
      {@required String channelID,
      @required String channelName,
      @required String channelDescription,
      @required String notificationTitle,
      @required String notificationBody,
      String payload}) async {
    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        channelID, channelName, channelDescription,
        importance: Importance.max, priority: Priority.max);
    print('android details have been set');
    IOSNotificationDetails iosDetails = IOSNotificationDetails();
    NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await notificationsPlugin?.show(
        0, notificationTitle, notificationBody, notificationDetails,
        payload: 'item X');
  }

  Future<void> scheduledNotification(
      {@required String channelID,
      @required String channelName,
      @required String channelDesc,
      @required String notificationTitle,
      int notificationId,
      @required String notificationBody,
      @required DateTime notificationTime}) async {
    TZDateTime scheduledNotificationDateTime = notificationTime;

    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelID,
      channelName,
      channelDesc,
      ticker: '$channelName',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
    );

    IOSNotificationDetails iosDetails = IOSNotificationDetails();
    NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await notificationsPlugin?.zonedSchedule(
      notificationId,
      notificationTitle,
      notificationBody,
      scheduledNotificationDateTime,
      notificationDetails,
      payload: '{ "item": "$channelID", "location": "$channelDesc"}',
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidAllowWhileIdle: true,
    );
  }

  Future<void> repeatNotification({
    String channelID,
    String channelName,
    String channelDesc,
    String notificationTitle,
    int notificationId,
    String notificationBody,
  }) async {
    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelID,
      channelName,
      channelDesc,
      ticker: '$channelName',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
    );

    IOSNotificationDetails iosDetails = IOSNotificationDetails();
    NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await notificationsPlugin.periodicallyShow(
        notificationId,
        notificationTitle,
        notificationBody,
        RepeatInterval.everyMinute,
        notificationDetails,
        payload: '{ "item": "$channelID", "location": "$channelDesc" }',
        androidAllowWhileIdle: true);
  }

  Future<dynamic> cancelNotification(int id) async {
    try {
      await notificationsPlugin.cancel(id);
    } catch (e) {
      print(e);
    }
  }

  Future<int> getNotificationId(String title) async {
    List<PendingNotificationRequest> pendingNotificationRequests =
        await notificationsPlugin?.pendingNotificationRequests();
    final notification = pendingNotificationRequests?.firstWhere(
      (item) => item.title == title,
      orElse: () => null,
    );
    if (notification != null) return notification.id;
    return null;
  }

  Future<int> getHighestNotificationId() async {
    List<PendingNotificationRequest> pendingNotificationRequests =
        await notificationsPlugin?.pendingNotificationRequests();
    int maxId = 0;
    pendingNotificationRequests?.forEach((item) {
      if (item.id > maxId) maxId = item.id;
    });
    return maxId;
  }
}
