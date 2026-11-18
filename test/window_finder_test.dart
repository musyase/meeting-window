import 'package:flutter_test/flutter_test.dart';
import 'package:meeting_window/window_finder.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

void main() {
  setUpAll(tzdata.initializeTimeZones);

  test('finds the narrow Moscow, London, New York overlap', () {
    final people = [
      const Participant(
        name: 'Moscow',
        zone: 'Europe/Moscow',
        startMinute: 540,
        endMinute: 1080,
      ),
      const Participant(
        name: 'London',
        zone: 'Europe/London',
        startMinute: 540,
        endMinute: 1080,
      ),
      const Participant(
        name: 'New York',
        zone: 'America/New_York',
        startMinute: 540,
        endMinute: 1080,
      ),
    ];
    final windows = findWindows(
      localDate: DateTime(2026, 11, 18),
      referenceZone: people.first.zone,
      participants: people,
      meetingLength: const Duration(hours: 1),
    );
    expect(windows, hasLength(1));
    expect(windows.single.startUtc, DateTime.utc(2026, 11, 18, 14));
    expect(windows.single.endUtc, DateTime.utc(2026, 11, 18, 15));
  });

  test('spring clock gap cannot produce a 02:00 meeting', () {
    final people = [
      const Participant(
        name: 'New York',
        zone: 'America/New_York',
        startMinute: 120,
        endMinute: 180,
      ),
      const Participant(
        name: 'UTC',
        zone: 'Europe/London',
        startMinute: 0,
        endMinute: 1440,
      ),
    ];
    final windows = findWindows(
      localDate: DateTime(2026, 3, 8),
      referenceZone: people.first.zone,
      participants: people,
      meetingLength: const Duration(minutes: 30),
    );
    expect(windows, isEmpty);
  });

  test('autumn repeated hour is two hours of real time', () {
    final people = [
      const Participant(
        name: 'New York',
        zone: 'America/New_York',
        startMinute: 60,
        endMinute: 120,
      ),
      const Participant(
        name: 'London',
        zone: 'Europe/London',
        startMinute: 0,
        endMinute: 1440,
      ),
    ];
    final windows = findWindows(
      localDate: DateTime(2026, 11, 1),
      referenceZone: people.first.zone,
      participants: people,
      meetingLength: const Duration(minutes: 30),
    );
    expect(windows, hasLength(1));
    expect(windows.single.startUtc, DateTime.utc(2026, 11, 1, 5));
    expect(windows.single.endUtc, DateTime.utc(2026, 11, 1, 7));
    expect(
      localLabel(windows.single.startUtc, people.first.zone),
      contains('UTC-04:00'),
    );
    expect(
      localLabel(DateTime.utc(2026, 11, 1, 6), people.first.zone),
      contains('UTC-05:00'),
    );
  });

  test('calendar export uses selected duration in UTC', () {
    final window = MeetingWindow(
      DateTime.utc(2026, 11, 18, 14),
      DateTime.utc(2026, 11, 18, 15),
    );
    final calendar = icsFor(window, const Duration(minutes: 30));
    expect(calendar, contains('DTSTART:20261118T140000Z'));
    expect(calendar, contains('DTEND:20261118T143000Z'));
    expect(calendar, contains('\r\nEND:VCALENDAR\r\n'));
  });

  test('rejects damaged saved participant data', () {
    expect(
      Participant.fromJson({
        'name': 'A',
        'zone': 'Europe/London',
        'start': 1080,
        'end': 540,
      }),
      isNull,
    );
    expect(
      Participant.fromJson({
        'name': 'A',
        'zone': 'Unknown/Zone',
        'start': 540,
        'end': 1080,
      }),
      isNull,
    );
  });
}
