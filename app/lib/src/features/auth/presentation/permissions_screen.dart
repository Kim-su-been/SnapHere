import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PermissionsScreen extends StatelessWidget {
  const PermissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('앱 권한 안내')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const _PermissionTile(
                icon: Icons.location_on_outlined,
                title: '위치',
                description: '사진과 가까운 관광지를 찾는 데 필요해요.',
                required: true,
              ),
              const _PermissionTile(
                icon: Icons.photo_library_outlined,
                title: '사진',
                description: '여행 사진을 선택하고 업로드하는 데 필요해요.',
                required: true,
              ),
              const _PermissionTile(
                icon: Icons.notifications_outlined,
                title: '알림',
                description: '추천, 댓글, 랭킹 소식을 알려드려요.',
                required: false,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('확인하고 홈으로'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.required,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text('$title · ${required ? '필수' : '선택'}'),
      subtitle: Text(description),
    );
  }
}
