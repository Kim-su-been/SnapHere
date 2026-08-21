import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('마이')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        children: [
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(child: Icon(Icons.person_outline)),
            title: Text('여행자'),
            subtitle: Text('내 사진 0 · 저장 0'),
          ),
          const SizedBox(height: 24),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('내 사진')),
              ButtonSegment(value: 1, label: Text('저장')),
              ButtonSegment(value: 2, label: Text('활동')),
            ],
            selected: const {0},
            onSelectionChanged: (_) {},
          ),
          const SizedBox(height: 24),
          const SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('전체 번역'),
            subtitle: Text('사용자 게시글과 댓글을 선택한 언어로 표시'),
            value: false,
            onChanged: null,
          ),
        ],
      ),
    );
  }
}
