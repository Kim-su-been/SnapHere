import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snap_here/src/features/auth/application/auth_controller.dart';

class ProfileSettingsSheet extends ConsumerWidget {
  const ProfileSettingsSheet({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          const ListTile(
            title: Text('설정', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SwitchListTile(
            title: Text('전체 번역'),
            subtitle: Text('사용자 게시글과 댓글을 선택한 언어로 표시'),
            value: false,
            onChanged: null,
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('개인정보 처리방침'),
            onTap: () {
              context.pop();
              context.push('/legal/privacy-policy');
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('로그아웃'),
            enabled: !auth.isLoading,
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                await ref.read(authControllerProvider.notifier).signOut();
                if (context.mounted) context.pop();
              } on Object catch (error) {
                messenger.showSnackBar(SnackBar(content: Text('$error')));
              }
            },
          ),
          ListTile(
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
      if (context.mounted) context.pop();
    } on Object catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }
}
