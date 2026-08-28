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
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/widgets/application_info_panel.dart';
import 'package:flauncher/widgets/focus_keyboard_listener.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

const _validationKeys = [LogicalKeyboardKey.select, LogicalKeyboardKey.enter, LogicalKeyboardKey.gameButtonA];

class AppCard extends StatefulWidget {
  final Category category;
  final App application;
  final bool autofocus;
  final void Function(AxisDirection) onMove;
  final VoidCallback onMoveEnd;

  AppCard({
    Key? key,
    required this.category,
    required this.application,
    required this.autofocus,
    required this.onMove,
    required this.onMoveEnd,
  }) : super(key: key);

  @override
  _AppCardState createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _moving = false;
  MemoryImage? _imageProvider;

  ImageProvider _cachedMemoryImage(Uint8List bytes) {
    if (!listEquals(bytes, _imageProvider?.bytes)) {
      _imageProvider = MemoryImage(bytes);
    }
    return _imageProvider!;
  }

  @override
  Widget build(BuildContext context) => FocusKeyboardListener(
        onPressed: (key) => _onPressed(context, key),
        onLongPress: (key) => _onLongPress(context, key),
        builder: (context) {
          final hasFocus = Focus.of(context).hasFocus;
          return AspectRatio(
            aspectRatio: 16 / 9,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              transformAlignment: Alignment.center,
              transform: _scaleTransform(context),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: hasFocus
                    ? [
                        BoxShadow(
                          color: const Color(0xFF8AB4F8).withValues(alpha: 0.45),
                          blurRadius: 22,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Material(
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                color: const Color(0xFF181C26),
                elevation: 0,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    InkWell(
                      autofocus: widget.autofocus,
                      focusColor: Colors.transparent,
                      onTap: () => _onPressed(context, null),
                      onLongPress: () => _onLongPress(context, null),
                      child: widget.application.banner != null
                          ? Ink.image(image: _cachedMemoryImage(widget.application.banner!), fit: BoxFit.cover)
                          : _nonTvAppLayout(context),
                    ),
                    if (_moving) ..._arrows(),
                    IgnorePointer(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        opacity: hasFocus ? 0 : 0.08,
                        child: Container(color: Colors.black),
                      ),
                    ),
                    // High-definition focus border
                    IgnorePointer(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        decoration: BoxDecoration(
                          border: hasFocus
                              ? Border.all(color: Colors.white.withValues(alpha: 0.95), width: 2.5)
                              : null,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );

  Widget _nonTvAppLayout(BuildContext context) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2A3040), Color(0xFF141722)],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: widget.application.icon != null
                    ? Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image(
                          image: _cachedMemoryImage(widget.application.icon!),
                          fit: BoxFit.contain,
                        ),
                      )
                    : const Icon(Icons.android_rounded, size: 44, color: Color(0xFF8AB4F8)),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.75),
                      Colors.black.withValues(alpha: 0.95),
                    ],
                  ),
                ),
                child: Text(
                  widget.application.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFF1F3F4),
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
          ],
        ),
      );

  Matrix4 _scaleTransform(BuildContext context) {
    final scale = _moving
        ? 1.0
        : Focus.of(context).hasFocus
            ? 1.07
            : 1.0;
    return Matrix4.diagonal3Values(scale, scale, 1.0);
  }

  List<Widget> _arrows() => [
        _arrow(Alignment.centerLeft, Icons.keyboard_arrow_left),
        _arrow(Alignment.topCenter, Icons.keyboard_arrow_up),
        _arrow(Alignment.bottomCenter, Icons.keyboard_arrow_down),
        _arrow(Alignment.centerRight, Icons.keyboard_arrow_right),
      ];

  Widget _arrow(Alignment alignment, IconData icon) => Align(
        alignment: alignment,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF8AB4F8).withValues(alpha: 0.9),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 16,
              color: const Color(0xFF0E1117),
            ),
          ),
        ),
      );

  KeyEventResult _onPressed(BuildContext context, LogicalKeyboardKey? key) {
    if (_moving) {
      WidgetsBinding.instance.addPostFrameCallback((_) => Scrollable.ensureVisible(context,
          alignment: 0.1, duration: Duration(milliseconds: 100), curve: Curves.easeInOut));
      if (key == LogicalKeyboardKey.arrowLeft) {
        widget.onMove(AxisDirection.left);
      } else if (key == LogicalKeyboardKey.arrowUp) {
        widget.onMove(AxisDirection.up);
      } else if (key == LogicalKeyboardKey.arrowRight) {
        widget.onMove(AxisDirection.right);
      } else if (key == LogicalKeyboardKey.arrowDown) {
        widget.onMove(AxisDirection.down);
      } else if (_validationKeys.contains(key)) {
        setState(() => _moving = false);
        widget.onMoveEnd();
      }
      return KeyEventResult.handled;
    } else if (_validationKeys.contains(key)) {
      context.read<AppsService>().launchApp(widget.application);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _onLongPress(BuildContext context, LogicalKeyboardKey? key) {
    if (!_moving && (key == null || longPressableKeys.contains(key))) {
      _showPanel(context);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _showPanel(BuildContext context) async {
    final result = await showDialog<ApplicationInfoPanelResult>(
      context: context,
      builder: (context) => ApplicationInfoPanel(
        category: widget.category,
        application: widget.application,
      ),
    );
    if (result == ApplicationInfoPanelResult.reorderApp) {
      setState(() => _moving = true);
    }
  }
}
