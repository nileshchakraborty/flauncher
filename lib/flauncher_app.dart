/*
 * FLauncher
 * Copyright (C) 2021  Étienne Fesser
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:flauncher/actions.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/ticker_model.dart';
import 'package:flauncher/providers/wallpaper_service.dart';
import 'package:flauncher/unsplash_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'database.dart';
import 'flauncher.dart';
import 'flauncher_channel.dart';

class FLauncherApp extends StatelessWidget {
  final SharedPreferences _sharedPreferences;
  final ImagePicker _imagePicker;
  final FLauncherChannel _fLauncherChannel;
  final FLauncherDatabase _fLauncherDatabase;
  final UnsplashService _unsplashService;

  FLauncherApp(
    this._sharedPreferences,
    this._imagePicker,
    this._fLauncherChannel,
    this._fLauncherDatabase,
    this._unsplashService,
  );

  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          ChangeNotifierProvider(
              create: (_) => SettingsService(_sharedPreferences),
              lazy: false),
          ChangeNotifierProvider(create: (_) => AppsService(_fLauncherChannel, _fLauncherDatabase)),
          ChangeNotifierProxyProvider<SettingsService, WallpaperService>(
              create: (_) => WallpaperService(_imagePicker, _fLauncherChannel, _unsplashService),
              update: (_, settingsService, wallpaperService) => wallpaperService!..settingsService = settingsService),
          Provider<TickerModel>(create: (context) => TickerModel(null))
        ],
        child: MaterialApp(
          shortcuts: {
            ...WidgetsApp.defaultShortcuts,
            SingleActivator(LogicalKeyboardKey.select): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.gameButtonB): PrioritizedIntents(orderedIntents: [
              DismissIntent(),
              BackIntent(),
            ]),
          },
          actions: {
            ...WidgetsApp.defaultActions,
            DirectionalFocusIntent: SoundFeedbackDirectionalFocusAction(context),
          },
          title: 'FLauncher',
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              brightness: Brightness.dark,
              seedColor: const Color(0xFF8AB4F8),
              surface: const Color(0xFF0E1117),
              onSurface: const Color(0xFFF1F3F4),
              surfaceContainerHighest: const Color(0xFF1E222D),
              primary: const Color(0xFF8AB4F8),
              secondary: const Color(0xFF80CBC4),
            ),
            scaffoldBackgroundColor: const Color(0xFF0E1117),
            cardTheme: CardThemeData(
              color: const Color(0xFF1A1E29),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: const Color(0xFF151821).withValues(alpha: 0.92),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF8AB4F8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            appBarTheme: const AppBarTheme(
              elevation: 0,
              backgroundColor: Colors.transparent,
              scrolledUnderElevation: 0,
            ),
            inputDecorationTheme: InputDecorationTheme(
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF8AB4F8), width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0x33FFFFFF)),
              ),
              labelStyle: const TextStyle(color: Color(0xFF9AA0A6)),
            ),
          ),
          home: Builder(
            builder: (context) => PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, result) async {
                if (didPop) return;
                final shouldPop = await shouldPopScope(context);
                if (!shouldPop && context.mounted) {
                  context.read<AppsService>().startAmbientMode();
                }
              },
              child: Actions(actions: {BackIntent: BackAction(context, systemNavigator: true)}, child: FLauncher()),
            ),
          ),
        ),
      );
}
