import 'package:flutter/material.dart';

import '../models/account.dart';
import '../providers/locale_controller.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// Wireframe credit card: transparent fill, drawn with hairlines, showing
/// the fields we keep from a screenshot (last 4, balance, corte, vencimiento).
class OutlineAccountCard extends StatelessWidget {
  const OutlineAccountCard({
    super.key,
    required this.account,
    required this.balance,
  });

  final Account account;
  final double balance;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lastFour = account.lastFour;
    final lineColor = AppColors.textPrimary.withValues(alpha: 0.42);

    return AspectRatio(
      aspectRatio: 1.62,
      child: CustomPaint(
        painter: _CardWireframePainter(color: lineColor),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      account.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  Text(
                    accountTypeLabel(account.type),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
              const Spacer(flex: 2),
              Text(
                lastFour == null || lastFour.isEmpty
                    ? '••••  ••••  ••••  ••••'
                    : '••••  ••••  ••••  $lastFour',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.4,
                ),
              ),
              const Spacer(),
              _Hairline(color: lineColor),
              const SizedBox(height: 10),
              Text(
                l10n.availableCredit,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                formatCurrency(balance),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 10),
              _Hairline(color: lineColor),
              const SizedBox(height: 10),
              _FieldRow(
                label: l10n.cutoffLabel,
                value: account.cutoffDate == null
                    ? '—'
                    : formatDate(account.cutoffDate!),
              ),
              const SizedBox(height: 6),
              _FieldRow(
                label: l10n.dueLabel,
                value: account.dueDate == null
                    ? '—'
                    : formatDate(account.dueDate!),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.label, required this.value});

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
              fontSize: 12.5,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12.5,
          ),
        ),
      ],
    );
  }
}

class _Hairline extends StatelessWidget {
  const _Hairline({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      width: double.infinity,
      child: ColoredBox(color: color.withValues(alpha: 0.55)),
    );
  }
}

class _CardWireframePainter extends CustomPainter {
  const _CardWireframePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final radius = Radius.circular(AppRadius.lg);
    final rect = RRect.fromRectAndRadius(Offset.zero & size, radius);
    canvas.drawRRect(rect, stroke);

    // Chip, drawn as a small rounded rectangle near the top-left.
    final chip = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.07, size.height * 0.22, 34, 24),
      const Radius.circular(6),
    );
    canvas.drawRRect(chip, stroke);

    // Inner corner ticks so it reads as a drafted card, not a filled tile.
    const tick = 10.0;
    final tickPaint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.square;
    void corner(Offset origin, double dx, double dy) {
      canvas.drawLine(origin, origin.translate(dx, 0), tickPaint);
      canvas.drawLine(origin, origin.translate(0, dy), tickPaint);
    }

    corner(const Offset(10, 10), tick, tick);
    corner(Offset(size.width - 10, 10), -tick, tick);
    corner(Offset(10, size.height - 10), tick, -tick);
    corner(Offset(size.width - 10, size.height - 10), -tick, -tick);
  }

  @override
  bool shouldRepaint(covariant _CardWireframePainter oldDelegate) =>
      oldDelegate.color != color;
}
