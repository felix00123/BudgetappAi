import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/account.dart';
import '../providers/locale_controller.dart';
import '../theme/app_motion.dart';
import '../theme/app_theme.dart';
import 'outline_account_card.dart';

/// Bank-app style guide, then a choice of screenshot vs manual.
/// After a card is saved, it shows wireframe cards of the captured fields.
class StatementCaptureGuide extends StatefulWidget {
  const StatementCaptureGuide({
    super.key,
    required this.accounts,
    required this.balanceOf,
    required this.onScreenshot,
    required this.onManual,
  });

  final List<Account> accounts;
  final double Function(String accountId) balanceOf;
  final VoidCallback onScreenshot;
  final VoidCallback onManual;

  @override
  State<StatementCaptureGuide> createState() => _StatementCaptureGuideState();
}

class _StatementCaptureGuideState extends State<StatementCaptureGuide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scan;

  @override
  void initState() {
    super.initState();
    _scan = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    if (widget.accounts.isEmpty) _scan.repeat();
  }

  @override
  void didUpdateWidget(covariant StatementCaptureGuide oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.accounts.isEmpty) {
      if (!_scan.isAnimating) _scan.repeat();
    } else if (_scan.isAnimating) {
      _scan.stop();
    }
  }

  @override
  void dispose() {
    _scan.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasCards = widget.accounts.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        children: [
          Text(
            hasCards ? l10n.yourCards : l10n.captureTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ).animate().fadeIn(duration: AppMotion.page),
          const SizedBox(height: 8),
          Text(
            hasCards ? l10n.yourCardsBody : l10n.captureBody,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.35,
              fontSize: 14,
            ),
          ).animate().fadeIn(delay: 80.ms),
          const SizedBox(height: 14),
          Expanded(
            child: hasCards
                ? ListView.separated(
                    padding: const EdgeInsets.only(bottom: 8),
                    itemCount: widget.accounts.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final account = widget.accounts[index];
                      return OutlineAccountCard(
                        account: account,
                        balance: widget.balanceOf(account.id),
                      )
                          .animate()
                          .fadeIn(duration: AppMotion.page)
                          .slideY(
                            begin: 0.06,
                            duration: AppMotion.page,
                            curve: AppMotion.pageCurve,
                          );
                    },
                  )
                : AnimatedBuilder(
                    animation: _scan,
                    builder: (context, _) =>
                        _BankCardPreview(scan: _scan.value),
                  ),
          ),
          const SizedBox(height: 14),
          _MethodRow(
            onScreenshot: widget.onScreenshot,
            onManual: widget.onManual,
          ),
        ],
      ),
    );
  }
}

class _MethodRow extends StatelessWidget {
  const _MethodRow({
    required this.onScreenshot,
    required this.onManual,
  });

  final VoidCallback onScreenshot;
  final VoidCallback onManual;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Row(
      children: [
        Expanded(
          child: _MethodTile(
            icon: Icons.photo_camera_rounded,
            title: l10n.screenshotChoice,
            subtitle: l10n.screenshotMethodHint,
            emphasized: true,
            onTap: onScreenshot,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MethodTile(
            icon: Icons.edit_rounded,
            title: l10n.manualChoice,
            subtitle: l10n.manualMethodHint,
            emphasized: false,
            onTap: onManual,
          ),
        ),
      ],
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.emphasized,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool emphasized;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.lg);
    final fill = emphasized ? AppColors.primary : AppColors.card;
    final onFill = emphasized ? Colors.white : AppColors.textPrimary;

    return Material(
      color: fill,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Ink(
          height: 92,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: emphasized ? null : Border.all(color: AppColors.border),
            boxShadow: emphasized
                ? AppShadows.glow(AppColors.primary)
                : AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: onFill, size: 20),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: onFill,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: emphasized
                      ? Colors.white.withValues(alpha: 0.82)
                      : AppColors.textSecondary,
                  fontSize: 10.5,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BankCardPreview extends StatelessWidget {
  const _BankCardPreview({required this.scan});

  final double scan;

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF0B4F7A);
    final lastFourLit = scan >= 0.08 && scan < 0.32;
    final balanceLit = scan >= 0.32 && scan < 0.52;
    final cutoffLit = scan >= 0.52 && scan < 0.74;
    final dueLit = scan >= 0.74 && scan < 0.96;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppShadows.floating,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: navy,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Visa',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'VISA',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                            letterSpacing: 1.6,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _Glow(
                          active: lastFourLit,
                          child: const Text(
                            '••••  ••••  4281',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Crédito disponible',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _Glow(
                          active: balanceLit,
                          child: const Text(
                            'DOP 19,681.25',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(22),
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Balance tarjeta',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: navy,
                            ),
                          ),
                          const Spacer(),
                          _Glow(
                            active: cutoffLit,
                            fill: true,
                            child: const _SheetRow(
                              label: 'Fecha de corte',
                              value: 'Sep 2, 2026',
                            ),
                          ),
                          const SizedBox(height: 8),
                          _Glow(
                            active: dueLit,
                            fill: true,
                            child: const _SheetRow(
                              label: 'Pagar antes de',
                              value: 'Sep 17, 2026',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: Align(
                  alignment: Alignment(0, -1 + scan * 2),
                  child: Container(
                    height: 36,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0x00FFFFFF),
                          Colors.white.withValues(alpha: 0.22),
                          const Color(0x00FFFFFF),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({
    required this.active,
    required this.child,
    this.fill = false,
  });

  final bool active;
  final bool fill;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.page,
      width: fill ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: active ? const Color(0x66FFD54F) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: active ? Border.all(color: const Color(0xFFFFD54F)) : null,
      ),
      child: child,
    );
  }
}

class _SheetRow extends StatelessWidget {
  const _SheetRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
