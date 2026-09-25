import 'app_language.dart';

class L10n {
  const L10n(this.language);

  final AppLanguage language;

  bool get isEs => language == AppLanguage.es;

  String t(String en, String es) => isEs ? es : en;

  // Language step — keep bilingual so either speaker can choose.
  String get languageTitle => 'Language / Idioma';
  String get languageSubtitle => 'English · Español';
  String get continueButton => t('Continue', 'Continuar');
  String get getStarted => t('Get started', 'Empezar');
  String get skip => t('Skip', 'Omitir');
  String get skipForNow => t('Skip for now', 'Omitir por ahora');
  String get startBudgeting => t('Start budgeting', 'Empezar a presupuestar');
  String get continueWithoutCard =>
      t('Continue without a card', 'Continuar sin tarjeta');

  String get welcomeTitle =>
      t('Let’s set up your money', 'Configuremos tu dinero');
  String get welcomeBody => t(
        'Screenshot your card from the bank app, then connect Gmail or Outlook. You can skip any step.',
        'Toma una captura de tu tarjeta en la app del banco y luego conecta Gmail u Outlook. Puedes omitir cualquier paso.',
      );

  String get captureTitle => t('Capture your card', 'Captura tu tarjeta');
  String get captureBody => t(
        'Add it from a bank screenshot, or type it in yourself.',
        'Agrégala desde una captura del banco, o escríbela tú.',
      );
  String get yourCards => t('Your cards', 'Tus tarjetas');
  String get yourCardsBody => t(
        'Add another from a screenshot, or enter it manually.',
        'Agrega otra desde una captura, o escríbela a mano.',
      );
  String get addFromScreenshot =>
      t('Add from screenshot', 'Agregar desde captura');
  String get addManually => t('Add manually', 'Agregar a mano');
  String get screenshotChoice => t('Screenshot', 'Captura');
  String get manualChoice => t('Manual', 'Manual');
  String get screenshotMethodHint => t(
        'Last 4, credit, corte, due date',
        'Últimos 4, crédito, corte, vencimiento',
      );
  String get manualMethodHint =>
      t('Type the card details', 'Escribe los datos de la tarjeta');
  String get availableCredit => t('Available credit', 'Crédito disponible');
  String get cutoffLabel => t('Statement date', 'Fecha de corte');
  String get dueLabel => t('Pay by', 'Pagar antes de');
  String get captureSheetTitle =>
      t('Capture the card screen', 'Captura la pantalla de la tarjeta');
  String get captureSheetBody => t(
        'Use the screen with last 4, crédito disponible, fecha de corte, and pagar antes de.',
        'Usa la pantalla con los últimos 4, crédito disponible, fecha de corte y pagar antes de.',
      );
  String get takePhoto => t('Take photo', 'Tomar foto');
  String get chooseScreenshot => t('Choose screenshot', 'Elegir captura');
  String get cardOcrFailed => t(
        'Could not read the card fields. You can enter them.',
        'No se pudieron leer los datos de la tarjeta. Puedes ingresarlos.',
      );
  String get cardAdded => t('Card added', 'Tarjeta agregada');

  String get mailTitle => t('Connect your mail', 'Conecta tu correo');
  String get mailBody => t(
        'We’ll look for bank alerts and match them to the last 4 on your cards.',
        'Buscaremos alertas del banco y las relacionaremos con los últimos 4 de tus tarjetas.',
      );
  String get mailReadOnly => t(
        'Read-only access to bank alerts. You can disconnect later.',
        'Acceso de solo lectura a alertas bancarias. Puedes desconectar después.',
      );
  String get connectGmail => t('Connect Gmail', 'Conectar Gmail');
  String get connectOutlook => t('Connect Outlook', 'Conectar Outlook');
  String get connecting => t('Connecting…', 'Conectando…');
  String connectedAs(String email) =>
      t('Connected as $email', 'Conectado como $email');
  String gmailConnectError(String error) =>
      t('Could not connect Gmail: $error', 'No se pudo conectar Gmail: $error');
  String outlookConnectError(String error) => t(
        'Could not connect Outlook: $error',
        'No se pudo conectar Outlook: $error',
      );

