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

import 'dart:typed_data';

import 'package:flauncher/custom_traversal_policy.dart';
import 'package:flauncher/database.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/wallpaper_service.dart';
import 'package:flauncher/widgets/apps_grid.dart';
import 'package:flauncher/widgets/category_row.dart';
import 'package:flauncher/widgets/settings/settings_panel.dart';
import 'package:flauncher/widgets/time_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FLauncher extends StatelessWidget {
  @override
  Widget build(BuildContext context) => FocusTraversalGroup(
        policy: RowByRowTraversalPolicy(),
        child: Stack(
          children: [
            // Background Wallpaper
            Consumer<WallpaperService>(
              builder: (_, wallpaper, __) => _wallpaper(context, wallpaper.wallpaperBytes, wallpaper.gradient.gradient),
            ),
            // Cinematic Scrim Overlay
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.60),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.70),
                      ],
                      stops: const [0.0, 0.40, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            Scaffold(
              backgroundColor: Colors.transparent,
              appBar: _appBar(context),
              body: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Consumer<AppsService>(
                  builder: (context, appsService, _) => appsService.initialized
                      ? SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: _categories(appsService.categoriesWithApps),
                        )
                      : _emptyState(context),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _categories(List<CategoryWithApps> categoriesWithApps) => Column(
        children: categoriesWithApps.map((categoryWithApps) {
          switch (categoryWithApps.category.type) {
            case CategoryType.row:
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: CategoryRow(
                    key: Key(categoryWithApps.category.id.toString()),
                    category: categoryWithApps.category,
                    applications: categoryWithApps.applications),
              );
            case CategoryType.grid:
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: AppsGrid(
                    key: Key(categoryWithApps.category.id.toString()),
                    category: categoryWithApps.category,
                    applications: categoryWithApps.applications),
              );
          }
        }).toList(),
      );

  PreferredSizeWidget _appBar(BuildContext context) => PreferredSize(
        preferredSize: const Size.fromHeight(68),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                // Left: Google TV Style Search / Discover Pill
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    focusColor: const Color(0xFF8AB4F8).withValues(alpha: 0.3),
                    onTap: () {
                      // Focus or open settings
                      showDialog(context: context, builder: (_) => SettingsPanel());
                    },
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E222D).withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_rounded, size: 18, color: Color(0xFF8AB4F8)),
                          SizedBox(width: 8),
                          Text(
                            "Apps & Channels",
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFFE8EAED),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                // Right: Ambient Quick Controls + Tabular Clock
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Settings Button in Frosted Glass Pill
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        focusColor: const Color(0xFF8AB4F8).withValues(alpha: 0.35),
                        onTap: () => showDialog(context: context, builder: (_) => SettingsPanel()),
                        child: Container(
                          height: 38,
                          width: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF1E222D).withValues(alpha: 0.75),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                          ),
                          child: const Center(
                            child: Icon(Icons.settings_outlined, size: 18, color: Color(0xFFE8EAED)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Clock Widget
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E222D).withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: TimeWidget(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

  Widget _wallpaper(BuildContext context, Uint8List? wallpaperImage, Gradient gradient) {
    final size = MediaQuery.sizeOf(context);
    return wallpaperImage != null
        ? Image.memory(
            wallpaperImage,
            key: const Key("background"),
            fit: BoxFit.cover,
            height: size.height,
            width: size.width,
          )
        : Container(key: const Key("background"), decoration: BoxDecoration(gradient: gradient));
  }

  Widget _emptyState(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8AB4F8)),
            ),
            const SizedBox(height: 20),
            Text(
              "Loading Applications...",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFFE8EAED),
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      );
}
