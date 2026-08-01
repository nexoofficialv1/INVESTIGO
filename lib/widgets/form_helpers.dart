import 'package:flutter/material.dart';

class FormHelpers {
  static Widget textField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  static Widget yesNoTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      value: value,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(value ? 'Yes — details required' : 'No'),
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }
}
