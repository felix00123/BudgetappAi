# Budget App

A personal finance app built with Flutter to track income and expenses, plan savings goals, export reports to Excel, and get AI-powered financial advice.

## Features

- **Income & Expense Tracking** — Add transactions with categories, dates, and notes
- **Dashboard** — View balance, monthly stats, and expense breakdown charts
- **Savings Goals** — Plan purchases (e.g. a car) and see how long it takes at your current savings rate
- **Excel Export** — Generate `.xlsx` reports with transactions and daily summaries by date
- **AI Financial Advisor** — Smart local advisor that analyzes your data; optional OpenAI API key for enhanced responses

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.11+)

### Run the app

```bash
cd budget_app
flutter pub get
flutter run
```

### Supported platforms

- iOS
- Android
- macOS
- Web

## Usage

1. **Add transactions** — Tap the + button on Home or Transactions tab
2. **Create a savings goal** — Go to Goals → New Goal (e.g. "Buy a car" for $25,000)
3. **See time estimate** — The app calculates how many months until you reach the goal based on this month's savings
4. **Export to Excel** — Tap the download icon on Home or use quick date filters on the Export screen
5. **Ask the AI Advisor** — Try "How long to save for a car?" or "Help me reduce expenses"

## Optional: OpenAI Integration

The AI Advisor works offline with built-in financial analysis. For enhanced responses, add your OpenAI API key in **AI Advisor → Settings**.

## Project Structure

```
lib/
├── models/          # Transaction, SavingsGoal, ChatMessage
├── providers/       # State management
├── screens/         # UI screens
├── services/        # Storage, Excel export, AI advisor
├── theme/           # App styling
├── utils/           # Formatters
└── widgets/         # Reusable components
```
