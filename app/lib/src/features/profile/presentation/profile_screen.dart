import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snap_here/src/features/auth/application/auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.value?.user;

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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('계정을 삭제할까요?'),
        content: const Text(
          '계정과 관련 개인정보 및 게시물이 삭제됩니다. 법령상 보관해야 하는 정보는 해당 기간 동안 별도로 보관될 수 있습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('계정 삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(authControllerProvider.notifier).deleteAccount();
    } on Object catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }
}
