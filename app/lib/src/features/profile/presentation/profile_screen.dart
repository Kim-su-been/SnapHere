import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snap_here/src/app/theme/app_tokens.dart';
import 'package:snap_here/src/core/ui/design_icon.dart';
import 'package:snap_here/src/core/ui/paged_sliver.dart';
import 'package:snap_here/src/core/ui/remote_image.dart';
import 'package:snap_here/src/features/auth/application/auth_controller.dart';
import 'package:snap_here/src/features/profile/application/profile_providers.dart';
import 'package:snap_here/src/features/profile/domain/profile_models.dart';
import 'package:snap_here/src/features/profile/presentation/profile_settings_sheet.dart';

/// Figma 92:1932 / 92:2173 / 92:2340.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({this.userId, super.key});
  final String? userId;
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int _revision = 0;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authControllerProvider).value;
    final own = widget.userId == null || widget.userId == session?.user?.id;
    final AsyncValue<ProfileSnapshot?> profile = own
        ? ref.watch(profileSnapshotProvider)
        : ref.watch(publicProfileProvider(widget.userId!));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(own ? '마이' : '프로필'),
        leading: own ? null : const DesignBackButton(),
        toolbarHeight: 48,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        actions: own
            ? [
                IconButton(
                  tooltip: '알림',
                  onPressed: () => context.push('/notifications'),
                  icon: const DesignIcon('bell', size: 20),
                ),
                IconButton(
                  tooltip: '설정',
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    showDragHandle: true,
                    builder: (_) => const ProfileSettingsSheet(),
                  ),
                  icon: const DesignIcon('settings', size: 20),
                ),
              ]
            : null,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => _revision++);
          if (own) {
            ref.invalidate(profileSnapshotProvider);
            await ref
                .read(profileSnapshotProvider.future)
                .then<void>((_) {}, onError: (Object _, StackTrace _) {});
          } else {
            ref.invalidate(publicProfileProvider(widget.userId!));
            await ref
                .read(publicProfileProvider(widget.userId!).future)
                .then<void>((_) {}, onError: (Object _, StackTrace _) {});
          }
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: profile.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: RetryMessage(
                    message: '프로필을 불러오지 못했어요',
                    onRetry: () {
                      if (own) {
                        ref.invalidate(profileSnapshotProvider);
                      } else {
                        ref.invalidate(publicProfileProvider(widget.userId!));
                      }
                    },
                  ),
                ),
                data: (data) => data == null
                    ? const SizedBox.shrink()
                    : _ProfileHeader(profile: data, own: own),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile, required this.own});
  final ProfileSnapshot profile;
  final bool own;
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Colors.white,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ProfileAvatar(url: profile.imageUrl),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.nickname,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.bio?.isNotEmpty == true
                          ? profile.bio!
                          : '아직 소개가 없어요',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
