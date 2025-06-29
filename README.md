# MoneyLog

MoneyLog is a comprehensive personal finance management app that helps you track and analyze your expenses, income, and financial transactions. Built with Flutter and Material Design 3, it offers a beautiful, intuitive interface with dynamic color theming and powerful financial insights.

## ✨ Features

- **📱 Modern Material 3 UI**: Beautiful, responsive interface with dynamic color theming and dark/light mode support
- **💳 Transaction Management**: Track income and expenses with detailed categorization
- **📊 Financial Insights**: Visualize your spending patterns with interactive charts and reports
- **🔔 Smart Reminders**: Never miss a bill payment with customizable reminders
- **🔒 Secure**: Optional biometric/PIN protection for your financial data

### 🏠 Dashboard
- Personalized financial overview with account balances and monthly summaries
- Quick access to recent transactions with detailed breakdowns
- Visual spending analytics with interactive charts

### 💬 Transaction Logs
- Automatic SMS transaction parsing from your bank messages
- Smart categorization of transactions
- Powerful search and filter functionality

### 📈 Financial Analysis
- Interactive expense tracking with daily, weekly, and monthly views
- Customizable budget categories and spending limits
- Exportable reports for tax and financial planning

### ⚙️ Account Management
- Multiple account support with individual balance tracking
- Customizable categories and tags
- Backup and restore functionality

### Settings
- Appearance: System/Dark/Light mode, dark style.
- Theme: Seed color picker for accent color.
- Data Export.
- User Info Settings.
- SMS Limit and Feature Toggles.

### App Lock
- Biometric/PIN lock, opt-in toggle, secure lock logic.

### SMS Detail Page
- Sender/date, full message, clickable tag chips.
- NLP-like date parsing and "Set Reminder" button.

### Notifications & Reminders
- Schedules and manages reminders using flutter_local_notifications and timezone.

### Persistent Preferences
- Uses shared_preferences for user data, reminders, and tags.

### SMS Parsing
- Uses sms_advanced for robust SMS access and parsing (no telephony plugin required).
- Regex and NLP for extracting accounts, amounts, and dates from SMS.

### Android Native Features
- Full support for notifications, dynamic theming, and SMS access.

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- Android Studio / Xcode (for building to mobile)
- A device or emulator running Android 6.0+ or iOS 11.0+

### Installation
1. Clone the repository:
   ```sh
   git clone https://github.com/yourusername/moneylog.git
   cd moneylog
   ```
2. Install dependencies:
   ```sh
   flutter pub get
   ```
3. Run the app:
   ```sh
   flutter run
   ```

## 📦 Dependencies

- **Flutter SDK** - Cross-platform UI toolkit
- **Provider** - State management
- **shared_preferences** - Local data persistence
- **fl_chart** - Beautiful charts and graphs
- **sms_advanced** - SMS parsing and handling
- **flutter_local_notifications** - Local notifications
- **intl** - Internationalization and formatting
- **table_calendar** - Interactive calendar views
- **flutter_colorpicker** - Color selection
- **dynamic_color** - Material You theming

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 Privacy Policy

MoneyLog respects your privacy. All your financial data stays on your device and is never sent to our servers.

---

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for the full license text.

```
MIT License

Copyright (c) 2025 Your Name

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

For more details, explore the code in `lib/` directory.
