import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';

Future<TimeOfDay?> showCustomTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
}) {
  return showDialog<TimeOfDay>(
    context: context,
    builder: (context) => _CustomTimePickerDialog(initialTime: initialTime),
  );
}

class _CustomTimePickerDialog extends StatefulWidget {
  final TimeOfDay initialTime;

  const _CustomTimePickerDialog({required this.initialTime});

  @override
  State<_CustomTimePickerDialog> createState() => _CustomTimePickerDialogState();
}

class _CustomTimePickerDialogState extends State<_CustomTimePickerDialog> {
  late int _hour;
  late int _minute;
  late bool _isAm;

  late TextEditingController _hourController;
  late TextEditingController _minuteController;
  late FocusNode _hourFocus;
  late FocusNode _minuteFocus;

  @override
  void initState() {
    super.initState();
    _hour = widget.initialTime.hourOfPeriod;
    if (_hour == 0) _hour = 12;
    _minute = widget.initialTime.minute;
    _isAm = widget.initialTime.period == DayPeriod.am;

    _hourController = TextEditingController(text: _hour.toString().padLeft(2, '0'));
    _minuteController = TextEditingController(text: _minute.toString().padLeft(2, '0'));
    
    _hourFocus = FocusNode();
    _minuteFocus = FocusNode();

    _hourFocus.addListener(() {
      if (_hourFocus.hasFocus) {
        _hourController.selection = TextSelection(baseOffset: 0, extentOffset: _hourController.text.length);
      } else {
        _hourController.text = _hour.toString().padLeft(2, '0');
      }
      setState(() {});
    });

    _minuteFocus.addListener(() {
      if (_minuteFocus.hasFocus) {
        _minuteController.selection = TextSelection(baseOffset: 0, extentOffset: _minuteController.text.length);
      } else {
        _minuteController.text = _minute.toString().padLeft(2, '0');
      }
      setState(() {});
    });

    _hourController.addListener(_onHourChanged);
    _minuteController.addListener(_onMinuteChanged);
  }

  void _onHourChanged() {
    final val = int.tryParse(_hourController.text);
    if (val != null) {
      if (val >= 13 && val <= 23) {
        _hour = val - 12;
        _isAm = false;
      } else if (val == 0) {
        _hour = 12;
        _isAm = true;
      } else if (val == 12) {
        _hour = 12;
        _isAm = false;
      } else if (val >= 1 && val <= 11) {
        _hour = val;
      }
      // Trigger rebuild to update AM/PM toggle visually
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
  }

  void _onMinuteChanged() {
    final val = int.tryParse(_minuteController.text);
    if (val != null) {
      _minute = val.clamp(0, 59);
    }
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    _hourFocus.dispose();
    _minuteFocus.dispose();
    super.dispose();
  }

  void _incrementHour(int delta) {
    setState(() {
      _hour += delta;
      if (_hour > 12) _hour = 1;
      if (_hour < 1) _hour = 12;
      _hourController.text = _hour.toString().padLeft(2, '0');
      _hourController.selection = TextSelection.collapsed(offset: _hourController.text.length);
    });
  }

  void _incrementMinute(int delta) {
    setState(() {
      _minute += delta;
      if (_minute > 59) _minute = 0;
      if (_minute < 0) _minute = 59;
      _minuteController.text = _minute.toString().padLeft(2, '0');
      _minuteController.selection = TextSelection.collapsed(offset: _minuteController.text.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: theme.cardColor,
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select time',
              style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color),
            ),
            const Gap(32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildNumberField(
                  controller: _hourController,
                  focusNode: _hourFocus,
                  onScroll: (delta) => _incrementHour(delta > 0 ? -1 : 1), // Scroll down = +delta = decrease value, scroll up = -delta = increase
                  theme: theme,
                  label: 'Hour',
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    ':',
                    style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
                  ),
                ),
                _buildNumberField(
                  controller: _minuteController,
                  focusNode: _minuteFocus,
                  onScroll: (delta) => _incrementMinute(delta > 0 ? -1 : 1),
                  theme: theme,
                  label: 'Minute',
                ),
                const Gap(16),
                _buildAmPmToggle(theme),
              ],
            ),
            const Gap(32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(foregroundColor: theme.textTheme.bodyMedium?.color),
                  child: const Text('Cancel'),
                ),
                const Gap(8),
                TextButton(
                  onPressed: () {
                    int finalHour = _hour;
                    if (_isAm && finalHour == 12) finalHour = 0;
                    if (!_isAm && finalHour < 12) finalHour += 12;
                    Navigator.pop(context, TimeOfDay(hour: finalHour, minute: _minute));
                  },
                  style: TextButton.styleFrom(foregroundColor: theme.primaryColor),
                  child: const Text('OK'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required Function(double) onScroll,
    required ThemeData theme,
    required String label,
  }) {
    return Column(
      children: [
        Listener(
          onPointerSignal: (pointerSignal) {
            if (pointerSignal is PointerScrollEvent) {
              onScroll(pointerSignal.scrollDelta.dy);
            }
          },
          child: Container(
            width: 96,
            height: 80,
            decoration: BoxDecoration(
              color: focusNode.hasFocus ? theme.primaryColor.withValues(alpha: 0.1) : theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: focusNode.hasFocus ? theme.primaryColor : theme.dividerColor.withValues(alpha: 0.1),
                width: 2,
              ),
            ),
            alignment: Alignment.center,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
              decoration: const InputDecoration(border: InputBorder.none, counterText: ''),
              maxLength: 2,
              onTap: () => controller.selection = TextSelection(baseOffset: 0, extentOffset: controller.text.length),
            ),
          ),
        ),
        const Gap(8),
        Text(label, style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color)),
      ],
    );
  }

  Widget _buildAmPmToggle(ThemeData theme) {
    return Container(
      width: 52,
      height: 80,
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isAm = true),
              child: Container(
                decoration: BoxDecoration(
                  color: _isAm ? theme.primaryColor.withValues(alpha: 0.2) : Colors.transparent,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                ),
                alignment: Alignment.center,
                child: Text('AM', style: TextStyle(fontWeight: FontWeight.bold, color: _isAm ? theme.primaryColor : theme.textTheme.bodyMedium?.color)),
              ),
            ),
          ),
          Container(height: 1, color: theme.dividerColor.withValues(alpha: 0.3)),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isAm = false),
              child: Container(
                decoration: BoxDecoration(
                  color: !_isAm ? theme.primaryColor.withValues(alpha: 0.2) : Colors.transparent,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(11)),
                ),
                alignment: Alignment.center,
                child: Text('PM', style: TextStyle(fontWeight: FontWeight.bold, color: !_isAm ? theme.primaryColor : theme.textTheme.bodyMedium?.color)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