  String get navHome => t('Home', 'Inicio');
  String get navActivity => t('Activity', 'Actividad');
  String get navGoals => t('Goals', 'Metas');
  String get navLoans => t('Loans', 'Préstamos');
  String get navAdvisor => t('Advisor', 'Asesor');

  String get goodMorning => t('Good morning', 'Buenos días');
  String get goodAfternoon => t('Good afternoon', 'Buenas tardes');
  String get goodEvening => t('Good evening', 'Buenas noches');

  String get insights => t('Insights', 'Análisis');
  String get categoriesAndAccounts =>
      t('Categories & Accounts', 'Categorías y cuentas');
  String get importAndExport => t('Import & Export', 'Importar y exportar');
  String get languageLabel => t('Language', 'Idioma');

  String get totalBalance => t('Total Balance', 'Saldo total');
  String get income => t('Income', 'Ingresos');
  String get expense => t('Expense', 'Gasto');
  String get expenses => t('Expenses', 'Gastos');
  String get spent => t('Spent', 'Gastado');
  String get received => t('Received', 'Recibido');
  String get thisMonthIncome => t('This Month Income', 'Ingresos del mes');
  String get thisMonthExpenses => t('This Month Expenses', 'Gastos del mes');
  String get monthlySavings => t('Monthly Savings', 'Ahorro del mes');
  String get savingsGoals => t('Savings Goals', 'Metas de ahorro');
  String get loans => t('Loans', 'Préstamos');
  String get recentTransactions =>
      t('Recent Transactions', 'Movimientos recientes');
  String get seeAll => t('See all', 'Ver todo');
  String get accounts => t('Accounts', 'Cuentas');
  String get manage => t('Manage', 'Administrar');
  String get expensesByCategory =>
      t('Expenses by Category', 'Gastos por categoría');

  String get addIncome => t('Add Income', 'Agregar ingreso');
  String get addExpense => t('Add Expense', 'Agregar gasto');
  String get moneyIn => t('Money in', 'Dinero que entra');
  String get moneyOut => t('Money out', 'Dinero que sale');
  String get scanReceipt => t('Scan receipt', 'Escanear recibo');
  String get photoAi => t('Photo + AI', 'Foto + IA');
  String get sayExpense => t('Say expense', 'Dictar gasto');
  String get voiceAi => t('Voice + AI', 'Voz + IA');
  String get takePhotoTooltip => t('Take photo', 'Tomar foto');

  String get loggingActivity => t('Logging Activity', 'Actividad de registro');
  String get loggingActivitySubtitle => t(
        'See how consistently you track your finances',
        'Mira con qué constancia registras tus finanzas',
      );
  String get logTransactions => t('Log Transactions', 'Registrar movimientos');
  String get logTransactionsSubtitle => t(
        'Record income and expenses daily',
        'Registra ingresos y gastos cada día',
      );
  String get trackIncome => t('Track Income', 'Registrar ingresos');
  String get trackIncomeSubtitle =>
      t('Log when money comes in', 'Anota cuando entra dinero');
  String get trackExpenses => t('Track Expenses', 'Registrar gastos');
  String get trackExpensesSubtitle =>
      t('Log when money goes out', 'Anota cuando sale dinero');

  String get noTransactionsYet =>
      t('No transactions yet', 'Aún no hay movimientos');
  String get noTransactionsYetBody => t(
        'Add income, expense, or snap a receipt to get started',
        'Agrega un ingreso, un gasto o captura un recibo para empezar',
      );
  String get addTransaction => t('Add Transaction', 'Agregar movimiento');
  String get editTransaction => t('Edit Transaction', 'Editar movimiento');
  String get transactions => t('Transactions', 'Movimientos');
  String get all => t('All', 'Todos');
  String get searchTransactions =>
      t('Search transactions...', 'Buscar movimientos...');
  String get noTransactionsFound =>
      t('No transactions found', 'No hay movimientos');
  String get tapToAddTransaction =>
      t('Tap + to add your first transaction', 'Toca + para agregar el primero');
  String get recurring => t('Recurring', 'Recurrentes');

