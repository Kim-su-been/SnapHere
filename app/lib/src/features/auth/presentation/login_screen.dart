import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sign_in_button/sign_in_button.dart';
import 'package:snap_here/src/features/auth/application/auth_controller.dart';
import 'package:snap_here/src/features/auth/presentation/auth_ui.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final errorMessage = auth.hasError ? auth.error.toString() : null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 120, 24, 40),
          child: Column(
            children: [
              const AuthAppLogo(),
              const Spacer(),
              if (errorMessage != null) ...[
                _LoginError(message: errorMessage),
                const SizedBox(height: 16),
              ],
              IgnorePointer(
                ignoring: auth.isLoading,
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: SignInButton(
                    Buttons.google,
                    key: const ValueKey('google-sign-in'),
                    text: 'Google로 계속하기',
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(
                        color: AuthColors.border,
                        width: 1.5,
                      ),
                    ),
                    textStyle: const TextStyle(
                      color: AuthColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    onPressed: () => ref
                        .read(authControllerProvider.notifier)
                        .signInWithGoogle(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              AuthTextLink(
                label: '로그인 없이 둘러보기',
                onTap: auth.isLoading
                    ? () {}
                    : () => ref
                          .read(authControllerProvider.notifier)
                          .continueAsGuest(),
              ),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 4,
                children: [
                  AuthTextLink(
                    label: '서비스 이용약관',
                    onTap: () => context.push('/legal/terms'),
                  ),
                  const Text(
                    '·',
                    style: TextStyle(color: AuthColors.textSecondary),
                  ),
                  AuthTextLink(
                    label: '개인정보 처리방침',
                    onTap: () => context.push('/legal/privacy-policy'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginError extends StatelessWidget {
  const _LoginError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1F1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          message,
          style: const TextStyle(color: Color(0xFFB42318), fontSize: 13),
        ),
      ),
    );
  }
}
