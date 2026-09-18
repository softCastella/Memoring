import 'package:flutter/material.dart';

import '../state/app_controller.dart';
import 'decorate_screen.dart';
import 'memo_screen.dart';
import 'mood_screen.dart';
import 'settings_screen.dart';
import 'store/background_store_screen.dart';
import 'store/my_backgrounds_screen.dart';
import 'today_screen.dart';
import '../widgets/soft_bottom_bar.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.controller});

  final AppController controller;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          setState(() => _index = 0);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: IndexedStack(
            index: _index,
            children: [
              TodayScreen(
                controller: widget.controller,
                onOpenMood: _openMood,
              ),
              MoodScreen(controller: widget.controller),
              MemoScreen(controller: widget.controller),
              BackgroundStoreScreen(controller: widget.controller),
              SettingsScreen(
                controller: widget.controller,
                onOpenDecorate: _openDecorate,
                onOpenStore: () => setState(() => _index = 3),
                onOpenMyBackgrounds: _openMyBackgrounds,
              ),
            ],
          ),
        ),
        bottomNavigationBar: SoftBottomBar(
          index: _index,
          onChanged: (index) => setState(() => _index = index),
        ),
      ),
    );
  }

  Future<void> _openMood() {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: const Text('마음 기록'),
              centerTitle: true,
            ),
            body: MoodScreen(
              controller: widget.controller,
              showTitle: false,
            ),
          );
        },
      ),
    );
  }

  Future<void> _openStore() {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => BackgroundStoreScreen(
          controller: widget.controller,
        ),
      ),
    );
  }

  Future<void> _openMyBackgrounds() {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => MyBackgroundsScreen(
          controller: widget.controller,
        ),
      ),
    );
  }

  Future<void> _openDecorate() {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(title: const Text('꾸미기')),
            body: DecorateScreen(
              controller: widget.controller,
              onOpenStore: _openStore,
            ),
          );
        },
      ),
    );
  }
}
