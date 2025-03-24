import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:io';
import 'package:flutter_timezone/flutter_timezone.dart';

import 'question.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await _requestNotificationPermission();
  await _configureLocalTimeZone();
  AwesomeNotifications().initialize(
    'resource://mipmap/ic_launcher',
    [
      NotificationChannel(
        channelKey: 'daily_channel',
        channelName: 'Daily Notifications',
        channelDescription: 'Used for Daily notifications',
        importance: NotificationImportance.Max,
        channelShowBadge: true,
      ),
    ],
    debug: true,
  );
  runApp(const MyApp());
}


Future<void> _requestNotificationPermission() async {
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
}

Future<void> _configureLocalTimeZone() async {
  tz.initializeTimeZones();
  try {
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));
    debugPrint("Time zone set to $timeZoneName");
  } catch (e) {
    debugPrint("Failed to get time zone: $e");
    tz.setLocalLocation(tz.getLocation('UTC'));
  }
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Menu',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF005EB8)),
        useMaterial3: true,
      ),
      home: const MainMenu(title: 'Main Menu'),
    );
  }
}

// ----------------- MAIN MENU SCREEN -----------------
class MainMenu extends StatelessWidget {
  final String title;
  const MainMenu({super.key, required this.title});

  Future<void> _ensureTimeZoneInitialized() async {
    try {
      tz.initializeTimeZones();
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      debugPrint("Time zone initialized: $timeZoneName");
    } catch (e) {
      debugPrint("Failed to initialize time zone: $e");
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
  }





  @override
  Widget build(BuildContext context) {
    final ButtonStyle largeButtonStyle = ElevatedButton.styleFrom(
      minimumSize: const Size(250, 60),
      textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    );

    final ButtonStyle regularButtonStyle = ElevatedButton.styleFrom(
      minimumSize: const Size(200, 50),
      textStyle: const TextStyle(fontSize: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            ElevatedButton(
              style: largeButtonStyle,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LedScreen()),
                );
              },
              child: const Text('Start'),
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              style: regularButtonStyle,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const QuestionnaireDaySelectorScreen()),
                );
              },
              child: const Text('Questionnaire'),
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              style: regularButtonStyle,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const OptionsScreen()),
                );
              },
              child: const Text('Options'),
            ),
            const SizedBox(height: 16),

            const SizedBox(height: 16),

            ElevatedButton(
              style: regularButtonStyle,
              onPressed: () {
                SystemChannels.platform.invokeMethod('SystemNavigator.pop', true);
              },
              child: const Text('Quit'),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------- OPTIONS SCREEN -----------------

class OptionsScreen extends StatefulWidget {
  const OptionsScreen({super.key});
  @override
  State<OptionsScreen> createState() => _OptionsScreenState();
}

class _OptionsScreenState extends State<OptionsScreen> {
  final TextEditingController _controller = TextEditingController();
  String? _deviceId;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await _loadIds();
      await _requestNotificationPermissions();
      tz.initializeTimeZones();
      await _configureLocalTimeZone();
    });
  }

  Future<void> _loadIds() async {
    final prefs = await SharedPreferences.getInstance();

    String? deviceId = prefs.getString('device_id');
    if (deviceId == null) {
      deviceId = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
      await prefs.setString('device_id', deviceId);
    }

    String? uniqueId = prefs.getString('unique_id') ?? "";

    setState(() {
      _deviceId = deviceId;
      _controller.text = uniqueId;
    });

    debugPrint("Device ID: $_deviceId");
  }

  Future<void> _saveUniqueId() async {
    final prefs = await SharedPreferences.getInstance();
    String uniqueId = _controller.text;

    await prefs.setString('unique_id', uniqueId);

    if (_deviceId == null) {
      debugPrint("Error: Device ID not found");
      return;
    }

    await FirebaseFirestore.instance.collection('users').doc(_deviceId).set({
      'device_id': _deviceId,
      'unique_id': uniqueId,
      'timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Test ID saved!")),
    );
  }

  Future<void> _requestAndroidNotificationPermission() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  Future<void> _requestIOSNotificationPermissions() async {
    if (Platform.isIOS) {

      bool isAllowed = await AwesomeNotifications().isNotificationAllowed();

      if (!isAllowed) {
        await AwesomeNotifications().requestPermissionToSendNotifications();
      }
    }
  }

  Future<void> _requestNotificationPermissions() async {
    if (Platform.isAndroid) {
      await _requestAndroidNotificationPermission();
    } else if (Platform.isIOS) {
      await _requestIOSNotificationPermissions();
    }
  }

  Future<void> _configureLocalTimeZone() async {
    tz.initializeTimeZones();
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      debugPrint("Time zone set to $timeZoneName");
    } catch (e) {
      debugPrint("Failed to get time zone: $e");
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
  }


  Future<void> _pickTime() async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );

    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  Future<void> _scheduleDailyNotification() async {
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please pick a time first!")),
      );
      return;
    }


    final now = DateTime.now();
    DateTime scheduledDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );


    if (scheduledDateTime.isBefore(now)) {
      scheduledDateTime = scheduledDateTime.add(const Duration(days: 1));
    }


    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 1234,
        channelKey: 'daily_channel',
        title: 'Daily BLT Reminder',
        body: 'It\'s time for your daily BLT session!',
      ),
      schedule: NotificationCalendar.fromDate(
        date: scheduledDateTime,
        repeats: true,
        preciseAlarm: true,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Scheduled daily notification for ${_selectedTime!.format(context)}")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Options")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text("Enter your Test ID:", style: TextStyle(fontSize: 25)),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(hintText: "Test ID"),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveUniqueId,
              child: const Text("Save", style: TextStyle(fontSize: 30)),
            ),
            const SizedBox(height: 16),

            if (_deviceId != null)
              Text(
                "Device ID: $_deviceId",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _pickTime,
              child: const Text("Pick Notification Time", style: TextStyle(fontSize: 30)),
            ),
            const SizedBox(height: 20),

            if (_selectedTime != null)
              Text(
                "Selected Time: ${_selectedTime!.format(context)}",
                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _scheduleDailyNotification,
              child: const Text("Schedule Daily Notification", style: TextStyle(fontSize: 25)),
            ),
          ],
        ),
      ),
    );
  }
}



