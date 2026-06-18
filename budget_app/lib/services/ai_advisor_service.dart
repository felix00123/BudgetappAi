import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/account.dart';
import '../models/category.dart';
import '../models/loan.dart';
import '../models/savings_goal.dart';
import '../models/transaction.dart';
import 'financial_context_builder.dart';
import '../utils/formatters.dart';

class AiAdvisorService {
  final _contextBuilder = FinancialContextBuilder();

  FinancialContext buildContext({
    required List<Transaction> transactions,
    required List<SavingsGoal> goals,
    required List<Loan> loans,
    required List<BudgetCategory> categories,
    required List<Account> accounts,
    required double monthlyIncome,
    required double monthlyExpenses,
    required double monthlySavings,
    required double Function(String accountId) accountBalance,
  }) {
    return _contextBuilder.build(
      transactions: transactions,
      goals: goals,
      loans: loans,
      categories: categories,
      accounts: accounts,
      monthlyIncome: monthlyIncome,
      monthlyExpenses: monthlyExpenses,
      monthlySavings: monthlySavings,
      accountBalance: accountBalance,
    );
  }

  Future<String> getAdvice({
    required String userMessage,
    required FinancialContext context,
    required List<SavingsGoal> goals,
    required List<BudgetCategory> categories,
    required List<Transaction> transactions,
    String? openAiApiKey,
  }) async {
    final spanish = _isSpanish(userMessage);

    if (openAiApiKey != null && openAiApiKey.isNotEmpty) {
      try {
        return await _getOpenAiAdvice(
          apiKey: openAiApiKey,
          userMessage: userMessage,
          context: context,
          spanish: spanish,
        );
      } catch (_) {
        // Fall back to local advisor
      }
    }
    return _getLocalAdvice(
      userMessage: userMessage,
      context: context,
      goals: goals,
      transactions: transactions,
      categories: categories,
      spanish: spanish,
    );
  }

