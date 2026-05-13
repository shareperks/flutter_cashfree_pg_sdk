import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:soui/theme.dart';

class CategorySearchSortBar extends StatelessWidget {
  final TextEditingController controller;
  final String sortBy; // "a-z" | "z-a"
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onToggleSort;

  const CategorySearchSortBar({
    super.key,
    required this.controller,
    required this.sortBy,
    required this.onSearchChanged,
    required this.onToggleSort,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 5,
      children: [
        SizedBox(
          width: MediaQuery.of(context).size.width - 88,
          child: TextField(
            controller: controller,
            onChanged: onSearchChanged,
            decoration: const InputDecoration(
              prefixIcon: Icon(HugeIconsSolid.search01),
              hint: Text("Search Perks"),
            ),
          ),
        ),
        GestureDetector(
          onTap: onToggleSort,
          child: Container(
            alignment: Alignment.center,
            width: 44,
            child: Center(
              child: Icon(
                sortBy == 'a-z'
                    ? HugeIconsSolid.sortingAZ02
                    : HugeIconsSolid.sortingZA01,
                color: AppColors.neutral700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
