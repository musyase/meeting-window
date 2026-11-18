import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import 'window_finder.dart';
import 'widgets.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  runApp(const MeetingWindowApp());
}

class MeetingWindowApp extends StatelessWidget {
  const MeetingWindowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meeting Window',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F7F2),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF17665B),
          onPrimary: Colors.white,
          primaryContainer: Color(0xFFD5E9E2),
          onPrimaryContainer: Color(0xFF0B423A),
          secondary: Color(0xFF93613F),
          surface: Color(0xFFF7F7F2),
          onSurface: Color(0xFF1D2A26),
          outline: Color(0xFF7A8880),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF7F7F2),
          foregroundColor: Color(0xFF1D2A26),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
      ),
      home: const PlannerPage(),
    );
  }
}

class PlannerPage extends StatefulWidget {
  const PlannerPage({super.key});

  @override
  State<PlannerPage> createState() => _PlannerPageState();
}

class _PlannerPageState extends State<PlannerPage> {
  static const storageKey = 'meeting_window_v1';
  DateTime date = DateTime.now();
  int minutes = 60;
  List<Participant> people = [
    const Participant(
      name: 'You',
      zone: 'Europe/Moscow',
      startMinute: 540,
      endMinute: 1080,
    ),
    const Participant(
      name: 'Teammate 2',
      zone: 'Europe/London',
      startMinute: 540,
      endMinute: 1080,
    ),
    const Participant(
      name: 'Teammate 3',
      zone: 'America/New_York',
      startMinute: 540,
      endMinute: 1080,
    ),
  ];

  @override
  void initState() {
    super.initState();
    unawaited(restore());
  }

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(storageKey);
    if (saved == null || !mounted) return;
    try {
      final data = jsonDecode(saved);
      if (data is! Map<String, dynamic> || data['people'] is! List) return;
      final restored = (data['people'] as List)
          .map(Participant.fromJson)
          .toList();
      final length = data['minutes'];
      if (restored.length < 2 ||
          restored.length > 4 ||
          restored.any((person) => person == null) ||
          length is! int ||
          ![30, 60, 90].contains(length)) {
        return;
      }
      setState(() {
        people = restored.cast<Participant>();
        minutes = length;
      });
    } on FormatException {
      // Damaged preferences leave the built-in example available.
    }
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      storageKey,
      jsonEncode({
        'people': people.map((person) => person.toJson()).toList(),
        'minutes': minutes,
      }),
    );
  }

  void changePerson(int index, Participant person) {
    setState(() => people[index] = person);
    unawaited(save());
  }

  void changeLength(int value) {
    setState(() => minutes = value);
    unawaited(save());
  }

  Future<void> chooseDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
      helpText: 'Date in ${people.first.zone}',
    );
    if (selected != null) setState(() => date = selected);
  }

  Future<void> share(MeetingWindow window) async {
    final bytes = Uint8List.fromList(
      utf8.encode(icsFor(window, Duration(minutes: minutes))),
    );
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              bytes,
              mimeType: 'text/calendar',
              name: 'meeting-window.ics',
            ),
          ],
          fileNameOverrides: ['meeting-window.ics'],
          subject: 'Meeting window',
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'The calendar file could not be shared on this device.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final windows = findWindows(
      localDate: date,
      referenceZone: people.first.zone,
      participants: people,
      meetingLength: Duration(minutes: minutes),
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Meeting Window',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: PlannerContent(
        date: date,
        minutes: minutes,
        people: people,
        windows: windows,
        onChooseDate: chooseDate,
        onChangeLength: changeLength,
        onChangePerson: changePerson,
        onAddPerson: () {
          if (people.length == 4) return;
          setState(
            () => people.add(
              Participant(
                name: 'Teammate ${people.length + 1}',
                zone: 'Asia/Singapore',
                startMinute: 540,
                endMinute: 1080,
              ),
            ),
          );
          unawaited(save());
        },
        onRemovePerson: () {
          if (people.length == 2) return;
          setState(() => people.removeLast());
          unawaited(save());
        },
        onShare: share,
      ),
    );
  }
}
