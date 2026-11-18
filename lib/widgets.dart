import 'package:material_ui/material_ui.dart';

import 'window_finder.dart';

const ink = Color(0xFF1D2A26);
const muted = Color(0xFF52645E);
const green = Color(0xFF17665B);

class PlannerContent extends StatelessWidget {
  const PlannerContent({
    super.key,
    required this.date,
    required this.minutes,
    required this.people,
    required this.windows,
    required this.onChooseDate,
    required this.onChangeLength,
    required this.onChangePerson,
    required this.onAddPerson,
    required this.onRemovePerson,
    required this.onShare,
  });

  final DateTime date;
  final int minutes;
  final List<Participant> people;
  final List<MeetingWindow> windows;
  final VoidCallback onChooseDate;
  final ValueChanged<int> onChangeLength;
  final void Function(int, Participant) onChangePerson;
  final VoidCallback onAddPerson;
  final VoidCallback onRemovePerson;
  final ValueChanged<MeetingWindow> onShare;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 860;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 60),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PLAN ACROSS TIME ZONES',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 1.7,
                    fontWeight: FontWeight.w800,
                    color: green,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Find a meeting window.',
                  style: TextStyle(
                    fontSize: wide ? 48 : 34,
                    height: 1.08,
                    letterSpacing: -1.4,
                    fontWeight: FontWeight.w700,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Choose a date and each person’s local working hours. Clock changes are included. No account or calendar access is needed.',
                  style: TextStyle(fontSize: 16, height: 1.45, color: muted),
                ),
                const SizedBox(height: 26),
                _controls(),
                const SizedBox(height: 26),
                if (wide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 10, child: _peopleSection()),
                      const SizedBox(width: 22),
                      Expanded(flex: 11, child: _resultsSection()),
                    ],
                  )
                else
                  Column(
                    children: [
                      _resultsSection(),
                      const SizedBox(height: 26),
                      _peopleSection(),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _controls() {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final dateText =
        '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
    return Wrap(
      spacing: 18,
      runSpacing: 16,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: onChooseDate,
          icon: const Icon(Icons.calendar_month_outlined),
          label: Text(dateText),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
          ),
        ),
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text(
              'Length',
              style: TextStyle(color: muted, fontWeight: FontWeight.w600),
            ),
            for (final length in [30, 60, 90])
              ChoiceChip(
                label: Text('$length min'),
                selected: length == minutes,
                onSelected: (_) => onChangeLength(length),
                selectedColor: const Color(0xFFD5E9E2),
                labelStyle: TextStyle(
                  color: length == minutes ? const Color(0xFF0B423A) : muted,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _peopleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'People and hours',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
            ),
            if (people.length < 4)
              TextButton.icon(
                onPressed: onAddPerson,
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              ),
          ],
        ),
        const SizedBox(height: 10),
        for (var index = 0; index < people.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _personCard(index, people[index]),
          ),
        if (people.length > 2)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onRemovePerson,
              child: const Text('Remove last person'),
            ),
          ),
        const SizedBox(height: 6),
        const Text(
          'Working hours are local to each person. Overnight shifts are not supported in this version.',
          style: TextStyle(fontSize: 13, height: 1.4, color: muted),
        ),
      ],
    );
  }

  Widget _personCard(int index, Participant person) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFD9E1DA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6EFE9),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  '${index + 1}'.padLeft(2, '0'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: green,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                person.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (index == 0)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Text(
                    'date reference',
                    style: TextStyle(fontSize: 11, color: muted),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 15),
          DropdownButtonFormField<String>(
            key: ValueKey('zone-$index-${person.zone}'),
            initialValue: person.zone,
            decoration: const InputDecoration(labelText: 'Time zone'),
            isExpanded: true,
            items: [
              for (final zone in commonZones)
                DropdownMenuItem(
                  value: zone,
                  child: Text(
                    zone.replaceAll('_', ' '),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (zone) {
              if (zone != null) {
                onChangePerson(index, person.copyWith(zone: zone));
              }
            },
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  key: ValueKey('start-$index-${person.startMinute}'),
                  initialValue: person.startMinute ~/ 60,
                  decoration: const InputDecoration(labelText: 'From'),
                  items: [
                    for (var hour = 0; hour < 24; hour++)
                      DropdownMenuItem(
                        value: hour,
                        child: Text(clockLabel(hour * 60)),
                      ),
                  ],
                  onChanged: (hour) {
                    if (hour != null) {
                      onChangePerson(
                        index,
                        person.copyWith(
                          startMinute: hour * 60,
                          endMinute: person.endMinute <= hour * 60
                              ? (hour + 1) * 60
                              : person.endMinute,
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<int>(
                  key: ValueKey('end-$index-${person.endMinute}'),
                  initialValue: person.endMinute ~/ 60,
                  decoration: const InputDecoration(labelText: 'To'),
                  items: [
                    for (var hour = 1; hour <= 24; hour++)
                      DropdownMenuItem(
                        value: hour,
                        child: Text(clockLabel(hour * 60)),
                      ),
                  ],
                  onChanged: (hour) {
                    if (hour != null) {
                      onChangePerson(
                        index,
                        person.copyWith(
                          startMinute: person.startMinute >= hour * 60
                              ? (hour - 1) * 60
                              : person.startMinute,
                          endMinute: hour * 60,
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _resultsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Shared windows',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        if (windows.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFE8EEE8),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.event_busy_outlined, color: green, size: 30),
                SizedBox(height: 14),
                Text(
                  'No shared time on this date',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 6),
                Text(
                  'Try a shorter meeting, wider working hours, or another date.',
                  style: TextStyle(color: muted, height: 1.4),
                ),
              ],
            ),
          )
        else
          for (var index = 0; index < windows.length; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: 11),
              child: _windowCard(index, windows[index]),
            ),
        const SizedBox(height: 6),
        const Text(
          'The date uses the first person’s zone. An invite starts at the beginning of a shown window.',
          style: TextStyle(color: muted, fontSize: 13, height: 1.4),
        ),
      ],
    );
  }

  Widget _windowCard(int index, MeetingWindow window) {
    final first = index == 0;
    final reference = people.first.zone;
    final start = localLabel(window.startUtc, reference);
    final end = localLabel(window.endUtc, reference);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        color: first ? const Color(0xFF183B34) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: first ? null : Border.all(color: const Color(0xFFD9E1DA)),
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: first ? Colors.white : ink),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              first ? 'EARLIEST MATCH' : 'ALSO AVAILABLE',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1.3,
                fontWeight: FontWeight.w800,
                color: first ? const Color(0xFF9BD7C4) : green,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${start.split('  ').first} to ${end.split('  ').first}',
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            Text(
              '${window.length.inMinutes} minutes available in $reference',
              style: TextStyle(
                fontSize: 12,
                color: first ? const Color(0xFFC4D8CE) : muted,
              ),
            ),
            const SizedBox(height: 18),
            for (final person in people)
              Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 102,
                      child: Text(
                        person.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${localLabel(window.startUtc, person.zone)} to ${localLabel(window.endUtc, person.zone)}',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: first ? const Color(0xFFD8E8DD) : muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: () => onShare(window),
              icon: const Icon(Icons.ios_share_outlined, size: 18),
              label: Text('Share $minutes min invite'),
              style: FilledButton.styleFrom(
                backgroundColor: first ? const Color(0xFFBCE5D3) : green,
                foregroundColor: first ? const Color(0xFF103A31) : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
