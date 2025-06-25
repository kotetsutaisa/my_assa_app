import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateDropdownPicker extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const DateDropdownPicker({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final formatted = DateFormat('yyyy年MM月dd日', 'ja_JP').format(selectedDate);

    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          locale: const Locale('ja', 'JP'),
        );
        if (picked != null) onDateSelected(picked);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(formatted, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(width: 4),
          const Icon(Icons.calendar_today, size: 18),
        ],
      ),
    );
  }
}


