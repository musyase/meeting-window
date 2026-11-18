import 'package:timezone/timezone.dart' as tz;

const commonZones = <String>[
  'Europe/London',
  'Europe/Berlin',
  'Europe/Moscow',
  'America/New_York',
  'America/Chicago',
  'America/Los_Angeles',
  'America/Sao_Paulo',
  'Asia/Dubai',
  'Asia/Kolkata',
  'Asia/Singapore',
  'Asia/Tokyo',
  'Australia/Sydney',
];

class Participant {
  const Participant({
    required this.name,
    required this.zone,
    required this.startMinute,
    required this.endMinute,
  });

  final String name;
  final String zone;
  final int startMinute;
  final int endMinute;

  Participant copyWith({
    String? name,
    String? zone,
    int? startMinute,
    int? endMinute,
  }) => Participant(
    name: name ?? this.name,
    zone: zone ?? this.zone,
    startMinute: startMinute ?? this.startMinute,
    endMinute: endMinute ?? this.endMinute,
  );

  Map<String, Object> toJson() => {
    'name': name,
    'zone': zone,
    'start': startMinute,
    'end': endMinute,
  };

  static Participant? fromJson(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final name = value['name'];
    final zone = value['zone'];
    final start = value['start'];
    final end = value['end'];
    if (name is! String ||
        name.trim().isEmpty ||
        name.length > 32 ||
        zone is! String ||
        !commonZones.contains(zone) ||
        start is! int ||
        end is! int ||
        start < 0 ||
        end > 1440 ||
        start >= end) {
      return null;
    }
    return Participant(
      name: name,
      zone: zone,
      startMinute: start,
      endMinute: end,
    );
  }
}

class MeetingWindow {
  const MeetingWindow(this.startUtc, this.endUtc);

  final DateTime startUtc;
  final DateTime endUtc;
  Duration get length => endUtc.difference(startUtc);
}

/// Finds intervals on one local calendar day in [referenceZone]. Iterating UTC
/// instants avoids inventing a time in a spring gap or losing a repeated hour.
List<MeetingWindow> findWindows({
  required DateTime localDate,
  required String referenceZone,
  required List<Participant> participants,
  required Duration meetingLength,
}) {
  if (participants.length < 2 ||
      participants.length > 4 ||
      meetingLength.inMinutes < 15 ||
      meetingLength.inMinutes > 180 ||
      meetingLength.inMinutes % 15 != 0) {
    throw ArgumentError(
      'Use 2 to 4 people and a meeting length in 15 minute steps.',
    );
  }
  final reference = tz.getLocation(referenceZone);
  final dayStart = tz.TZDateTime(
    reference,
    localDate.year,
    localDate.month,
    localDate.day,
  ).toUtc();
  final dayEnd = tz.TZDateTime(
    reference,
    localDate.year,
    localDate.month,
    localDate.day + 1,
  ).toUtc();
  final locations = participants
      .map((person) => tz.getLocation(person.zone))
      .toList();
  const step = Duration(minutes: 15);
  final results = <MeetingWindow>[];
  DateTime? openStart;
  DateTime? openEnd;

  for (
    var candidate = dayStart;
    !candidate.add(meetingLength).isAfter(dayEnd);
    candidate = candidate.add(step)
  ) {
    final available = List.generate(participants.length, (index) {
      final person = participants[index];
      final location = locations[index];
      // A one minute sample also detects an offset change inside a slot.
      for (var minute = 0; minute < meetingLength.inMinutes; minute++) {
        final local = tz.TZDateTime.from(
          candidate.add(Duration(minutes: minute)),
          location,
        );
        final clock = local.hour * 60 + local.minute;
        if (clock < person.startMinute || clock >= person.endMinute) {
          return false;
        }
      }
      return true;
    }).every((value) => value);
    if (!available) continue;
    final end = candidate.add(meetingLength);
    if (openStart == null || candidate.isAfter(openEnd!)) {
      if (openStart != null) results.add(MeetingWindow(openStart, openEnd!));
      openStart = candidate;
      openEnd = end;
    } else if (end.isAfter(openEnd)) {
      openEnd = end;
    }
  }
  if (openStart != null) results.add(MeetingWindow(openStart, openEnd!));
  return results;
}

String clockLabel(int minute) =>
    '${(minute ~/ 60).toString().padLeft(2, '0')}:${(minute % 60).toString().padLeft(2, '0')}';

String localLabel(DateTime instantUtc, String zone) {
  final local = tz.TZDateTime.from(instantUtc, tz.getLocation(zone));
  const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final offset = local.timeZoneOffset;
  final sign = offset.isNegative ? '-' : '+';
  final total = offset.inMinutes.abs();
  final suffix =
      'UTC$sign${(total ~/ 60).toString().padLeft(2, '0')}:${(total % 60).toString().padLeft(2, '0')}';
  return '${weekdays[local.weekday - 1]} ${clockLabel(local.hour * 60 + local.minute)}  $suffix';
}

String icsFor(MeetingWindow window, Duration meetingLength) {
  if (meetingLength > window.length) {
    throw ArgumentError('Meeting is longer than the available window.');
  }
  String utc(DateTime value) {
    final date = value.toUtc();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${date.year}${two(date.month)}${two(date.day)}T${two(date.hour)}${two(date.minute)}${two(date.second)}Z';
  }

  final uid =
      '${window.startUtc.microsecondsSinceEpoch}-${window.length.inMinutes}@meeting-window.local';
  return [
    'BEGIN:VCALENDAR',
    'VERSION:2.0',
    'PRODID:-//Meeting Window//EN',
    'CALSCALE:GREGORIAN',
    'BEGIN:VEVENT',
    'UID:$uid',
    'DTSTAMP:${utc(DateTime.now())}',
    'DTSTART:${utc(window.startUtc)}',
    'DTEND:${utc(window.startUtc.add(meetingLength))}',
    'SUMMARY:Meeting across time zones',
    'DESCRIPTION:Time checked offline with Meeting Window.',
    'END:VEVENT',
    'END:VCALENDAR',
    '',
  ].join('\r\n');
}
