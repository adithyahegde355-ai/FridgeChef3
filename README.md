# Fridge Chef

Type the ingredients you have and get Indian recipes with big photos and a step-by-step cooking mode. Flutter, Android and iOS.

## Run it

```bash
cd fridge_chef
flutter create . --platforms=android,ios   # generates android/ and ios/ around the existing code
flutter pub get
flutter run
```

For a release build on Android, add this line inside `<manifest>` in `android/app/src/main/AndroidManifest.xml` (photo lookups need it):

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

Run the tests with `flutter test`.

## How it works

- **Recipes** live in `assets/recipes.json` (29 Indian dishes). Each ingredient is marked as a pantry staple or optional, and steps carry an optional timer length in seconds.
- **Matching** (`lib/services/matcher.dart`) ranks recipes by fewest missing ingredients. It understands Hindi and alternate names (aloo, dahi, palak, anda) and plurals.
- **Photos** (`lib/services/photo_service.dart`) look each dish up on Wikipedia by name. If the page has no usable image, the app shows a coloured card with the dish emoji and name. Found photos are cached on the phone, and misses are retried after a week.
- **Cooking mode** keeps the screen awake, shows one big step at a time, and runs timers that keep counting when you swipe to another step.
- The fridge, switches and saved recipes persist on the device.

## Adding a dish

Add an entry to `assets/recipes.json`. Set `"wiki"` to the exact Wikipedia article title if the dish name alone does not find the right page, or `null` to try the dish name.

## Photo credits

Photos come from Wikipedia and Wikimedia Commons under their individual licences. The app labels each photo "Photo: Wikipedia". Before publishing to a store, add per-image attribution.
