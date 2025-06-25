import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void showTimePickerModal({
  required BuildContext context,
  required DateTime initialDateTime,
  required Function(DateTime) onTimePicked,
}) {
  showCupertinoModalPopup(
    context: context,
    builder: (_) => Container(
      height: 300,
      color: Colors.white,
      child: Column(
        children: [
          // ドラムロール式の時間ピッカー
          Expanded(
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.time, // 👈 時間のみ
              initialDateTime: initialDateTime,
              use24hFormat: true, // 24時間表記
              onDateTimeChanged: onTimePicked,
            ),
          ),
        ],
      ),
    ),
  );
}
