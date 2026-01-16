import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'screens/dashboard_screen.dart';
import 'providers/scan_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Create and initialize provider
  final scanProvider = ScanProvider();
  await scanProvider.initialize();

  runApp(VulnScannerApp(scanProvider: scanProvider));
}

class VulnScannerApp extends StatelessWidget {
  final ScanProvider scanProvider;

  const VulnScannerApp({super.key, required this.scanProvider});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: scanProvider,
      child: MaterialApp(
        title: 'Developers',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme.copyWith(
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: FadePageTransitionsBuilder(),
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              TargetPlatform.windows: FadePageTransitionsBuilder(),
              TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
              TargetPlatform.linux: FadePageTransitionsBuilder(),
            },
          ),
        ),
        home: const DashboardScreen(),
      ),
    );
  }
}

/// Custom fade page transition
class FadePageTransitionsBuilder extends PageTransitionsBuilder {
  const FadePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
            .animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
        child: child,
      ),
    );
  }
}
