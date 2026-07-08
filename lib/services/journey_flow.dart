import '../models/bank_product.dart';
import 'card_reader_service.dart';

class JourneyFlow {
  const JourneyFlow._();

  static const standbyRoute = '/';
  static const magneticStripeRoute = '/cartao';
  static const passwordRoute = '/senha';
  static const chipRoute = '/inserir-cartao';
  static const faceBiometryRoute = '/biometria';
  static const fingerprintBiometryRoute = '/biometria-digital';
  static const nfcRoute = '/aproximar';
  static const processingRoute = '/processando';
  static const successRoute = '/sucesso';
  static const errorRoute = '/erro';

  static String paymentRouteFor(PaymentMethod method) {
    return switch (method) {
      PaymentMethod.nfc => nfcRoute,
      PaymentMethod.chip => chipRoute,
      PaymentMethod.magneticStripe => magneticStripeRoute,
    };
  }

  static String authenticationRouteFor(AuthenticationMethod method) {
    return switch (method) {
      AuthenticationMethod.faceBiometry => faceBiometryRoute,
      AuthenticationMethod.fingerprintBiometry => fingerprintBiometryRoute,
      AuthenticationMethod.password => passwordRoute,
    };
  }

  static bool matchesPaymentEvent(
    PaymentMethod method,
    CardReaderEventType eventType,
  ) {
    return switch (method) {
      PaymentMethod.nfc => eventType == CardReaderEventType.nfcApproached,
      PaymentMethod.chip => eventType == CardReaderEventType.icInserted,
      PaymentMethod.magneticStripe =>
        eventType == CardReaderEventType.magSwiped,
    };
  }

  static String paymentTitle(PaymentMethod method) {
    return switch (method) {
      PaymentMethod.nfc => 'Aproxime\no cartão',
      PaymentMethod.chip => 'Insira o cartão\n(com chip)',
      PaymentMethod.magneticStripe => 'Passe\no cartão',
    };
  }

  static String paymentActionLabel(PaymentMethod method) {
    return switch (method) {
      PaymentMethod.nfc => 'Aguardando aproximação',
      PaymentMethod.chip => 'Aguardando inserção',
      PaymentMethod.magneticStripe => 'Aguardando leitura da tarja',
    };
  }
}

class AccountOpeningStepArgs {
  const AccountOpeningStepArgs({
    required this.nextRoute,
    this.nextArguments,
    this.title,
    this.messageStart,
    this.messageHighlight,
    this.messageEnd,
    this.panelTitle,
    this.requirePasswordConfirmation = false,
  });

  final String nextRoute;
  final Object? nextArguments;
  final String? title;
  final String? messageStart;
  final String? messageHighlight;
  final String? messageEnd;
  final String? panelTitle;
  final bool requirePasswordConfirmation;
}
