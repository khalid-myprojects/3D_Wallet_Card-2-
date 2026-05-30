import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/card_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait + immersive mode for premium feel
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF050507),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const NexusCardApp());
}

class NexusCardApp extends StatelessWidget {
  const NexusCardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CardProvider()),
      ],
      child: MaterialApp(
        title: 'Nexus Cards',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF050507),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFD4A843),
            surface: Color(0xFF0D0D0D),
            background: Color(0xFF050507),
          ),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        home: const _AppShell(),
      ),
    );
  }
}

class _AppShell extends StatefulWidget {
  const _AppShell();

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> with SingleTickerProviderStateMixin {
  bool _splashDone = false;
  late AnimationController _transitionController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _transitionController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _transitionController.dispose();
    super.dispose();
  }

  void _onSplashComplete() {
    setState(() => _splashDone = true);
    _transitionController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Home screen (fades in under splash)
        if (_splashDone)
          FadeTransition(
            opacity: _fadeIn,
            child: const HomeScreen(),
          ),

        // Splash screen on top
        if (!_splashDone)
          SplashScreen(onComplete: _onSplashComplete),
      ],
    );
  }
}
