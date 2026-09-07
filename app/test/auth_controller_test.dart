import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snap_here/src/features/auth/application/auth_controller.dart';
import 'package:snap_here/src/features/auth/data/fake_auth_repository.dart';
import 'package:snap_here/src/features/auth/data/google_identity_client.dart';
import 'package:snap_here/src/features/auth/data/session_store.dart';
import 'package:snap_here/src/features/auth/domain/auth_models.dart';
import 'package:snap_here/src/features/auth/domain/auth_repository.dart';

class _FailedIdentity extends FakeGoogleIdentityClient {
  const _FailedIdentity({required this.cancelled});
  final bool cancelled;
  @override
  Future<GoogleIdentityCredential> signIn() async =>
      throw AuthFailure('인증 실패', isCancellation: cancelled);
}

void main() {
  for (final cancelled in [true, false]) {
    test(
      'guest session survives Google ${cancelled ? 'cancellation' : 'failure'}',
      () async {
        final store = MemorySessionStore();
        await store.write(const AuthSession.guest());
        final container = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
            googleIdentityClientProvider.overrideWithValue(
              _FailedIdentity(cancelled: cancelled),
            ),
            sessionStoreProvider.overrideWithValue(store),
          ],
        );
        addTearDown(container.dispose);
        await container.read(authControllerProvider.future);
        final completed = await container
            .read(authControllerProvider.notifier)
            .signInWithGoogle();
        expect(completed, isFalse);
        expect(container.read(authControllerProvider).value?.isGuest, true);
        expect(container.read(authControllerProvider).hasError, !cancelled);
        expect((await store.read())?.isGuest, true);
      },
    );
  }
  test(
    'Google sign-in and profile completion persist an active session',
    () async {
      final store = MemorySessionStore();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          googleIdentityClientProvider.overrideWithValue(
            const FakeGoogleIdentityClient(),
          ),
          sessionStoreProvider.overrideWithValue(store),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authControllerProvider.future);
      final controller = container.read(authControllerProvider.notifier);

      expect(await controller.signInWithGoogle(), isTrue);
      expect(
        container.read(authControllerProvider).value?.user?.needsProfileSetup,
        isTrue,
      );

      await controller.completeProfile(
        ProfileSubmission(
          nickname: '여행토끼',
          bio: null,
          consents: ConsentRecord(
            termsVersion: 'terms-1',
            privacyVersion: 'privacy-1',
            marketingAccepted: false,
            acceptedAt: DateTime.utc(2026, 9, 1),
          ),
        ),
      );

      final active = container.read(authControllerProvider).requireValue;
      expect(active?.user?.needsProfileSetup, isFalse);
      expect(active?.user?.nickname, '여행토끼');
      expect((await store.read())?.accessToken, active?.accessToken);

      await controller.deleteAccount(contentAction: 'KEEP_ANONYMIZED');
      expect(container.read(authControllerProvider).value, isNull);
      expect(await store.read(), isNull);
    },
  );
}