  String get noGoalsYet => t('No savings goals yet', 'Aún no hay metas de ahorro');
  String get noGoalsYetBody => t(
        'Create a goal like buying a car and see how long it will take to reach it',
        'Crea una meta, como comprar un carro, y mira cuánto tardarás en alcanzarla',
      );
  String get createGoal => t('Create Goal', 'Crear meta');
  String get newGoal => t('New Goal', 'Nueva meta');
  String get homeScreenWidget =>
      t('Home screen widget', 'Widget de pantalla de inicio');

  String get noLoansYet => t('No loans tracked yet', 'Aún no hay préstamos');
  String get noLoansYetBody => t(
        'Add your mortgages, car loans, or personal loans to see amortization schedules and payoff dates',
        'Agrega hipotecas, préstamos de carro o personales para ver tablas de amortización y fechas de pago',
      );
  String get addLoan => t('Add Loan', 'Agregar préstamo');
  String get newLoan => t('New Loan', 'Nuevo préstamo');
  String get paidOff => t('Paid Off', 'Pagados');

  String get advisorTitle =>
      t('AI Financial Advisor', 'Asesor financiero con IA');
  String get advisorWelcomeTitle =>
      t('Your AI Financial Advisor', 'Tu asesor financiero con IA');
  String get advisorWelcomeBody => t(
        'I analyze your goals, recent income, and spending to give personalized advice. Ask me anything!',
        'Analizo tus metas, ingresos recientes y gastos para darte consejos. ¡Pregúntame lo que quieras!',
      );
  String get tryAsking => t('Try asking:', 'Prueba preguntar:');
  String get askFinancesHint =>
      t('Ask about your finances...', 'Pregunta sobre tus finanzas...');
  String get clearChat => t('Clear chat', 'Borrar chat');
  String get clearChatTitle => t('Clear Chat', 'Borrar chat');
  String get clearChatBody =>
      t('Delete all chat messages?', '¿Borrar todos los mensajes?');
  String get cancel => t('Cancel', 'Cancelar');
  String get clear => t('Clear', 'Borrar');
  String get save => t('Save', 'Guardar');

  List<String> get advisorSuggestions => isEs
      ? const [
          '¿Cómo van mis metas de ahorro?',
          '¿En qué gasté últimamente?',
          'Resume mis ingresos recientes',
          'Ayúdame a crear un presupuesto',
        ]
      : const [
          'How are my savings goals going?',
          'What did I spend on lately?',
          'Summarize my recent income',
          'Help me make a budget',
        ];

  String get categories => t('Categories', 'Categorías');
  String get excel => 'Excel';
  String get gmail => 'Gmail';
  String get outlook => 'Outlook';
  String get bankEmail => t('Bank email', 'Correo del banco');
  String get export => t('Export', 'Exportar');

  String get noRecurringYet =>
      t('No recurring items yet', 'Aún no hay recurrentes');
  String get noRecurringYetBody => t(
        'Set up salary, rent, or subscriptions — e.g. \$5,000 every 1st of the month',
        'Configura salario, alquiler o suscripciones — por ejemplo RD\$5,000 cada día 1',
      );
  String get addRecurring => t('Add Recurring', 'Agregar recurrente');

  String get spendingByCategory =>
      t('Spending by category', 'Gastos por categoría');
  String get last6Months => t('Last 6 months', 'Últimos 6 meses');
  String get monthlySpending => t('Monthly spending', 'Gasto mensual');
  String get bankReportedBalances =>
      t('Bank-reported balances', 'Saldos reportados por el banco');
  String accountsCount(int count) => count == 1
      ? t('1 account', '1 cuenta')
      : t('$count accounts', '$count cuentas');

  String get cash => t('Cash', 'Efectivo');
  String get bank => t('Bank', 'Banco');
  String get creditCard => t('Credit Card', 'Tarjeta de crédito');
  String get savings => t('Savings', 'Ahorros');
  String get other => t('Other', 'Otro');

  String get monthly => t('Monthly', 'Mensual');
  String get weekly => t('Weekly', 'Semanal');
  String get yearly => t('Yearly', 'Anual');

  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return goodMorning;
    if (hour < 18) return goodAfternoon;
    return goodEvening;
  }
}
