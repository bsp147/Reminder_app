import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() {
  runApp(ActivityReminderApp());
}

class ActivityReminderApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Activity Reminder',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
        debugShowCheckedModeBanner: false
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Activity> activities = [];

  void addActivity(Activity activity) {
    setState(() {
      activities.add(activity);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Activity Reminder'),
      ),
      body: Column(
        children: [
          ElevatedButton(
            child: Text('Add Activity'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ActivityForm(addActivity)),
              );
            },
          ),
          Expanded(
            child: ListView.builder(
              itemCount: activities.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(activities[index].name),
                  subtitle: Text(
                    'Day: ${activities[index].dayOfWeek} - Time: ${activities[index].time}',
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ActivityForm extends StatefulWidget {
  final Function(Activity) onActivityAdded;

  ActivityForm(this.onActivityAdded);

  @override
  _ActivityFormState createState() => _ActivityFormState();
}

class _ActivityFormState extends State<ActivityForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _timeController = TextEditingController();
  TimeOfDay _selectedTime = TimeOfDay.now();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  List<String> activitiesList = ['Wake Up', 'Go To Gym', 'Breakfast', 'Meetings', 'Lunch', 'Quick Nap', 'Go To Library', 'Dinner', 'Go to Sleep'];
  String? selectedActivity;

  List<String> daysOfWeekList = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  String? selectedDay;

  @override
  void initState() {
    super.initState();
    initializeNotifications();
  }

  void initializeNotifications() async {
    final AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('app_icon');
    final InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void scheduleNotification(String activityName, TimeOfDay time) async {
    tz.initializeTimeZones();
    final location = tz.local;

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'activity_reminder_channel',
      'Activity Reminder',
      channelDescription: 'Reminders for scheduled activities',
      importance: Importance.high,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('notification_sound'),
    );

    final NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    final now = DateTime.now();
    final activityTime = tz.TZDateTime(location, now.year, now.month, now.day, time.hour, time.minute);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      'Activity Reminder',
      'Remember to do $activityName',
      activityTime,
      platformChannelSpecifics,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'Activity Reminder',
    );

  }



  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (pickedTime != null && pickedTime != _selectedTime) {
      setState(() {
        _selectedTime = pickedTime;
        _timeController.text = DateFormat.Hm().format(DateTime(0, 1, 1, pickedTime.hour, pickedTime.minute));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Activity'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: selectedActivity,
                items: activitiesList.map((activity) {
                  return DropdownMenuItem<String>(
                    value: activity,
                    child: Text(activity),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedActivity = value;
                  });
                },
                decoration: InputDecoration(labelText: 'Activity'),
                validator: (value) {
                  if (value == null) {
                    return 'Please select an activity';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: selectedDay,
                items: daysOfWeekList.map((day) {
                  return DropdownMenuItem<String>(
                    value: day,
                    child: Text(day),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedDay = value;
                  });
                },
                decoration: InputDecoration(labelText: 'Day of Week'),
                validator: (value) {
                  if (value == null) {
                    return 'Please select a day of the week';
                  }
                  return null;
                },
              ),
              ListTile(
                title: Text('Time'),
                subtitle: Text(_timeController.text),
                onTap: () => _selectTime(context),
              ),
              ElevatedButton(
                child: Text('Set Reminder'),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    String activityName = selectedActivity!;
                    String dayOfWeek = selectedDay!;
                    TimeOfDay selectedTime = _selectedTime;

                    Activity newActivity = Activity(
                      name: activityName,
                      dayOfWeek: dayOfWeek,
                      time: DateFormat.Hm().format(DateTime(0, 1, 1, selectedTime.hour, selectedTime.minute)),
                    );

                    widget.onActivityAdded(newActivity);

                    scheduleNotification(activityName, selectedTime);

                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Reminder set successfully'),
                    ));

                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Activity {
  final String name;
  final String dayOfWeek;
  final String time;

  Activity({
    required this.name,
    required this.dayOfWeek,
    required this.time,
  });
}

