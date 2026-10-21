import 'dart:async';

import 'package:ecommerce_app/home_screen.dart';
import 'package:ecommerce_app/provider/auth_provider.dart';
import 'package:ecommerce_app/screens/login_screen.dart';
import 'package:ecommerce_app/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Shopesphere',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const _AppFlowScreen(),
    );
  }
}

class _AppFlowScreen extends ConsumerStatefulWidget {
  const _AppFlowScreen();

  @override
  ConsumerState<_AppFlowScreen> createState() => _AppFlowScreenState();
}

class _AppFlowScreenState extends ConsumerState<_AppFlowScreen> {
  bool _splashFinished = false;

  @override
  void initState() {
    super.initState();
    unawaited(_initializeApp());
  }

  Future<void> _initializeApp() async {
    await Future.wait<void>([
      ref.read(authProvider.notifier).restoreSession(),
      Future<void>.delayed(const Duration(milliseconds: 1800)),
    ]);
    if (mounted) setState(() => _splashFinished = true);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    if (!_splashFinished || authState.isRestoringSession) {
      return const SplashScreen();
    }
    if (authState.isAuthenticated) return const HomeScreen();
    return const LoginScreen();
  }
}
