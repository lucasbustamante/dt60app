import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/bank_product.dart';
import 'screens/account_opening_screen.dart';
import 'screens/card_payment_screen.dart';
import 'screens/docinho_screen.dart';
import 'screens/error_screen.dart';
import 'screens/face_biometry_screen.dart';
import 'screens/fingerprint_biometry_screen.dart';
import 'screens/contactless_card_screen.dart';
import 'screens/credit_consigned_screen.dart';
import 'screens/insert_card_screen.dart';
import 'screens/led_test_screen.dart';
import 'screens/password_screen.dart';
import 'screens/processing_screen.dart';
import 'screens/product_offer_screen.dart';
import 'screens/standby_screen.dart';
import 'screens/success_screen.dart';
import 'services/card_reader_service.dart';
import 'services/terminal_command_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const PinpadTerminalApp());
}

class AppRoutes {
  static const standby = '/';
  static const card = '/cartao';
  static const password = '/senha';
  static const insertCard = '/inserir-cartao';
  static const faceBiometry = '/biometria';
  static const fingerprintBiometry = '/biometria-digital';
  static const contactlessCard = '/aproximar';
  static const processing = '/processando';
  static const success = '/sucesso';
  static const error = '/erro';
  static const docinho = '/docinho';
  static const led = '/led';
  static const productOffer = '/oferta-produto';
  static const accountOpening = '/abertura-conta';
  static const creditConsigned = '/credito-consignado';
}

class PinpadTerminalApp extends StatefulWidget {
  const PinpadTerminalApp({super.key});

  @override
  State<PinpadTerminalApp> createState() => _PinpadTerminalAppState();
}

class _PinpadTerminalAppState extends State<PinpadTerminalApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late final TerminalCommandService _commandService;

  @override
  void initState() {
    super.initState();
    _commandService = TerminalCommandService(onCommand: _handleCommand);
    unawaited(_commandService.start());
  }

  @override
  void dispose() {
    _commandService.dispose();
    super.dispose();
  }

  void _handleCommand(TerminalCommand command) {
    final ledColor = command.ledColor;
    if (ledColor != null) {
      unawaited(CardReaderService.instance.setStatusLed(ledColor));
      return;
    }

    if (command == TerminalCommand.ledOff) {
      unawaited(CardReaderService.instance.ledOff());
      return;
    }

    if (command == TerminalCommand.ledLoading) {
      unawaited(CardReaderService.instance.playFixedLedLoading());
      return;
    }

    if (command == TerminalCommand.creditoConsignado) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final navigator = _navigatorKey.currentState;
        if (navigator == null) return;
        navigator.pushNamedAndRemoveUntil(AppRoutes.creditConsigned, (_) => false);
      });
      return;
    }

    if (command == TerminalCommand.aberturaConta) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final navigator = _navigatorKey.currentState;
        if (navigator == null) return;
        navigator.pushNamedAndRemoveUntil(AppRoutes.accountOpening, (_) => false);
      });
      return;
    }

    final productKind = command.productKind;
    if (productKind != null) {
      final product = BankProductCatalog.byKind(productKind);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final navigator = _navigatorKey.currentState;
        if (navigator == null) return;
        navigator.pushNamedAndRemoveUntil(
          AppRoutes.productOffer,
          (_) => false,
          arguments: product,
        );
      });
      return;
    }

    final route = _routeFor(command);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = _navigatorKey.currentState;
      if (navigator == null) return;
      navigator.pushNamedAndRemoveUntil(route, (_) => false);
    });
  }

  String _routeFor(TerminalCommand command) {
    switch (command) {
      case TerminalCommand.standby:
        return AppRoutes.standby;
      case TerminalCommand.cartao:
        return AppRoutes.card;
      case TerminalCommand.senha:
        return AppRoutes.password;
      case TerminalCommand.inserirCartao:
        return AppRoutes.insertCard;
      case TerminalCommand.biometria:
        return AppRoutes.faceBiometry;
      case TerminalCommand.biometriaDigital:
        return AppRoutes.fingerprintBiometry;
      case TerminalCommand.aproximar:
        return AppRoutes.contactlessCard;
      case TerminalCommand.sucesso:
        return AppRoutes.success;
      case TerminalCommand.erro:
        return AppRoutes.error;
      case TerminalCommand.docinho:
        return AppRoutes.docinho;
      case TerminalCommand.led:
        return AppRoutes.led;
      case TerminalCommand.seguroPet:
      case TerminalCommand.seguroBolsaProtegida:
      case TerminalCommand.assistenciaSaude:
      case TerminalCommand.protecaoCartao:
      case TerminalCommand.assistenciaResidencial:
      case TerminalCommand.seguroCelular:
      case TerminalCommand.aberturaConta:
      case TerminalCommand.creditoConsignado:
      case TerminalCommand.ledRed:
      case TerminalCommand.ledGreen:
      case TerminalCommand.ledBlue:
      case TerminalCommand.ledYellow:
      case TerminalCommand.ledPurple:
      case TerminalCommand.ledWhite:
      case TerminalCommand.ledOff:
      case TerminalCommand.ledLoading:
        return AppRoutes.standby;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Terminal Pinpad',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      navigatorKey: _navigatorKey,
      initialRoute: AppRoutes.standby,
      routes: {
        AppRoutes.standby: (_) => const StandbyScreen(),
        AppRoutes.card: (_) => const CardPaymentScreen(),
        AppRoutes.password: (_) => const PasswordScreen(),
        AppRoutes.insertCard: (_) => const InsertCardScreen(),
        AppRoutes.faceBiometry: (_) => const FaceBiometryScreen(),
        AppRoutes.fingerprintBiometry: (_) => const FingerprintBiometryScreen(),
        AppRoutes.contactlessCard: (_) => const ContactlessCardScreen(),
        AppRoutes.processing: (_) => const ProcessingScreen(),
        AppRoutes.success: (_) => const SuccessScreen(),
        AppRoutes.error: (_) => const ErrorScreen(),
        AppRoutes.docinho: (_) => const DocinhoScreen(),
        AppRoutes.led: (_) => const LedTestScreen(),
        AppRoutes.accountOpening: (_) => const AccountOpeningScreen(),
        AppRoutes.creditConsigned: (_) => const CreditConsignedScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.productOffer) {
          final product = settings.arguments;
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => ProductOfferScreen(
              product: product is BankProduct
                  ? product
                  : BankProductCatalog.byKind(BankProductKind.pet),
            ),
          );
        }
        return null;
      },
    );
  }
}
