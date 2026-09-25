import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../l10n/app_language.dart';
import '../providers/locale_controller.dart';
import '../theme/app_motion.dart';
import '../theme/app_theme.dart';

class LanguagePicker extends StatelessWidget {
  const LanguagePicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final AppLanguage selected;
  final ValueChanged<AppLanguage> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < AppLanguage.values.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _LanguageCard(
            language: AppLanguage.values[i],
            selected: selected == AppLanguage.values[i],
            onTap: () => onSelected(AppLanguage.values[i]),
          )
              .animate()
              .fadeIn(
                delay: AppMotion.stagger * i,
                duration: AppMotion.page,
              )
              .slideY(
                begin: 0.08,
                delay: AppMotion.stagger * i,
                duration: AppMotion.page,
                curve: AppMotion.pageCurve,
              ),
        ],
      ],
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.language,
    required this.selected,
    required this.onTap,
  });

  final AppLanguage language;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: AnimatedContainer(
          duration: AppMotion.page,
          curve: AppMotion.pageCurve,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? AppShadows.glow(AppColors.primary.withValues(alpha: 0.35))
                : AppShadows.card,
          ),
          child: Row(
            children: [
              Text(language.flag, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      language.nativeName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      language.otherName,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedOpacity(
                duration: AppMotion.page,
                opacity: selected ? 1 : 0,
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showLanguagePickerSheet(BuildContext context) {
  final controller = context.localeController;
  if (controller == null) return Future.value();

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.l10n.languageTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),
              LanguagePicker(
                selected: controller.language,
                onSelected: (language) async {
                  await controller.setLanguage(language);
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}
