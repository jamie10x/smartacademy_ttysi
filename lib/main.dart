import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Make sure this is imported!
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/supabase_constants.dart';
import 'core/router/router.dart';
import 'core/theme/app_theme.dart';

final class LoggerObserver extends ProviderObserver {
}
@override
void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
    ) {
  debugPrint('''
[Riverpod] State Changed:
  Provider: ${context.provider.name ?? context.provider.runtimeType}
  New Value: $newValue
''');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConstants.url,
    anonKey: SupabaseConstants.anonKey,
  );

  runApp(
    ProviderScope(
      observers: [LoggerObserver()], // Add the observer here
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'TTYESI Social',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}