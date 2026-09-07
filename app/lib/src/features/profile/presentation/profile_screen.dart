import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snap_here/src/features/auth/application/auth_controller.dart';
import 'package:snap_here/src/features/profile/application/profile_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.value?.user;
    final snapshot = ref.watch(profileSnapshotProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('마이')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundImage: user?.photoUrl == null
                  ? null
                  : NetworkImage(user!.photoUrl!),
              child: user?.photoUrl == null
                  ? const Icon(Icons.person_outline)
                  : null,
            ),
            title: Text(user?.nickname ?? user?.displayName ?? '회원'),
            subtitle: Text(user?.email ?? ''),
          ),
          snapshot.when(
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.cloud_off_outlined),
              title: const Text('프로필 통계를 불러오지 못했어요'),
              subtitle: Text('$error'),
              trailing: IconButton(
                onPressed: () => ref.invalidate(profileSnapshotProvider),
                icon: const Icon(Icons.refresh),
              ),
            ),
            data: (data) => data == null
                ? const SizedBox.shrink()
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _ProfileMetric('게시글', data.stats.postCount),
                      _ProfileMetric('팔로워', data.stats.followerCount),
                      _ProfileMetric('팔로잉', data.stats.followingCount),
                      _ProfileMetric('뱃지', data.stats.badgeCount),
                    ],
                  ),
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
          const Divider(height: 40),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('개인정보 처리방침'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/legal/privacy-policy'),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.logout),
            title: const Text('로그아웃'),
            enabled: !auth.isLoading,
            onTap: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
            title: const Text(
              '계정 삭제',
              style: TextStyle(color: Colors.redAccent),
            ),
            enabled: !auth.isLoading,
            onTap: () => _confirmAccountDeletion(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAccountDeletion(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final contentAction = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('계정을 삭제할까요?'),
        content: const Text('30일 복구 유예 후 게시물을 익명으로 보존할지, 모두 삭제할지 선택해 주세요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'KEEP_ANONYMIZED'),
            child: const Text('익명으로 보존'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, 'DELETE_ALL'),
            child: const Text('게시물도 삭제'),
          ),
        ],
      ),
    );
    if (contentAction == null || !context.mounted) return;
    try {
      await ref
          .read(authControllerProvider.notifier)
          .deleteAccount(contentAction: contentAction);
    } on Object catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }
}

class _ProfileMetric extends StatelessWidget {
  const _ProfileMetric(this.label, this.value);

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text('$value', style: Theme.of(context).textTheme.titleLarge),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}
