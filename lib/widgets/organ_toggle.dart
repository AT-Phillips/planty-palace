import 'package:flutter/material.dart';
import 'package:planty_palace/styles/app_theme.dart';

class OrganToggle extends StatelessWidget {
  final String selectedOrgan;
  final ValueChanged<String> onChanged;

  const OrganToggle({
    Key? key,
    required this.selectedOrgan,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: ['leaf', 'flower'].map((organ) {
        final isSelected = selectedOrgan == organ;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: ChoiceChip(
            label: Text(organ[0].toUpperCase() + organ.substring(1)),
            selected: isSelected,
            onSelected: (_) => onChanged(organ),
            selectedColor: AppTheme.primaryColor,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : AppTheme.primaryColor,
            ),
            backgroundColor: Colors.grey[200],
          ),
        );
      }).toList(),
    );
  }
}
