import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../l10n/app_language.dart';
import '../models/account.dart';
import '../providers/budget_provider.dart';
import '../providers/locale_controller.dart';
import '../services/card_screenshot_ocr.dart';
import '../services/gmail_sync_service.dart';
import '../services/outlook_sync_service.dart';
import '../theme/app_motion.dart';
import '../theme/app_theme.dart';
import '../widgets/ambient_background.dart';
import '../widgets/language_picker.dart';
import '../widgets/mail_brand_logos.dart';
import '../widgets/statement_capture_guide.dart';
import 'manage_accounts_screen.dart';

/// First-open wizard: add cards, then connect Gmail and Outlook.
class SetupOnboardingScreen extends StatefulWidget {
  const SetupOnboardingScreen({super.key});

  @override
  State<SetupOnboardingScreen> createState() => _SetupOnboardingScreenState();
}

class _SetupOnboardingScreenState extends State<SetupOnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;
  bool _gmailBusy = false;
  bool _outlookBusy = false;
  final _capturedIds = <String>{};

  static const _lastPage = 3;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await context.read<BudgetProvider>().completeOnboarding();
  }

  void _goTo(int page) {
    _pageController.animateToPage(
      page,
      duration: AppMotion.page,
      curve: AppMotion.pageCurve,
    );
  }

  void _next() {
    if (_page == 0) {
      final locales = context.read<LocaleController>();
      locales.setLanguage(locales.language);
    }
    if (_page >= _lastPage) {
      _finish();
      return;
    }
    _goTo(_page + 1);
  }

  void _skip() {
    if (_page == 1 || _page >= _lastPage) {
      _finish();
      return;
    }
    _goTo(_page + 1);
  }

  Future<void> _showSuccessThenPop(String message) async {
    if (!mounted) return;
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'success',
      barrierColor: Colors.black26,
      transitionDuration: AppMotion.success,
      pageBuilder: (context, animation, _) {
        return Center(
          child: Material(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.income,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: AppMotion.successCurve,
        );
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween(begin: 0.86, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    if (mounted) {
      Navigator.of(context, rootNavigator: true).maybePop();
    }
  }

  Future<void> _addCard({required bool fromScreenshot}) async {
    String? lastFour;
    DateTime? dueDate;
    DateTime? cutoffDate;
    double? balance;

    if (fromScreenshot) {
      final source = await _pickScreenshotSource();
      if (source == null || !mounted) return;
      final image = await ImagePicker().pickImage(
        source: source,
        imageQuality: 92,
      );
      if (image == null || !mounted) return;

      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      try {
        final fields = await CardScreenshotOcr().read(image.path);
        lastFour = fields.lastFour;
        dueDate = fields.dueDate;
        cutoffDate = fields.cutoffDate;
        balance = fields.balance;
      } catch (_) {
        lastFour = null;
        dueDate = null;
        cutoffDate = null;
        balance = null;
      }
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      if (!mounted) return;
      if (lastFour == null && dueDate == null && cutoffDate == null && balance == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.cardOcrFailed)),
        );
      }
    }

    final provider = context.read<BudgetProvider>();
    final beforeIds = provider.accounts.map((a) => a.id).toSet();
    await Navigator.push<void>(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => AccountEditorScreen(
          initialLastFour: lastFour,
          initialDueDate: dueDate,
          initialCutoffDate: cutoffDate,
          initialBalance: balance,
          initialType: AccountType.credit,
        ),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: AppMotion.pageCurve),
              ),
              child: child,
            ),
          );
        },
        transitionDuration: AppMotion.page,
      ),
    );
    if (!mounted) return;
    final added = context
        .read<BudgetProvider>()
        .accounts
        .where((a) => !beforeIds.contains(a.id));
    if (added.isEmpty) return;
    setState(() {
      _capturedIds.addAll(added.map((a) => a.id));
    });
  }

  Future<ImageSource?> _pickScreenshotSource() {
    final l10n = context.l10n;
    return showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  l10n.captureSheetTitle,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(l10n.captureSheetBody),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_rounded),
                title: Text(l10n.takePhoto),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(l10n.chooseScreenshot),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _connectGmail() async {
    setState(() => _gmailBusy = true);
    final provider = context.read<BudgetProvider>();
    try {
      final email = await provider.connectGmail();
      try {
        await provider.syncGmail();
      } catch (_) {
        // First sync is best-effort; connect already succeeded.
      }
      if (!mounted) return;
      await _showSuccessThenPop(context.l10n.connectedAs(email));
    } on GmailSyncException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.expense),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.gmailConnectError('$e')),
          backgroundColor: AppColors.expense,
        ),
      );
    } finally {
      if (mounted) setState(() => _gmailBusy = false);
    }
  }

  Future<void> _connectOutlook() async {
    setState(() => _outlookBusy = true);
    final provider = context.read<BudgetProvider>();
    try {
      final email = await provider.connectOutlook();
      try {
        await provider.syncOutlook();
      } catch (_) {}
      if (!mounted) return;
      await _showSuccessThenPop(context.l10n.connectedAs(email));
    } on OutlookSyncException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.expense),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.outlookConnectError('$e')),
          backgroundColor: AppColors.expense,
        ),
      );
    } finally {
      if (mounted) setState(() => _outlookBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final continueLabel = switch (_page) {
      0 => l10n.continueButton,
      1 => l10n.getStarted,
      3 => l10n.startBudgeting,
      _ => l10n.continueButton,
    };

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 20, 0),
                child: Row(
                  children: [
                    if (_page > 0)
                      IconButton(
                        onPressed: () => _goTo(_page - 1),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      )
                    else
                      const SizedBox(width: 48),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: (_page + 1) / (_lastPage + 1),
                          minHeight: 5,
                          backgroundColor: AppColors.border,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) => setState(() => _page = index),
                  children: [
                    _LanguageStep(
                      selected: context.watch<LocaleController>().language,
                      onSelected: (language) {
                        context.read<LocaleController>().setLanguage(language);
                      },
                    ),
                    const _WelcomeStep(),
                    StatementCaptureGuide(
                      accounts: context
                          .watch<BudgetProvider>()
                          .accounts
                          .where((a) => _capturedIds.contains(a.id))
                          .toList(),
                      balanceOf: context.read<BudgetProvider>().accountBalance,
                      onScreenshot: () => _addCard(fromScreenshot: true),
                      onManual: () => _addCard(fromScreenshot: false),
                    ),
                    _MailStep(
                      gmailBusy: _gmailBusy,
                      outlookBusy: _outlookBusy,
                      onConnectGmail: _connectGmail,
                      onConnectOutlook: _connectOutlook,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  children: [
                    if (_page == 2)
                      FilledButton.icon(
                        onPressed: _next,
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: Text(
                          _capturedIds.isEmpty
                              ? l10n.continueWithoutCard
                              : l10n.continueButton,
                        ),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          backgroundColor: _capturedIds.isEmpty
                              ? AppColors.surfaceMuted
                              : AppColors.primary,
                          foregroundColor: _capturedIds.isEmpty
                              ? AppColors.textPrimary
                              : Colors.white,
                        ),
                      )
                    else
                      FilledButton(
                        onPressed: _next,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                        ),
                        child: Text(continueLabel),
                      ),
                    if (_page == 1 || _page == 3) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _skip,
                        child: Text(
                          _page >= _lastPage ? l10n.skipForNow : l10n.skip,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageStep extends StatelessWidget {
  const _LanguageStep({
    required this.selected,
    required this.onSelected,
  });

  final AppLanguage selected;
  final ValueChanged<AppLanguage> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        children: [
          _StepHeader(
            icon: Icons.translate_rounded,
            title: l10n.languageTitle,
            subtitle: l10n.languageSubtitle,
          ),
          const SizedBox(height: 28),
          LanguagePicker(
            selected: selected,
            onSelected: onSelected,
          ),
        ],
      ),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppGradients.brand,
              boxShadow: AppShadows.glow(AppColors.primary),
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              size: 52,
              color: Colors.white,
            ),
          ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 28),
          Text(
            context.l10n.welcomeTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ).animate().fadeIn(delay: 100.ms).slideY(
                begin: 0.08,
                duration: AppMotion.page,
                curve: AppMotion.pageCurve,
              ),
          const SizedBox(height: 14),
          Text(
            context.l10n.welcomeBody,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.45,
              fontSize: 16,
            ),
          ).animate().fadeIn(delay: 200.ms),
        ],
      ),
    );
  }
}

