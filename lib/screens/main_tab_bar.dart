import 'package:flutter/material.dart';

class MainTabBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabSelected;

  const MainTabBar({
    Key? key,
    required this.selectedIndex,
    required this.onTabSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildTabItem(context, 0, 'assets/main/tab/travel.png', '트립프렌즈'),
          _buildTabItem(context, 1, 'assets/main/tab/triprace.png', '트립레이스'),
          _buildTabItem(context, 2, 'assets/main/tab/job.png', '워크메이트'),
          _buildTabItem(context, 3, 'assets/main/tab/talk.png', '실시간톡톡'),
        ],
      ),
    );
  }

  Widget _buildTabItem(BuildContext context, int index, String iconPath, String label) {
    final isSelected = selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTabSelected(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                iconPath,
                width: 40,
                height: 40,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF5963D0) : const Color(0xFF1B1C1F),
                  fontSize: 13,
                  fontFamily: 'Spoqa Han Sans Neo',
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                ),
                maxLines: 2,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}