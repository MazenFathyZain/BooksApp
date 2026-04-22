import 'package:flutter/material.dart';

import '../../main.dart';

class AppDropdown extends StatelessWidget {
final dynamic attribute;
final Map<int, String?>? selectedValues;
final void Function(String?)? onChanged;

  const AppDropdown({
    super.key,
    this.attribute,
    this.selectedValues,
    this.onChanged
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(attribute.attributeName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        DropdownButtonFormField<String>(
          value: selectedValues![attribute.id],
          hint: Text('Select ${attribute.attributeName}'),
          isExpanded: true,
          dropdownColor: Colors.white,
          decoration: const InputDecoration(
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blue, width: 2),
            ),
            border: OutlineInputBorder(),
          ),
          items: attribute.listValues.map<DropdownMenuItem<String>>((item) {
            return DropdownMenuItem<String>(
              value: item.code,
              child: Text(item.value),
            );
          }).toList(),
          onChanged: onChanged,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
