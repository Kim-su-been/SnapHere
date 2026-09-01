import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:snap_here/src/features/auth/presentation/auth_ui.dart';

class LoginRequiredScreen extends StatelessWidget {
  const LoginRequiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AuthTopBar(title: '전북 게시글', onBack: () => context.go('/home')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                _PostPreview(title: '한옥마을 야경 최고!', likes: 128),
                SizedBox(height: 12),
                _PostPreview(title: '가을 내장산 단풍 구경하고 왔어요', likes: 85),
              ],
            ),
          ),
          Container(color: const Color(0x660F1720)),
          Center(
            child: Container(
              width: 340,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x40000000),
                    blurRadius: 28,
                    offset: Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '로그인이 필요해요',
                          style: TextStyle(
                            color: AuthColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go('/home'),
                        child: const Icon(
                          Icons.cancel_outlined,
                          size: 20,
                          color: AuthColors.iconMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '좋아요, 팔로우, 댓글, 업로드 기능을 이용하려면 로그인해 주세요.',
                    style: TextStyle(
                      color: AuthColors.textSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 46,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AuthColors.textPrimary,
                        side: const BorderSide(color: AuthColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onPressed: () => context.go('/login'),
                      icon: const Icon(Icons.login, size: 18),
                      label: const Text('로그인하러 가기'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: AuthTextLink(
                      label: '취소',
                      onTap: () => context.go('/home'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PostPreview extends StatelessWidget {
  const _PostPreview({required this.title, required this.likes});
  final String title;
  final int likes;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 114,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AuthColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: AuthColors.canvas,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.image_outlined,
              color: AuthColors.iconMuted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AuthColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: Color(0xFF43C3DF),
                    ),
                    SizedBox(width: 3),
                    Text(
                      '전주 한옥마을',
                      style: TextStyle(
                        color: AuthColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: AuthColors.border,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      '너구리즈',
                      style: TextStyle(
                        color: AuthColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.favorite_border,
                      size: 16,
                      color: Color(0xFFD85959),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '$likes',
                      style: const TextStyle(
                        color: AuthColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
