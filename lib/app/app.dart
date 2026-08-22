import 'package:chambapp_mobile/app/router.dart';
import 'package:chambapp_mobile/core/constants/app_constants.dart';
import 'package:chambapp_mobile/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChambappApp extends ConsumerWidget {
  const ChambappApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: AppConstants.appName,
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    routerConfig: ref.watch(routerProvider),
  );
}
