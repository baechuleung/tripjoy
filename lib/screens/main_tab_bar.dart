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
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 10),
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
          _buildTabItem(context, 1, 'assets/main/tab/job.png', '위크메이트'),
          _buildTabItem(context, 2, 'assets/main/tab/talk.png', '현지톡톡'),
          _buildTabItem(context, 3, 'assets/main/tab/info.png', '실시간정보'),
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
                width: 36,
                height: 36,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF3182F6) : const Color(0xFF1B1C1F),
                  fontSize: 13,
                  fontFamily: 'Spoqa Han Sans Neo',
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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