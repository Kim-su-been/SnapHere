import 'package:flutter/material.dart';

class UploadScreen extends StatelessWidget {
  const UploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
        title: const Text('사진 올리기'),
        actions: [TextButton(onPressed: () {}, child: const Text('게시'))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_photo_alternate_outlined, size: 56),
                SizedBox(height: 8),
                Text('사진 선택'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.gps_fixed),
            title: Text('GPS로 관광지 자동 매칭'),
            subtitle: Text('위치 권한 연동 후 주변 관광지 후보를 보여줍니다.'),
          ),
          const TextField(
            maxLines: 4,
            decoration: InputDecoration(hintText: '이 장소의 분위기와 사진 팁을 남겨보세요.'),
          ),
        ],
      ),
    );
  }
}
