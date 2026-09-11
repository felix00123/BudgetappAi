import 'dart:convert';

import 'package:home_widget/home_widget.dart';

import '../models/loan.dart';
import '../models/savings_goal.dart';
import '../utils/formatters.dart';

/// Syncs goal/loan progress data to native home screen widgets.
class HomeWidgetService {
  HomeWidgetService._();

  static const appGroupId = 'group.com.budgetappai.sharedai';
  static const androidProviderName = 'ProgressWidgetProvider';

  static const goalsDataKey = 'goals_widget_data';
  static const loansDataKey = 'loans_widget_data';

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      await HomeWidget.setAppGroupId(appGroupId);
    } catch (_) {
      // Missing on unit tests / unsupported platforms.
    }
  }

  static Future<void> sync({
    required List<SavingsGoal> goals,
    required List<Loan> loans,
  }) async {
    try {
      await init();

      final goalsPayload = goals
        .map(
          (g) => {
            'id': g.id,
            'name': g.name,
            'icon': g.icon ?? '🎯',
            'progress': (g.progress * 100).round(),
            'subtitle':
                '${formatCurrency(g.currentSaved)} / ${formatCurrency(g.targetAmount)}',
          },
        )
        .toList();

    final loansPayload = loans
        .map(
          (l) => {
            'id': l.id,
            'name': l.name,
            'icon': l.icon ?? '🏦',
            'progress': (l.progress * 100).round(),
            'subtitle':
                '${formatCurrency(l.amountPaidOff)} / ${formatCurrency(l.principal)}',
          },
        )
        .toList();

    await HomeWidget.saveWidgetData(goalsDataKey, jsonEncode(goalsPayload));
    await HomeWidget.saveWidgetData(loansDataKey, jsonEncode(loansPayload));
    await HomeWidget.updateWidget(
      name: androidProviderName,
      androidName: androidProviderName,
      iOSName: 'budgetappai',
    );
    } catch (_) {
      // Missing on unit tests / unsupported platforms.
    }
  }

  static Future<void> saveWidgetSelection({
    required String type,
    required String itemId,
  }) async {
    try {
      await init();
      await HomeWidget.saveWidgetData('widget_selected_type', type);
      await HomeWidget.saveWidgetData('widget_selected_id', itemId);
      await HomeWidget.updateWidget(
        name: androidProviderName,
        androidName: androidProviderName,
        iOSName: 'budgetappai',
      );
    } catch (_) {
      // Missing on unit tests / unsupported platforms.
    }
  }
}
