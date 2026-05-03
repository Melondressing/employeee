import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/auth_session.dart';
import '../services/auth_service.dart';
import '../services/cloud_sync_coordinator.dart';
import '../theme/colors.dart';
import '../widgets/app_background.dart';
import '../widgets/app_page.dart';
import '../widgets/glass_card.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  static const route = '/login';

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _username = TextEditingController();
  final _displayName = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _isRegister = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _username.dispose();
    _displayName.dispose();
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
          child: AppPage(
            maxWidth: AppPage.loginMaxWidth,
            fillHeight: true,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: ListView(
              primary: true,
              padding: EdgeInsets.zero,
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
                      ? 'Budget-Lee와 같은 계정으로 로그인하면\n나중에 급여 → 가계부 연동까지 자연스럽게 이어집니다.'
                      : '${session.displayName} workspace\n${session.username.isEmpty ? session.email : session.username}',
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
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('로그인')),
              ButtonSegment(value: true, label: Text('회원가입')),
            ],
            selected: {_isRegister},
            onSelectionChanged: _isSubmitting
                ? null
                : (selection) => setState(() => _isRegister = selection.first),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _username,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.username],
            decoration: const InputDecoration(
              labelText: 'Budget-Lee 아이디',
              prefixIcon: Icon(Icons.alternate_email),
            ),
          ),
          if (_isRegister) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _displayName,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              decoration: const InputDecoration(
                labelText: '이름 / 표시 이름',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),
          ],
          const SizedBox(height: 10),
          TextField(
            controller: _password,
            obscureText: _obscure,
            keyboardType: TextInputType.number,
            maxLength: 4,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            autofillHints: const [AutofillHints.password],
            decoration: InputDecoration(
              labelText: '비밀번호 4자리',
              counterText: '',
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
            onPressed: _isSubmitting ? null : _submitSharedAccount,
            child: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    _isRegister ? '공통 계정 만들기' : '공통 계정으로 로그인',
                    style: const TextStyle(fontWeight: FontWeight.w800),
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
            'Budget-Lee와 같은 인증 API를 사용합니다. 같은 아이디로 두 앱을 함께 쓸 수 있어요.',
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
            title: session.isLocalOnly ? '기기 저장 모드' : '공통 계정 연결됨',
            subtitle: session.isLocalOnly
                ? '이 기기/브라우저에만 저장됩니다.'
                : 'Budget-Lee Auth API를 통해 같은 사용자로 인식됩니다.',
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
            '공통 계정 구조',
            style: TextStyle(
              color: AppColors.deepInk,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 10),
          _PlanRow(
            icon: Icons.cloud_outlined,
            title: 'Budget-Lee Auth API',
            subtitle: '회원가입/로그인은 같은 users 테이블을 사용합니다.',
          ),
          _PlanRow(
            icon: Icons.storage_outlined,
            title: 'employeeee 데이터 분리 예정',
            subtitle: 'pay_rules, work_entries는 같은 user_id 아래 별도 테이블로 붙입니다.',
          ),
          _PlanRow(
            icon: Icons.sync_outlined,
            title: 'Budget 앱 연동',
            subtitle: '급여 확정 시 지급일 기준 income 거래로 보낼 수 있게 연결합니다.',
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

  Future<void> _submitSharedAccount() async {
    final username = _username.text.trim();
    final password = _password.text.trim();
    final displayName = _displayName.text.trim();

    if (username.isEmpty || password.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('아이디와 숫자 4자리 비밀번호를 입력해주세요.')),
      );
      return;
    }
    if (_isRegister && displayName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('회원가입에는 표시 이름이 필요해요.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      late final AuthSession session;
      if (_isRegister) {
        session =
            await ref.read(authSessionProvider.notifier).registerSharedAccount(
                  username: username,
                  password: password,
                  displayName: displayName,
                );
      } else {
        session = await ref.read(authSessionProvider.notifier).signInWithEmail(
              email: username,
              password: password,
            );
      }

      await EmployeeeeCloudSyncCoordinator.sync(ref, session);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isRegister ? '공통 계정을 만들었어요.' : '로그인했어요.'),
        ),
      );
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인 서버에 연결하지 못했어요.')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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
