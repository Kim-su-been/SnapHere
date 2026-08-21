import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RankingsScreen extends StatelessWidget {
  const RankingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final regions = ['대전', '서울', '제주', '부산', '강원'];

    return Scaffold(
      appBar: AppBar(title: const Text('랭킹')),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        itemCount: regions.length,
        separatorBuilder: (_, _) => const Divider(),
        itemBuilder: (context, index) => ListTile(
          leading: CircleAvatar(child: Text('${index + 1}')),
          title: Text('${regions[index]} 인기 사진'),
          subtitle: const Text('이번 주 추천 기준'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/photos/rank-${index + 1}'),
        ),
      ),
    );
  }
}