// ----------------- LED CONTROL SCREEN -----------------
class LedScreen extends StatefulWidget {
  const LedScreen({super.key});

  @override
  _LedScreenState createState() => _LedScreenState();
}

class _LedScreenState extends State<LedScreen> {
  bool _isScanning = false;
  bool isLedOn = false;
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _ledCharacteristic;
  BluetoothCharacteristic? _proximityCharacteristic;
  List<BluetoothDevice> _availableDevices = [];

  Timer? _timer;
  Duration _elapsedTime = Duration.zero;
  static const int proximityThreshold = 30;
  int _currentProximity = 100;

  final String deviceNamePrefix = "Nano33BLE_Prox";
  final Guid serviceUuid = Guid("19B10000-E8F2-537E-4F6C-D104768A1214");
  final Guid ledCharacteristicUuid = Guid("19B10001-E8F2-537E-4F6C-D104768A1214");
  final Guid proximityCharacteristicUuid = Guid("19B10003-E8F2-537E-4F6C-D104768A1214");

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.location,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();
  }

  Future<void> _scanForDevices() async {
    await _requestPermissions();
    setState(() {
      _isScanning = true;
      _availableDevices.clear();
    });

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

    FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        _availableDevices = results
            .map((r) => r.device)
            .where((d) => d.name.startsWith(deviceNamePrefix))
            .toList();
      });
    });

    await Future.delayed(const Duration(seconds: 10));
    FlutterBluePlus.stopScan();
    setState(() => _isScanning = false);
    _showDeviceSelectionDialog();
  }

  void _showDeviceSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Select Glasses to Connect"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _availableDevices.length,
              itemBuilder: (context, index) {
                final device = _availableDevices[index];
                return ListTile(
                  title: Text(device.name),
                  subtitle: Text(device.remoteId.toString()),
                  onTap: () {
                    Navigator.pop(context);
                    _connectToDevice(device);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    setState(() => _isScanning = false);

    try {
      await device.connect();

      _connectedDevice = device;
      final services = await device.discoverServices();

      for (BluetoothService s in services) {
        if (s.uuid == serviceUuid) {
          for (BluetoothCharacteristic c in s.characteristics) {
            if (c.uuid == ledCharacteristicUuid) {
              _ledCharacteristic = c;
            } else if (c.uuid == proximityCharacteristicUuid) {
              _proximityCharacteristic = c;
            }
          }
        }
      }

      if (_proximityCharacteristic != null) {
        await _proximityCharacteristic!.setNotifyValue(true);
        _proximityCharacteristic!.lastValueStream.listen((data) {
          if (data.isNotEmpty && mounted) {
            setState(() {
              _currentProximity = data[0];
            });
          }
        });
      }

      setState(() {});
    } catch (e) {
      debugPrint("Error connecting: $e");
    }
  }

  Future<void> _disconnectDevice() async {
    if (_connectedDevice != null) {

      if (_ledCharacteristic != null && isLedOn) {
        await _ledCharacteristic!.write([0]);
        setState(() => isLedOn = false);
      }

      await _connectedDevice!.disconnect();
      setState(() {
        _connectedDevice = null;
        _ledCharacteristic = null;
        _proximityCharacteristic = null;
        isLedOn = false;
      });
    }
  }

  Future<void> _toggleLed() async {
    if (_ledCharacteristic != null) {
      isLedOn = !isLedOn;
      await _ledCharacteristic!.write([isLedOn ? 1 : 0]);
      if (mounted) setState(() {});

      if (isLedOn) {
        _startTimer();
      } else {
        _stopTimer();
      }
    }
  }

  void _startTimer() {
    if (_timer != null) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (isLedOn && _currentProximity < proximityThreshold && mounted) {
        setState(() {
          _elapsedTime += const Duration(seconds: 1);
        });
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _saveTimerData() async {
    final prefs = await SharedPreferences.getInstance();
    String uniqueId = prefs.getString('unique_id') ?? "unknown";
    String? deviceId = prefs.getString('device_id');
    final now = DateTime.now();
    final timeString = now.toIso8601String();

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(deviceId)
          .collection('led_timer_data')
          .add({
        'elapsed_seconds': _elapsedTime.inSeconds,
        'timestamp': timeString,
        'unique_id': uniqueId
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Timer data saved!")),
      );

      setState(() {
        _elapsedTime = Duration.zero;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving timer data: $e")),
      );
    }

  }

  @override
  Widget build(BuildContext context) {
    final deviceStatus = _connectedDevice == null ? "Not Connected" : "Connected";
    final minutes = _elapsedTime.inMinutes;
    final seconds = _elapsedTime.inSeconds % 60;
    final elapsedFormatted = "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";

    return Scaffold(
      appBar: AppBar(title: const Text("LED Control")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(deviceStatus,
                style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),


            AnimatedOpacity(
              opacity: _connectedDevice == null ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: ElevatedButton(
                onPressed: _connectedDevice == null ? _scanForDevices : null,
                child: Text(_isScanning ? "Scanning..." : "Connect to Glasses"),
              ),
            ),
            const SizedBox(height: 18),

            ElevatedButton(
              onPressed: _connectedDevice == null ? null : _toggleLed,
              child: Text(isLedOn ? "Turn LED OFF" : "Turn LED ON"),
            ),
            const SizedBox(height: 18),

            Text("Elapsed Time: $elapsedFormatted", style: const TextStyle(fontSize: 25)),
            const SizedBox(height: 18),

            ElevatedButton(
              onPressed: _saveTimerData,
              child: const Text("Save Timer Data"),
            ),
            const SizedBox(height: 18),

            ElevatedButton(
              onPressed: _connectedDevice != null ? _disconnectDevice : null,
              child: const Text("Disconnect"),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------- QUESTIONNAIRE DAY SELECTOR SCREEN -----------------

class QuestionnaireDaySelectorScreen extends StatefulWidget {
  const QuestionnaireDaySelectorScreen({super.key});
  @override
  State<QuestionnaireDaySelectorScreen> createState() => _QuestionnaireDaySelectorScreenState();
}

class _QuestionnaireDaySelectorScreenState extends State<QuestionnaireDaySelectorScreen> {
  DateTime? _selectedDate;
  String? _selectedDay;

  final _dayOptions = [
    "Baseline",
    for (var i = -3; i <= -1; i++) "Pretravel Day $i",
    for (var i = 1; i <= 3; i++) "Post-travel Day $i",
    "Post-travel Day 7"
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _selectedDay = _dayOptions.first;
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate!,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = "${_selectedDate!.month}/${_selectedDate!.day}/${_selectedDate!.year}";

    return Scaffold(
      appBar: AppBar(title: const Text("Date and Day Selection")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Selected Date: $formattedDate", style: const TextStyle(fontSize: 21)),
                ElevatedButton(
                  onPressed: _pickDate,
                  child: const Text("Pick Date"),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                const Text("Select Day:", style: TextStyle(fontSize: 25)),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _selectedDay,
                  items: _dayOptions.map((String day) {
                    return DropdownMenuItem<String>(
                      value: day,
                      child: Text(day, style: TextStyle(fontSize: 25)),
                    );
                  }).toList(),
                  onChanged: (newDay) {
                    setState(() {
                      _selectedDay = newDay!;
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: () {
                if (_selectedDate != null && _selectedDay != null) {
                  String dayKey = "${_selectedDate!.toIso8601String()} - $_selectedDay";
                  String dayTitle = "Selected: $_selectedDay on $formattedDate";

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QuestionnaireTypeMenuScreen(
                        dayKey: dayKey,
                        dayTitle: dayTitle,
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please select a date and a day option.")),
                  );
                }
              },
              child: const Text("Continue", style: TextStyle(fontSize: 30)),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------- QUESTIONNAIRE TYPE MENU SCREEN -----------------
class QuestionnaireTypeMenuScreen extends StatelessWidget {
  final String dayKey;
  final String dayTitle;
  const QuestionnaireTypeMenuScreen({super.key, required this.dayKey, required this.dayTitle});
  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> types = [
      {"id": "psqi", "title": psqiQuestionnaire.title, "questionnaire": psqiQuestionnaire},
      {"id": "wsas", "title": wsasQuestionnaire.title, "questionnaire": wsasQuestionnaire},
      {"id": "icecapA", "title": icecapAQuestionnaire.title, "questionnaire": icecapAQuestionnaire},
    ];
    return Scaffold(
      appBar: AppBar(title: Text("Select Questionnaire")),
      body: ListView.builder(
        itemCount: types.length,
        itemBuilder: (context, index) {
          final option = types[index];
          return ListTile(
            title: Text(
              option["title"]!,
              style: const TextStyle(fontSize: 22),
            ),

            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => QuestionnaireScreen(
                    dayKey: dayKey,
                    questionnaire: option["questionnaire"],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ----------------- QUESTIONNAIRE SCREEN -----------------
class QuestionnaireScreen extends StatefulWidget {
  final String dayKey;
  final Questionnaire questionnaire;
  const QuestionnaireScreen({super.key, required this.dayKey, required this.questionnaire});
  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  final Map<int, dynamic> _answers = {};
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _checkIfSubmitted();
  }
  Future<void> _checkIfSubmitted() async {
    final prefs = await SharedPreferences.getInstance();
    bool submitted = prefs.getBool('submission_${widget.dayKey}_${widget.questionnaire.id}') ?? false;
    setState(() {
      _submitted = submitted;
    });
  }
  Future<void> _submitAnswers() async {
    final now = DateTime.now();
    final timeString = now.toIso8601String();


    Map<String, dynamic> responseMap = {};
    for (int i = 0; i < widget.questionnaire.questions.length; i++) {
      String qText = widget.questionnaire.questions[i].questionText;
      dynamic ans = _answers[i];
      responseMap[qText] = ans ?? "Not answered";
    }


    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('device_id');
    String uniqueId = prefs.getString('unique_id') ?? "unknown";

    if (deviceId == null) {
      debugPrint("Error: Device ID not found.");
      return;
    }

    try {

      await FirebaseFirestore.instance
          .collection('users')
          .doc(deviceId)
          .collection('questionnaire_submissions')
          .add({
        'day': widget.dayKey,
        'questionnaire_id': widget.questionnaire.id,
        'questionnaire_title': widget.questionnaire.title,
        'unique_id': uniqueId,
        'responses': responseMap,
        'timestamp': timeString,
      });

      await prefs.setBool('submission_${widget.dayKey}_${widget.questionnaire.id}', true);
      setState(() {
        _submitted = true;
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Questionnaire submitted successfully!")),
        );
      }
    } catch (e) {
      debugPrint("Error submitting data: $e");
    }
  }

  Widget _buildQuestion(int index, QuestionItem question) {
    bool shouldDisplayNumber = question.displayNumber;


    if (question.questionText == "During the past month, how often have you had trouble sleeping because you...") {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          question.questionText,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Text(
          shouldDisplayNumber
              ? "${_getCorrectNumber(index)} ${question.questionText}"
              : question.questionText,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),


        if (question.useSlider)
          Column(
            children: [
              Slider(
                value: (_answers[index] ?? 4.0).toDouble(),
                min: 0,
                max: 8,
                divisions: 8,
                label: (_answers[index] ?? 4.0).toString(),
                onChanged: _submitted ? null : (double value) {
                  setState(() {
                    _answers[index] = value.toInt();
                  });
                },
              ),
              Text(
                "Selected: ${(_answers[index] ?? 4).toInt()}",
                style: const TextStyle(fontSize: 18),
              ),
            ],
          ),



        if (question.isTimePicker)
          TextButton(
            onPressed: _submitted ? null : () async {
              TimeOfDay? picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (picked != null) {
                setState(() {
                  _answers[index] =
                  "${picked.hour}:${picked.minute.toString().padLeft(2, '0')}";
                });
              }
            },
            child: Text(
              _answers[index] ?? "Select Time",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),


        if (question.isNumericInput)
          TextField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: "Enter a number"),
            onChanged: (val) {
              setState(() {
                _answers[index] = val;
              });
            },
          ),


        if (question.options.isNotEmpty)
          Column(
            children: List.generate(question.options.length, (i) {
              return RadioListTile<int>(
                title: Text(question.options[i]),
                value: i,
                groupValue: _answers[index],
                onChanged: _submitted ? null : (val) {
                  setState(() {
                    _answers[index] = val;
                  });
                },
              );
            }),
          ),


        if (question.options.isEmpty && !question.useSlider && !question.isTimePicker && !question.isNumericInput)
          TextField(
            decoration: const InputDecoration(hintText: "Enter your answer"),
            onChanged: (val) {
              setState(() {
                _answers[index] = val;
              });
            },
          ),

        const Divider(),
      ],
    );
  }


  String _getCorrectNumber(int index) {
    int questionNumber = 0;
    for (int i = 0; i <= index; i++) {
      if (widget.questionnaire.questions[i].displayNumber) {
        questionNumber++;
      }
    }
    return "$questionNumber.";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${widget.questionnaire.title} - ${widget.dayKey}")),
      body: _submitted
          ? Center(child: Text("You've already submitted this questionnaire."))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (var instruction in widget.questionnaire.instructions)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(instruction, style: const TextStyle(fontSize: 20)),
              ),
            for (int i = 0; i < widget.questionnaire.questions.length; i++) ...[
              _buildQuestion(i, widget.questionnaire.questions[i]),
            ],
            ElevatedButton(
              onPressed: _submitAnswers,
              child: const Text("Submit"),
            ),
          ],
        ),
      ),
    );
  }
}