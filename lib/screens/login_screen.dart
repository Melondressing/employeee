import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/auth_session.dart';
import '../services/auth_service.dart';
import '../theme/colors.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_card.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  static const route = '/login';

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);
    final canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                shrinkWrap: true,
                children: [
                  if (canPop)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton.filledTonal(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ),
                  const SizedBox(height: 8),
                  const _BrandMark(),
                  const SizedBox(height: 10),
                  const Text(
                    'employeeee',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.deepInk,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.9,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    session == null ? '내 급여 작업공간으로 들어가기' : '계정 상태',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.deepInk,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    session == null
                        ? '지금은 기기 저장 모드로 안전하게 이어가고,\n다음 단계에서 Cloudflare D1 동기화를 붙일 수 있게 준비해뒀어요.'
                        : '${session.displayName} workspace\n${session.email}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.softBlack,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (session == null) _loginForm() else _sessionCard(session),
                  const SizedBox(height: 14),
                  _syncPlanCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _loginForm() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.deepInk,
              side: const BorderSide(color: AppColors.inputStroke),
              padding: const EdgeInsets.symmetric(vertical: 13),
              backgroundColor: AppColors.cardSurfaceStrong,
            ),
            onPressed: _showGoogleNotice,
            icon:
                const Text('G', style: TextStyle(fontWeight: FontWeight.w900)),
            label: const Text('Google 로그인 연결 예정'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
              labelText: '아이디 / 이메일',
              prefixIcon: Icon(Icons.alternate_email),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _password,
            obscureText: _obscure,
            autofillHints: const [AutofillHints.password],
            decoration: InputDecoration(
              labelText: '비밀번호',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.lavender,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: _signInEmailPreview,
            child: const Text(
              '이메일 방식으로 시작',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () =>
                ref.read(authSessionProvider.notifier).continueLocally(),
            child: const Text('로그인 없이 기기 저장으로 계속'),
          ),
          const SizedBox(height: 4),
          const Text(
            '현재 이메일/비밀번호 화면은 DB 연결 전 준비 단계입니다. 실제 비밀번호 검증은 Worker API 연결 후 활성화돼요.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.softBlack, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _sessionCard(AuthSession session) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PlanRow(
            icon: Icons.person_outline,
            title: session.isLocalOnly ? '기기 저장 모드' : '클라우드 동기화',
            subtitle: session.isLocalOnly
                ? '이 기기/브라우저에만 저장됩니다.'
                : 'D1 데이터베이스와 동기화됩니다.',
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => ref.read(authSessionProvider.notifier).signOut(),
            icon: const Icon(Icons.logout),
            label: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }

  Widget _syncPlanCard() {
    return const GlassCard(
      padding: EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DB 연결 예정 구조',
            style: TextStyle(
              color: AppColors.deepInk,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 10),
          _PlanRow(
            icon: Icons.cloud_outlined,
            title: 'Cloudflare Worker API',
            subtitle: 'Flutter 앱은 API만 호출하고, DB 토큰은 서버에 숨깁니다.',
          ),
          _PlanRow(
            icon: Icons.storage_outlined,
            title: 'D1 tables',
            subtitle: 'users, sessions, pay_rules, work_entries로 분리합니다.',
          ),
          _PlanRow(
            icon: Icons.sync_outlined,
            title: '기존 기록 이전',
            subtitle: '첫 로그인 때 로컬 근무기록을 사용자 DB로 업로드합니다.',
          ),
        ],
      ),
    );
  }

  void _showGoogleNotice() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Google OAuth는 Worker/D1 인증 API 연결 단계에서 활성화할게요.'),
      ),
    );
  }

  Future<void> _signInEmailPreview() async {
    final email = _email.text.trim();
    final password = _password.text.trim();
    if (!email.contains('@') || password.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이메일과 4자 이상 비밀번호를 입력해주세요.')),
      );
      return;
    }
    await ref.read(authSessionProvider.notifier).signInWithEmail(
          email: email,
          password: password,
        );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 104,
        height: 104,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF4EA), Color(0xFFD4E4F7), Color(0xFFE6DDF5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: AppColors.inputStroke),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowTint,
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: const Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: 23,
              top: 26,
              child: Icon(Icons.receipt_long, size: 42),
            ),
            Positioned(
              right: 22,
              bottom: 23,
              child: Icon(Icons.event_available, size: 42),
            ),
            Positioned(
              right: 18,
              top: 18,
              child: Icon(Icons.attach_money, size: 30),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.cardSurfaceAlt,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: AppColors.inputStroke),
            ),
            child: Icon(icon, size: 18, color: AppColors.deepInk),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.deepInk,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style:
                      const TextStyle(color: AppColors.softBlack, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
