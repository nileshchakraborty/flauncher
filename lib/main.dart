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

import 'dart:async';

import 'package:flauncher/database.dart';
import 'package:flauncher/flauncher_channel.dart';
import 'package:flauncher/unsplash_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unsplash_client/unsplash_client.dart';

import 'flauncher_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint("[FLauncher Boot] WidgetsFlutterBinding initialized");

  runZonedGuarded<void>(() async {
    debugPrint("[FLauncher Boot] Starting app initialization sequence");
    final sharedPreferences = await SharedPreferences.getInstance();
    debugPrint("[FLauncher Boot] SharedPreferences loaded");
    final imagePicker = ImagePicker();
    final fLauncherChannel = FLauncherChannel();
    final fLauncherDatabase = FLauncherDatabase(connect());
    debugPrint("[FLauncher Boot] Database connected");
    final unsplashService = UnsplashService(
      UnsplashClient(
        settings: ClientSettings(
          debug: kDebugMode,
          credentials: AppCredentials(
            accessKey: "",
            secretKey: "",
          ),
        ),
      ),
    );
    debugPrint("[FLauncher Boot] Launching FLauncherApp widget");
    runApp(
      FLauncherApp(
        sharedPreferences,
        imagePicker,
        fLauncherChannel,
        fLauncherDatabase,
        unsplashService,
      ),
    );
  }, (error, stackTrace) {
    debugPrint("[FLauncher Boot Error] Uncaught error: $error\n$stackTrace");
  });
}
