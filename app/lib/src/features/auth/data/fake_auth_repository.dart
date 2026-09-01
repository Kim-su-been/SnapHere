import 'package:snap_here/src/features/auth/domain/auth_models.dart';
import 'package:snap_here/src/features/auth/domain/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  AuthUser? _registeredUser;

  @override
  Future<AuthSession> exchangeGoogleCredential(
    GoogleIdentityCredential credential,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    final user =
        _registeredUser ??
        AuthUser(
          id: credential.subject,
          email: credential.email,
          displayName: credential.displayName,
          photoUrl: credential.photoUrl,
          needsProfileSetup: true,
        );
    return AuthSession.authenticated(
      accessToken: 'fake-access-token-${credential.subject}',
      refreshToken: 'fake-refresh-token-${credential.subject}',
      user: user,
    );
  }

  @override
  Future<AuthSession> completeProfile({
    required String accessToken,
    required ProfileSubmission submission,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    final current = _registeredUser;
    _registeredUser = AuthUser(
      id: current?.id ?? 'google-demo-user',
      email: current?.email ?? 'traveler@example.com',
      displayName: current?.displayName,
      photoUrl: current?.photoUrl,
      nickname: submission.nickname,
      bio: submission.bio,
      needsProfileSetup: false,
    );
    return AuthSession.authenticated(
      accessToken: accessToken,
      refreshToken: 'fake-refresh-token-${_registeredUser!.id}',
      user: _registeredUser!,
    );
  }

  @override
  Future<AuthSession> refreshSession(String refreshToken) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final user = _registeredUser;
    if (user == null) {
      throw const AuthFailure('저장된 데모 세션이 만료되었습니다.');
    }
    return AuthSession.authenticated(
      accessToken: 'refreshed-fake-access-token',
      refreshToken: refreshToken,
      user: user,
    );
  }

  @override
  Future<void> signOut(String accessToken) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }

  @override
  Future<void> deleteAccount(String accessToken) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _registeredUser = null;
  }
}

class FakeLegalDocumentRepository implements LegalDocumentRepository {
  @override
  Future<LegalDocument> fetch(LegalDocumentType type) async {
    return _documents[type]!;
  }

  static final Map<LegalDocumentType, LegalDocument> _documents = {
    LegalDocumentType.terms: LegalDocument(
      type: LegalDocumentType.terms,
      title: '서비스 이용약관',
      version: 'mock-1.0',
      effectiveDate: DateTime(2026, 9, 1),
      sections: const [
        LegalSection(
          heading: '제1조 목적',
          body: '이 약관은 SnapHere가 제공하는 관광 사진 커뮤니티 서비스의 이용 조건과 회원의 권리·의무를 정합니다.',
        ),
        LegalSection(
          heading: '제2조 계정과 서비스 이용',
          body: '회원은 정확한 정보를 제공하고 계정을 안전하게 관리해야 합니다. 타인의 계정을 이용하거나 서비스 운영을 방해해서는 안 됩니다.',
        ),
        LegalSection(
          heading: '제3조 이용자 게시물',
          body: '회원은 자신이 게시한 사진과 글에 필요한 권리를 보유해야 하며, 불법·유해·권리 침해 콘텐츠를 게시해서는 안 됩니다.',
        ),
        LegalSection(
          heading: '제4조 신고와 이용 제한',
          body: '운영자는 신고된 콘텐츠를 검토하고 약관을 위반한 게시물 삭제, 노출 제한 또는 계정 이용 제한 조치를 할 수 있습니다.',
        ),
        LegalSection(
          heading: '제5조 탈퇴',
          body: '회원은 앱의 계정 설정에서 탈퇴를 요청할 수 있으며, 법령상 보존 의무가 있는 정보를 제외한 계정과 관련 데이터를 삭제할 수 있습니다.',
        ),
      ],
    ),
    LegalDocumentType.privacyConsent: LegalDocument(
      type: LegalDocumentType.privacyConsent,
      title: '개인정보 수집·이용 동의',
      version: 'mock-1.0',
      effectiveDate: DateTime(2026, 9, 1),
      sections: const [
        LegalSection(
          heading: '수집 항목',
          body: 'Google 계정 식별자, 이메일 주소, 닉네임, 선택 입력한 소개글과 프로필 이미지',
        ),
        LegalSection(
          heading: '수집·이용 목적',
          body: '회원 식별, 로그인과 계정 관리, 프로필 및 커뮤니티 기능 제공, 부정 이용 방지와 고객 문의 처리',
        ),
        LegalSection(
          heading: '보유 및 이용 기간',
          body: '회원 탈퇴 시까지 보유하며, 관계 법령에 따라 보존할 필요가 있는 정보는 해당 기간 동안 별도로 보관합니다.',
        ),
        LegalSection(
          heading: '동의 거부 권리',
          body: '필수 개인정보 수집·이용 동의를 거부할 수 있으나, 거부하면 회원 계정 기반 기능을 이용할 수 없습니다.',
        ),
      ],
    ),
    LegalDocumentType.privacyPolicy: LegalDocument(
      type: LegalDocumentType.privacyPolicy,
      title: '개인정보 처리방침',
      version: 'mock-1.0',
      effectiveDate: DateTime(2026, 9, 1),
      sections: const [
        LegalSection(
          heading: '개인정보의 처리',
          body: 'SnapHere는 회원 관리와 서비스 제공에 필요한 최소한의 개인정보를 처리합니다. 실제 출시 문서는 운영 주체, 문의처, 위탁사와 국외 이전 현황을 포함해 API에서 제공해야 합니다.',
        ),
        LegalSection(
          heading: '정보주체의 권리',
          body: '이용자는 개인정보 열람, 정정, 삭제, 처리 정지와 동의 철회를 요청할 수 있습니다.',
        ),
        LegalSection(
          heading: '파기와 안전성 확보',
          body: '보유 목적이 달성된 개인정보는 지체 없이 파기하며, 접근 통제와 전송·저장 구간 보호 등 안전성 확보 조치를 적용합니다.',
        ),
        LegalSection(
          heading: '출시 전 교체 필요',
          body: '현재 문서는 개발용 더미입니다. 실제 운영자 정보와 데이터 처리 현황을 반영한 검토 완료 문서로 반드시 교체해야 합니다.',
        ),
      ],
    ),
    LegalDocumentType.marketing: LegalDocument(
      type: LegalDocumentType.marketing,
      title: '마케팅 정보 수신 동의',
      version: 'mock-1.0',
      effectiveDate: DateTime(2026, 9, 1),
      sections: const [
        LegalSection(
          heading: '수신 내용과 방법',
          body: '관광 행사, 챌린지, 신규 기능과 혜택 정보를 앱 푸시 또는 이메일로 안내할 수 있습니다.',
        ),
        LegalSection(
          heading: '선택 동의와 철회',
          body: '동의하지 않아도 서비스 이용에 제한이 없으며, 앱 설정에서 언제든 수신 동의를 철회할 수 있습니다.',
        ),
      ],
    ),
  };
}