  Future<String> _getOpenAiAdvice({
    required String apiKey,
    required String userMessage,
    required FinancialContext context,
    required bool spanish,
  }) async {
    final lang = spanish ? 'Spanish' : 'English';
    final promptContext = context.toPromptText();

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-4o-mini',
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a friendly, practical personal finance advisor inside a budget app. '
                'You ALWAYS use the user\'s real data below — their goals, progress, recent income, '
                'recent expenses, accounts, and monthly totals. Reference specific amounts, categories, '
                'and goal names when relevant. Give clear, actionable advice. '
                'Use bullet points when helpful. Keep responses under 350 words. '
                'Respond in $lang.\n\n'
                'USER FINANCIAL DATA:\n$promptContext',
          },
          {'role': 'user', 'content': userMessage},
        ],
        'max_tokens': 600,
        'temperature': 0.7,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('OpenAI API error: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = data['choices'] as List;
    return choices.first['message']['content'] as String;
  }

  String _getLocalAdvice({
    required String userMessage,
    required FinancialContext context,
    required List<SavingsGoal> goals,
    required List<Transaction> transactions,
    required List<BudgetCategory> categories,
    required bool spanish,
  }) {
    final lower = userMessage.toLowerCase();

    if (_matchesAny(lower, ['hola', 'hello', 'hi', 'hey', 'help', 'ayuda'])) {
      return _welcomeMessage(context, spanish);
    }

    if (_matchesAny(lower, ['car', 'vehicle', 'auto', 'carro', 'coche'])) {
      return _carAdvice(goals, context.monthlySavings, spanish);
    }

    if (_matchesAny(lower, ['save', 'saving', 'savings', 'ahorr', 'ahorro'])) {
      return _savingsAdvice(context, goals, spanish);
    }

    if (_matchesAny(lower, ['budget', 'plan', 'planning', 'presupuesto'])) {
      return _budgetAdvice(context, spanish);
    }

    if (_matchesAny(lower, [
      'expense', 'spending', 'spend', 'cut', 'reduce',
      'gasto', 'gastos', 'gasté', 'gaste',
    ])) {
      return _expenseAdvice(context, spanish);
    }

    if (_matchesAny(lower, [
      'income', 'earn', 'salary', 'money', 'entrada', 'entradas',
      'ingreso', 'ingresos', 'sueldo',
    ])) {
      return _incomeAdvice(context, spanish);
    }

    if (_matchesAny(lower, ['goal', 'target', 'dream', 'meta', 'metas', 'objetivo'])) {
      return _goalsAdvice(context, goals, spanish);
    }

    if (_matchesAny(lower, ['debt', 'loan', 'credit', 'deuda', 'préstamo', 'prestamo'])) {
      return _debtAdvice(context.monthlySavings, spanish);
    }

    if (_matchesAny(lower, ['invest', 'investment', 'stock', 'retire', 'invert'])) {
      return _investmentAdvice(context.monthlySavings, spanish);
    }

    if (_matchesAny(lower, ['reciente', 'recent', 'últim', 'ultim', 'lately', 'ultimo'])) {
      return _recentActivityAdvice(context, spanish);
    }

    return _generalAdvice(context, spanish);
  }

  bool _isSpanish(String text) {
    const markers = [
      'hola', 'cómo', 'como', 'qué', 'que', 'cuánto', 'cuanto',
      'ahorr', 'gast', 'ingres', 'meta', 'presupuesto', 'ayuda',
      'debo', 'puedo', 'mis', 'tengo',
    ];
    final lower = text.toLowerCase();
    return markers.any((m) => lower.contains(m));
  }

  bool _matchesAny(String text, List<String> keywords) =>
      keywords.any((k) => text.contains(k));

  String _welcomeMessage(FinancialContext context, bool spanish) {
    if (spanish) {
      return '👋 ¡Hola! Soy tu asesor financiero personal.\n\n'
          'Ya conozco tus metas, ingresos y gastos recientes:\n\n'
          '${context.toUserSummary(inSpanish: true)}\n\n'
          'Puedo ayudarte con:\n'
          '• Cuánto falta para tus metas\n'
          '• Analizar en qué gastaste últimamente\n'
          '• Revisar tus ingresos recientes\n'
          '• Crear un plan de ahorro\n\n'
          'Pregúntame lo que necesites sobre tus finanzas.';
    }
    return '👋 Hi! I\'m your personal finance advisor.\n\n'
        'I already know your goals, recent income, and recent spending:\n\n'
        '${context.toUserSummary()}\n\n'
        'I can help you with:\n'
        '• How far you are from your goals\n'
        '• What you\'ve spent lately\n'
        '• Reviewing your recent income\n'
        '• Building a savings plan\n\n'
        'Ask me anything about your finances!';
  }

  String _recentActivityAdvice(FinancialContext context, bool spanish) {
    final buffer = StringBuffer(
      spanish ? '📋 Actividad reciente (30 días)\n\n' : '📋 Recent activity (30 days)\n\n',
    );

    buffer.writeln(
      spanish
          ? 'Ingresos: ${formatCurrency(context.last30DaysIncomeTotal)}'
          : 'Income: ${formatCurrency(context.last30DaysIncomeTotal)}',
    );
    if (context.recentIncome.isEmpty) {
      buffer.writeln(spanish ? 'Sin ingresos registrados.' : 'No income recorded.');
    } else {
      for (final t in context.recentIncome.take(8)) {
        buffer.writeln('• ${t.shortLine}');
      }
    }

    buffer.writeln();
    buffer.writeln(
      spanish
          ? 'Gastos: ${formatCurrency(context.last30DaysExpenseTotal)}'
          : 'Expenses: ${formatCurrency(context.last30DaysExpenseTotal)}',
    );
    if (context.recentExpenses.isEmpty) {
      buffer.writeln(spanish ? 'Sin gastos registrados.' : 'No expenses recorded.');
    } else {
      for (final t in context.recentExpenses.take(8)) {
        buffer.writeln('• ${t.shortLine}');
      }
    }

    if (context.goals.isNotEmpty) {
      buffer.writeln();
      buffer.writeln(spanish ? '🎯 Estado de metas:' : '🎯 Goal progress:');
      for (final g in context.goals) {
        buffer.writeln(
          '• ${g.icon ?? '🎯'} ${g.name}: ${g.progressPercent}% '
          '(${formatCurrency(g.saved)}/${formatCurrency(g.target)})',
        );
      }
    }

    return buffer.toString();
  }

  String _carAdvice(List<SavingsGoal> goals, double monthlySavings, bool spanish) {
    final carGoal = goals.where((g) =>
        g.name.toLowerCase().contains('car') ||
        g.name.toLowerCase().contains('carro') ||
        g.name.toLowerCase().contains('coche') ||
        g.icon == '🚗').firstOrNull;

    if (carGoal != null) {
      final months = carGoal.monthsToReach(monthlySavings);
      if (months == null) {
        return spanish
            ? '🚗 Tu meta "${carGoal.name}" necesita un ahorro mensual positivo.\n\n'
                'Ahorrado: ${formatCurrency(carGoal.currentSaved)} de ${formatCurrency(carGoal.targetAmount)}.\n'
                'Reduce gastos un 10-15% para avanzar hacia tu meta.'
            : '🚗 Your goal "${carGoal.name}" needs a positive savings rate.\n\n'
                'Saved: ${formatCurrency(carGoal.currentSaved)} of ${formatCurrency(carGoal.targetAmount)}.\n'
                'Try cutting expenses 10-15% to progress toward your goal.';
      }
      if (months == 0) {
        return spanish
            ? '🎉 ¡Ya alcanzaste tu meta de ${formatCurrency(carGoal.targetAmount)} para ${carGoal.name}!'
            : '🎉 You\'ve reached your ${formatCurrency(carGoal.targetAmount)} goal for ${carGoal.name}!';
      }
      final completion = carGoal.estimatedCompletionDate(monthlySavings);
      return spanish
          ? '🚗 ${carGoal.name}\n\n'
              'Progreso: ${formatCurrency(carGoal.currentSaved)} / ${formatCurrency(carGoal.targetAmount)}\n'
              'Faltan: ${formatCurrency(carGoal.remaining)}\n'
              'A tu ritmo de ${formatCurrency(monthlySavings)}/mes: ${formatDuration(months)}\n'
              'Fecha estimada: ${formatDate(completion!)}'
          : '🚗 ${carGoal.name}\n\n'
              'Progress: ${formatCurrency(carGoal.currentSaved)} / ${formatCurrency(carGoal.targetAmount)}\n'
              'Remaining: ${formatCurrency(carGoal.remaining)}\n'
              'At ${formatCurrency(monthlySavings)}/month: ${formatDuration(months)}\n'
              'Estimated: ${formatDate(completion!)}';
    }

    if (monthlySavings <= 0) {
      return spanish
          ? '🚗 Primero necesitas ahorrar cada mes. Crea una meta en la pestaña Metas.'
          : '🚗 You need positive monthly savings first. Create a goal in the Goals tab.';
    }

    final months = (25000 / monthlySavings).ceil();
    return spanish
        ? '🚗 Sin meta de auto definida. A ${formatCurrency(monthlySavings)}/mes, '
            'un auto de \$25,000 tomaría ${formatDuration(months)}.'
        : '🚗 No car goal set. At ${formatCurrency(monthlySavings)}/month, '
            'a \$25,000 car would take ${formatDuration(months)}.';
  }

  String _savingsAdvice(
    FinancialContext context,
    List<SavingsGoal> goals,
    bool spanish,
  ) {
    final rate = context.savingsRate;
    final buffer = StringBuffer(spanish ? '💰 Análisis de ahorro\n\n' : '💰 Savings analysis\n\n');

    if (context.monthlySavings <= 0) {
      buffer.writeln(spanish
          ? '⚠️ Este mes gastas igual o más de lo que ingresas.'
          : '⚠️ You\'re not saving this month — expenses match or exceed income.');
      buffer.writeln(spanish
          ? 'Ingresos: ${formatCurrency(context.monthlyIncome)} | Gastos: ${formatCurrency(context.monthlyExpenses)}'
          : 'Income: ${formatCurrency(context.monthlyIncome)} | Expenses: ${formatCurrency(context.monthlyExpenses)}');
    } else {
      buffer.writeln(spanish
          ? 'Ahorras ${formatCurrency(context.monthlySavings)}/mes (${rate.toStringAsFixed(1)}% de ingresos).'
          : 'You\'re saving ${formatCurrency(context.monthlySavings)}/month (${rate.toStringAsFixed(1)}% of income).');
    }

    if (context.goals.isNotEmpty) {
      buffer.writeln(spanish ? '\nTus metas:' : '\nYour goals:');
      for (final g in context.goals) {
        buffer.writeln(
          '• ${g.icon ?? '🎯'} ${g.name}: ${g.progressPercent}% — '
          '${formatCurrency(g.saved)} / ${formatCurrency(g.target)}'
          '${g.monthsToGoal != null && g.monthsToGoal! > 0 ? ' — ${formatDuration(g.monthsToGoal!)}' : ''}',
        );
      }
    } else if (goals.isEmpty) {
      buffer.writeln(spanish
          ? '\n💡 Crea metas en la pestaña Metas para saber cuánto falta.'
          : '\n💡 Create goals in the Goals tab to track progress.');
    }

    return buffer.toString();
  }

  String _budgetAdvice(FinancialContext context, bool spanish) {
    if (context.monthlyIncome <= 0) {
      return spanish
          ? '📊 Registra tus ingresos primero para crear un presupuesto.'
          : '📊 Add income transactions first to build a budget.';
    }

    final income = context.monthlyIncome;
    final buffer = StringBuffer(
      spanish ? '📊 Presupuesto 50/30/20\n\n' : '📊 50/30/20 Budget\n\n',
    );
    buffer.writeln(spanish
        ? 'Ingresos del mes: ${formatCurrency(income)}'
        : 'Monthly income: ${formatCurrency(income)}');
    buffer.writeln(spanish
        ? 'Gastos del mes: ${formatCurrency(context.monthlyExpenses)}'
        : 'Monthly expenses: ${formatCurrency(context.monthlyExpenses)}');

    if (context.monthlyExpensesByCategory.isNotEmpty) {
      buffer.writeln(spanish ? '\nGastos por categoría (este mes):' : '\nSpending by category (this month):');
      final sorted = context.monthlyExpensesByCategory.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      for (final e in sorted.take(5)) {
        buffer.writeln('• ${e.key}: ${formatCurrency(e.value)}');
      }
    }

    if (context.goals.isNotEmpty) {
      buffer.writeln(spanish ? '\nMetas activas:' : '\nActive goals:');
      for (final g in context.goals.take(3)) {
        buffer.writeln('• ${g.name}: ${g.progressPercent}%');
      }
    }

    return buffer.toString();
  }

  String _expenseAdvice(FinancialContext context, bool spanish) {
    if (context.recentExpenses.isEmpty &&
        context.monthlyExpensesByCategory.isEmpty) {
      return spanish
          ? 'Registra gastos para que pueda analizar en qué gastas.'
          : 'Add expenses so I can analyze your spending.';
    }

    final buffer = StringBuffer(spanish ? '💸 Tus gastos\n\n' : '💸 Your spending\n\n');

    buffer.writeln(spanish
        ? 'Este mes: ${formatCurrency(context.monthlyExpenses)}'
        : 'This month: ${formatCurrency(context.monthlyExpenses)}');
    buffer.writeln(spanish
        ? 'Últimos 30 días: ${formatCurrency(context.last30DaysExpenseTotal)}'
        : 'Last 30 days: ${formatCurrency(context.last30DaysExpenseTotal)}');

    if (context.monthlyExpensesByCategory.isNotEmpty) {
      buffer.writeln(spanish ? '\nPor categoría (este mes):' : '\nBy category (this month):');
      final sorted = context.monthlyExpensesByCategory.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      for (final e in sorted.take(6)) {
        final pct = context.monthlyExpenses > 0
            ? (e.value / context.monthlyExpenses * 100).toStringAsFixed(0)
            : '0';
        buffer.writeln('• ${e.key}: ${formatCurrency(e.value)} ($pct%)');
      }
    }

    if (context.recentExpenses.isNotEmpty) {
      buffer.writeln(spanish ? '\nGastos recientes:' : '\nRecent expenses:');
      for (final t in context.recentExpenses.take(6)) {
        buffer.writeln('• ${t.shortLine}');
      }
    }

    return buffer.toString();
  }

  String _incomeAdvice(FinancialContext context, bool spanish) {
    if (context.recentIncome.isEmpty && context.monthlyIncome <= 0) {
      return spanish
          ? '💵 Registra tus ingresos en la pestaña Transacciones.'
          : '💵 Record your income in the Transactions tab.';
    }

    final buffer = StringBuffer(spanish ? '💵 Tus ingresos\n\n' : '💵 Your income\n\n');
    buffer.writeln(spanish
        ? 'Este mes: ${formatCurrency(context.monthlyIncome)}'
        : 'This month: ${formatCurrency(context.monthlyIncome)}');
    buffer.writeln(spanish
        ? 'Últimos 30 días: ${formatCurrency(context.last30DaysIncomeTotal)}'
        : 'Last 30 days: ${formatCurrency(context.last30DaysIncomeTotal)}');
    buffer.writeln(spanish
        ? 'Disponible después de gastos: ${formatCurrency(context.monthlySavings)}'
        : 'Available after expenses: ${formatCurrency(context.monthlySavings)}');

    if (context.recentIncome.isNotEmpty) {
      buffer.writeln(spanish ? '\nIngresos recientes:' : '\nRecent income:');
      for (final t in context.recentIncome.take(8)) {
        buffer.writeln('• ${t.shortLine}');
      }
    }

    return buffer.toString();
  }

  String _goalsAdvice(
    FinancialContext context,
    List<SavingsGoal> goals,
    bool spanish,
  ) {
    if (context.goals.isEmpty) {
      return spanish
          ? '🎯 No tienes metas aún. Créalas en la pestaña Metas (ej: comprar un carro).'
          : '🎯 No goals yet. Create them in Goals (e.g. buy a car).';
    }

    final buffer = StringBuffer(spanish ? '🎯 Tus metas y avance\n\n' : '🎯 Your goals & progress\n\n');
    for (final g in context.goals) {
      buffer.writeln('${g.icon ?? '🎯'} ${g.name}');
      buffer.writeln(spanish
          ? '   Avance: ${g.progressPercent}% (${formatCurrency(g.saved)} de ${formatCurrency(g.target)})'
          : '   Progress: ${g.progressPercent}% (${formatCurrency(g.saved)} / ${formatCurrency(g.target)})');
      buffer.writeln(spanish
          ? '   Faltan: ${formatCurrency(g.remaining)}'
          : '   Remaining: ${formatCurrency(g.remaining)}');
      if (g.monthsToGoal != null && g.monthsToGoal! > 0) {
        buffer.writeln(spanish
            ? '   Tiempo estimado: ${formatDuration(g.monthsToGoal!)}'
            : '   Time to goal: ${formatDuration(g.monthsToGoal!)}');
      } else if (g.remaining <= 0) {
        buffer.writeln(spanish ? '   ✅ ¡Meta alcanzada!' : '   ✅ Goal reached!');
      }
      buffer.writeln('');
    }

    return buffer.toString();
  }

  String _debtAdvice(double monthlySavings, bool spanish) {
    return spanish
        ? '💳 Capacidad de ahorro actual: ${formatCurrency(monthlySavings)}/mes.\n'
            'Prioriza deudas con mayor interés o usa el método bola de nieve.'
        : '💳 Current savings capacity: ${formatCurrency(monthlySavings)}/month.\n'
            'Prioritize high-interest debt or use the snowball method.';
  }

  String _investmentAdvice(double monthlySavings, bool spanish) {
    return spanish
        ? '📈 Con ${formatCurrency(monthlySavings)}/mes: primero fondo de emergencia (3-6 meses), '
            'luego considera index funds.'
        : '📈 With ${formatCurrency(monthlySavings)}/month: build emergency fund first (3-6 months), '
            'then consider index funds.';
  }

  String _generalAdvice(FinancialContext context, bool spanish) {
    if (spanish) {
      return 'Aquí está tu situación financiera actual:\n\n'
          '${context.toUserSummary(inSpanish: true)}\n\n'
          'Pregúntame sobre:\n'
          '• "¿En qué gasté últimamente?"\n'
          '• "¿Cómo van mis metas?"\n'
          '• "¿Cuánto ingresé este mes?"\n'
          '• "Ayúdame a ahorrar para un carro"';
    }
    return 'Here\'s your current financial picture:\n\n'
        '${context.toUserSummary()}\n\n'
        'Try asking:\n'
        '• "What did I spend lately?"\n'
        '• "How are my goals progressing?"\n'
        '• "How much income did I get this month?"\n'
        '• "Help me save for a car"';
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) return iterator.current;
    return null;
  }
}
