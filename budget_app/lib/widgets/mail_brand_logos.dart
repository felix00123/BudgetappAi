import 'package:flutter/material.dart';

import '../providers/locale_controller.dart';
import '../theme/app_theme.dart';

/// Official-looking Gmail four-color mark.
class GmailLogo extends StatelessWidget {
  const GmailLogo({super.key, this.size = 24});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: const _GmailLogoPainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

/// Outlook 365-style blue tile plus envelope.
class OutlookLogo extends StatelessWidget {
  const OutlookLogo({super.key, this.size = 24});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: const _OutlookLogoPainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _GmailLogoPainter extends CustomPainter {
  const _GmailLogoPainter();

  static const _blue = Color(0xFF4285F4);
  static const _green = Color(0xFF34A853);
  static const _yellow = Color(0xFFFBBC04);
  static const _red = Color(0xFFEA4335);
  static const _darkRed = Color(0xFFC5221F);

  Offset _p(Size size, double x, double y) {
    return Offset(
      (x - 52) / 88 * size.width,
      (y - 42) / 66 * size.height,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    Offset p(double x, double y) => _p(size, x, y);

    final blue = Path()
      ..moveTo(p(58, 108).dx, p(58, 108).dy)
      ..lineTo(p(72, 108).dx, p(72, 108).dy)
      ..lineTo(p(72, 74).dx, p(72, 74).dy)
      ..lineTo(p(52, 59).dx, p(52, 59).dy)
      ..lineTo(p(52, 102).dx, p(52, 102).dy)
      ..cubicTo(
        p(52, 105.32).dx,
        p(52, 105.32).dy,
        p(54.69, 108).dx,
        p(54.69, 108).dy,
        p(58, 108).dx,
        p(58, 108).dy,
      );

    final green = Path()
      ..moveTo(p(120, 108).dx, p(120, 108).dy)
      ..lineTo(p(134, 108).dx, p(134, 108).dy)
      ..cubicTo(
        p(137.32, 108).dx,
        p(137.32, 108).dy,
        p(140, 105.31).dx,
        p(140, 105.31).dy,
        p(140, 102).dx,
        p(140, 102).dy,
      )
      ..lineTo(p(140, 59).dx, p(140, 59).dy)
      ..lineTo(p(120, 74).dx, p(120, 74).dy)
      ..close();

    final yellow = Path()
      ..moveTo(p(120, 48).dx, p(120, 48).dy)
      ..lineTo(p(120, 74).dx, p(120, 74).dy)
      ..lineTo(p(140, 59).dx, p(140, 59).dy)
      ..lineTo(p(140, 51).dx, p(140, 51).dy)
      ..cubicTo(
        p(140, 43.58).dx,
        p(140, 43.58).dy,
        p(131.53, 39.35).dx,
        p(131.53, 39.35).dy,
        p(125.6, 43.8).dx,
        p(125.6, 43.8).dy,
      )
      ..close();

    final red = Path()
      ..moveTo(p(72, 74).dx, p(72, 74).dy)
      ..lineTo(p(72, 48).dx, p(72, 48).dy)
      ..lineTo(p(96, 66).dx, p(96, 66).dy)
      ..lineTo(p(120, 48).dx, p(120, 48).dy)
      ..lineTo(p(120, 74).dx, p(120, 74).dy)
      ..lineTo(p(96, 92).dx, p(96, 92).dy)
      ..close();

    final darkRed = Path()
      ..moveTo(p(52, 51).dx, p(52, 51).dy)
      ..lineTo(p(52, 59).dx, p(52, 59).dy)
      ..lineTo(p(72, 74).dx, p(72, 74).dy)
      ..lineTo(p(72, 48).dx, p(72, 48).dy)
      ..lineTo(p(66.4, 43.8).dx, p(66.4, 43.8).dy)
      ..cubicTo(
        p(60.46, 39.35).dx,
        p(60.46, 39.35).dy,
        p(52, 43.58).dx,
        p(52, 43.58).dy,
        p(52, 51).dx,
        p(52, 51).dy,
      );

    canvas.drawPath(blue, Paint()..color = _blue);
    canvas.drawPath(green, Paint()..color = _green);
    canvas.drawPath(yellow, Paint()..color = _yellow);
    canvas.drawPath(darkRed, Paint()..color = _darkRed);
    canvas.drawPath(red, Paint()..color = _red);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _OutlookLogoPainter extends CustomPainter {
  const _OutlookLogoPainter();

  static const _envelope = Color(0xFF28A8EA);
  static const _tile = Color(0xFF0078D4);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final envelope = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.30, h * 0.18, w * 0.66, h * 0.64),
      Radius.circular(w * 0.08),
    );
    canvas.drawRRect(envelope, Paint()..color = _envelope);

    final flap = Path()
      ..moveTo(w * 0.36, h * 0.24)
      ..lineTo(w * 0.64, h * 0.46)
      ..lineTo(w * 0.92, h * 0.24);
    canvas.drawPath(
      flap,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.92)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.055
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawLine(
      Offset(w * 0.40, h * 0.72),
      Offset(w * 0.88, h * 0.72),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.55)
        ..strokeWidth = w * 0.045
        ..strokeCap = StrokeCap.round,
    );

    final tile = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.02, h * 0.12, w * 0.58, h * 0.76),
      Radius.circular(w * 0.11),
    );
    canvas.drawRRect(tile, Paint()..color = _tile);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.31, h * 0.50),
        width: w * 0.30,
        height: h * 0.36,
      ),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.075,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

enum MailBrand { gmail, outlook }

/// Connect button with the provider's brand mark.
class MailConnectButton extends StatelessWidget {
  const MailConnectButton({
    super.key,
    required this.brand,
    required this.onPressed,
    this.busy = false,
  });

  final MailBrand brand;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final isGmail = brand == MailBrand.gmail;
    final l10n = context.l10n;
    final label = busy
        ? l10n.connecting
        : isGmail
            ? l10n.connectGmail
            : l10n.connectOutlook;

    final logo = isGmail
        ? const GmailLogo(size: 18)
        : const OutlookLogo(size: 18);

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton(
        onPressed: busy ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: isGmail ? Colors.white : const Color(0xFF0078D4),
          foregroundColor:
              isGmail ? const Color(0xFF1F1F1F) : Colors.white,
          disabledBackgroundColor: isGmail
              ? Colors.white
              : const Color(0xFF0078D4).withValues(alpha: 0.6),
          elevation: 0,
          side: isGmail
              ? const BorderSide(color: Color(0xFFDADCE0))
              : BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (busy)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isGmail ? const Color(0xFF5F6368) : Colors.white,
                ),
              )
            else
              Container(
                width: 22,
                height: 22,
                padding: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: logo,
              ),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