class _MailStep extends StatelessWidget {
  const _MailStep({
    required this.gmailBusy,
    required this.outlookBusy,
    required this.onConnectGmail,
    required this.onConnectOutlook,
  });

  final bool gmailBusy;
  final bool outlookBusy;
  final VoidCallback onConnectGmail;
  final VoidCallback onConnectOutlook;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BudgetProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        children: [
          _StepHeader(
            icon: Icons.mark_email_read_rounded,
            title: context.l10n.mailTitle,
            subtitle: context.l10n.mailBody,
          ),
          const SizedBox(height: 20),
          _MailProviderCard(
            logo: const GmailLogo(size: 28),
            title: 'Gmail',
            connectedEmail: provider.gmailAccountEmail,
            busy: gmailBusy,
            brand: MailBrand.gmail,
            onConnect: onConnectGmail,
          ).animate().fadeIn(duration: AppMotion.page).slideY(
                begin: 0.08,
                duration: AppMotion.page,
                curve: AppMotion.pageCurve,
              ),
          const SizedBox(height: 12),
          _MailProviderCard(
            logo: const OutlookLogo(size: 28),
            title: 'Outlook',
            connectedEmail: provider.outlookAccountEmail,
            busy: outlookBusy,
            brand: MailBrand.outlook,
            onConnect: onConnectOutlook,
          )
              .animate()
              .fadeIn(
                delay: AppMotion.stagger,
                duration: AppMotion.page,
              )
              .slideY(
                begin: 0.08,
                delay: AppMotion.stagger,
                duration: AppMotion.page,
                curve: AppMotion.pageCurve,
              ),
        ],
      ),
    );
  }
}

class _MailProviderCard extends StatelessWidget {
  const _MailProviderCard({
    required this.logo,
    required this.title,
    required this.brand,
    required this.onConnect,
    this.connectedEmail,
    this.busy = false,
    this.enabled = true,
    this.disabledHint,
  });

  final Widget logo;
  final String title;
  final MailBrand brand;
  final String? connectedEmail;
  final bool busy;
  final bool enabled;
  final String? disabledHint;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    final connected = connectedEmail != null && connectedEmail!.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              logo,
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              if (connected)
                const Icon(Icons.check_circle_rounded, color: AppColors.income),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            connected
                ? connectedEmail!
                : (enabled
                    ? context.l10n.mailReadOnly
                    : (disabledHint ?? 'Not configured yet.')),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13.5,
            ),
          ),
          if (!connected && enabled) ...[
            const SizedBox(height: 14),
            MailConnectButton(
              brand: brand,
              busy: busy,
              onPressed: onConnect,
            ),
          ],
        ],
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 28),
        ).animate().scale(duration: 420.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ).animate().fadeIn(delay: 80.ms).slideY(
              begin: 0.08,
              duration: AppMotion.page,
              curve: AppMotion.pageCurve,
            ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            height: 1.45,
            fontSize: 15,
          ),
        ).animate().fadeIn(delay: 160.ms),
      ],
    );
  }
}
