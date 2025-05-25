# Streak Zero

A minimalist streak tracking app for daily habits and goals. Track your progress towards daily targets and maintain your streaks with a clean, simple interface.

## Features

- Create multiple streaks with custom names and targets
- Track daily progress with visual progress bars
- View monthly streak history with 31-day tracking
- Persistent storage of your streaks
- Clean, minimalist Material Design 3 interface

## Getting Started

### Prerequisites

- Flutter SDK (version 3.7.2 or higher)
- Dart SDK
- Android Studio / VS Code with Flutter extensions

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/streak_zero.git
```

2. Navigate to the project directory:
```bash
cd streak_zero
```

3. Install dependencies:
```bash
flutter pub get
```

4. Run the app:
```bash
flutter run
```

## Usage

### Adding a New Streak

1. Tap the + button in the bottom right corner
2. Enter a name for your streak (e.g., "Water Intake")
3. Set your daily target (e.g., "3" for 3 liters of water)
4. Tap "Add" to create the streak

### Updating Progress

1. Tap the edit (pencil) icon on any streak card
2. Enter your current progress
3. Tap "Update" to save

### Understanding the Interface

Each streak card shows:
- Streak name
- Progress bar showing current progress towards daily target
- Current progress / target value
- 31 small blocks representing the month's streak (filled when target is met)

## Development

### Project Structure

- `lib/main.dart` - Main application code
- `pubspec.yaml` - Project dependencies and configuration

### Dependencies

- `provider` - State management
- `shared_preferences` - Local storage
- `intl` - Internationalization and formatting

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Flutter team for the amazing framework
- Material Design team for the beautiful design system
