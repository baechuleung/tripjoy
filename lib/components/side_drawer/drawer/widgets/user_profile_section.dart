import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../profile_update.dart';

class UserProfileSection extends StatefulWidget {
  final String? photoUrl;
  final String? nickname;
  final int? points;
  final VoidCallback onProfileUpdated;

  const UserProfileSection({
    Key? key,
    this.photoUrl,
    this.nickname,
    this.points,
    required this.onProfileUpdated,
  }) : super(key: key);

  @override
  _UserProfileSectionState createState() => _UserProfileSectionState();
}

class _UserProfileSectionState extends State<UserProfileSection> {
  @override
  Widget build(BuildContext context) {
    print('🔍 [UserProfileSection] photoUrl: ${widget.photoUrl}');
    print('🔍 [UserProfileSection] nickname: ${widget.nickname}');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[200],
              ),
              clipBehavior: Clip.hardEdge,
              child: widget.photoUrl != null && widget.photoUrl!.isNotEmpty
                  ? Image.network(
                widget.photoUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.person,
                    size: 40,
                    color: Colors.grey[400],
                  );
                },
              )
                  : Icon(
                Icons.person,
                size: 40,
                color: Colors.grey[400],
              ),
            ),
          ),
          SizedBox(height: 15),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _showProfileUpdateDialog,
                  child: Text(
                    widget.nickname ?? '여행하는길동이 님',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                SizedBox(width: 5),
                GestureDetector(
                  onTap: _showProfileUpdateDialog,
                  child: Image.asset(
                    'assets/side/name_change.png',
                    width: 18,
                    height: 18,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _showProfileUpdateDialog() async {
    await showDialog(
      context: context,
      builder: (context) => ProfileUpdateDialog(
        onProfileUpdated: widget.onProfileUpdated,
      ),
    );
  }
}