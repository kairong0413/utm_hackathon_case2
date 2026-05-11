# GX Finance Cat

GX Finance Cat is a gamified personal finance app that helps students build better saving habits through a virtual cat companion. Users record savings and spending, earn Meow Points, level up their cat, unlock room decorations, and receive weekly financial feedback.
# Presentation Video link
https://youtu.be/edrlWF2KYoo

## APK File
[Download APK](my_app/build/app/outputs/flutter-apk/GXFinancialCat.apk)


## Main Features

### Login And Signup

- Clean login and signup page.
- Supports new user registration and returning user login.
- Attractive visual design that matches the cat finance theme.

### Cat Home Page

- Shows the user's cat, mood, level, and room.
- Cat reacts to user financial behavior.
- Cat can move to different room areas to sleep, eat, play, or idle.
- Room upgrades unlock as the user levels up.

### Transactions

- Users can add savings and spending records.
- Saving improves progress, XP, Meow Points, and cat mood.
- Overspending and BNPL behavior can negatively affect the cat.
- Users can edit or delete transactions to fix mistakes.

### Inventory And Shop

- Users can buy cat items using Meow Points.
- Bought items appear in the inventory.
- Users can equip up to two bought items at one time.
- Equipped items appear visually on the cat.
- Level-up room rewards stay permanently and do not need to be equipped.
- Some shop items are locked until the user reaches the required level or points.

### Weekly Report

- Analyzes weekly performance based on saving, spending, risk, and streak.
- Gives performance-based rewards instead of a fixed reward.
- Weekly checkup can only be completed once per week.
- Helps users understand how to improve their financial habits.

### Community / Cafe

- Users can search and add friends.
- Friend profiles show cat name, mood, level, and equipped items.
- Encourages friendly comparison and motivation.

### User And Cat Profile

- User profile shows account and progress details.
- Cat profile shows cat name, breed, mood, level, and current style.
- Cat name and profile changes update across the app.

## Target Users

- Students who want to manage money in a simple and fun way.
- Young adults who struggle with overspending or BNPL habits.
- Users who enjoy pets, games, rewards, and social progress.
- Schools, universities, or financial literacy programs that want to encourage better money habits.

## Impact

- Makes financial tracking less boring and more engaging.
- Encourages consistent saving habits.
- Helps users notice overspending and BNPL risk earlier.
- Uses cat mood, rewards, levels, and room upgrades as visual feedback.
- Supports financial literacy through small daily actions.

## Tech Stack

- Flutter: cross-platform mobile app development.
- Dart: application logic and UI code.
- Firebase Authentication: login and signup.
- Cloud Firestore: user, cat, finance, transaction, and friend data storage.
- Firebase Storage: prepared for media or asset storage.
- Firebase AI: prepared for future intelligent finance guidance.
- Custom Flutter painters: cat room, cat visuals, item shapes, and animation effects.
- Material Design: app layout, navigation, forms, and controls.

## Project Structure

```text
lib/
  app/                App startup and backend connection
  models/             User, cat, finance, transaction, and friend models
  screens/            Login, adoption, home, profile, and feature screens
  services/           Firebase and backend service logic
  widgets/            Reusable UI and cat room scene widgets

assets/
  icons/              App icon source image

release_apk/          Place release APK file here
```

## How To Run

```bash
flutter pub get
flutter run
```

## How To Build Release APK

```bash
flutter build apk --release
```

After building, the APK will be generated at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

