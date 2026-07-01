import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum CardDetectionMode { any, chip, magneticStripe, nfc }

enum CardReaderEventType {
  icInserted,
  magSwiped,
  nfcApproached,
  fingerprintDetected,
  fingerprintFailed,
  fingerprintError,
  pinpadEnter,
  pinpadCancel,
  pinpadClear,
  ledError,
  unknown,
}

class CardReaderEvent {
  const CardReaderEvent(this.type, {this.data});

  final CardReaderEventType type;
  final Map<dynamic, dynamic>? data;
}

class CardReaderService {
  CardReaderService._() {
    _channel.setMethodCallHandler(_handleNativeEvent);
  }

  static final CardReaderService instance = CardReaderService._();

  static const MethodChannel _channel = MethodChannel(
    'pinpad_terminal/card_reader',
  );

  final StreamController<CardReaderEvent> _events =
      StreamController<CardReaderEvent>.broadcast();

  Stream<CardReaderEvent> get events => _events.stream;

  Future<void> startDetection({
    CardDetectionMode mode = CardDetectionMode.any,
  }) async {
    try {
      await _invokeReader(
        'startCardDetection',
        null,
        const Duration(seconds: 3),
      );
    } on MissingPluginException {
      debugPrint('MethodChannel nativo do leitor não foi encontrado.');
    } on TimeoutException {
      debugPrint('Tempo esgotado ao iniciar detecção chip/tarja/NFC.');
    } catch (error) {
      debugPrint('Erro ao iniciar detecção chip/tarja/NFC: $error');
    }

    await _startPreferredDetection(mode);
  }

  Future<void> stopDetection() async {
    await Future.wait([
      _invokeOptionalReader('stopCardDetection'),
      _invokeOptionalReader('cancelCardDetection'),
      _invokeOptionalReader('stopMagneticCardDetection'),
      _invokeOptionalReader('stopMagCardDetection'),
      _invokeOptionalReader('stopMagStripeDetection'),
      _invokeOptionalReader('stopMsrDetection'),
      _invokeOptionalReader('stopNfcCardDetection'),
      _invokeOptionalReader('stopIcCardDetection'),
    ]);
  }

  Future<void> _startPreferredDetection(CardDetectionMode mode) async {
    final methods = switch (mode) {
      CardDetectionMode.any => const <String>[],
      CardDetectionMode.chip => const [
          'startIcCardDetection',
          'startChipCardDetection',
        ],
      CardDetectionMode.magneticStripe => const [
          'startMagneticCardDetection',
          'startMagCardDetection',
          'startMagStripeDetection',
          'startMsrDetection',
        ],
      CardDetectionMode.nfc => const [
          'startNfcCardDetection',
          'startContactlessCardDetection',
          'startPiccDetection',
        ],
    };

    for (final method in methods) {
      await _invokeOptionalReader(method);
    }
  }

  Future<void> startFingerprintDetection() async {
    try {
      await _channel.invokeMethod('startFingerprintDetection');
    } on MissingPluginException {
      debugPrint('MethodChannel nativo da biometria não foi encontrado.');
    } catch (error) {
      debugPrint('Erro ao iniciar biometria digital: $error');
    }
  }

  Future<void> stopFingerprintDetection() async {
    try {
      await _channel.invokeMethod('stopFingerprintDetection');
    } catch (_) {}
  }

  Future<void> setStatusLed(String color) async {
    try {
      await _channel.invokeMethod('setStatusLed', {'color': color});
    } on MissingPluginException {
      debugPrint('MethodChannel nativo do LED não foi encontrado.');
    } catch (error) {
      debugPrint('Erro ao alterar LED: $error');
    }
  }

  Future<void> ledOff() async => setStatusLed('off');

  Future<void> playFixedLedLoading() async {
    try {
      await _channel.invokeMethod('playFixedLedLoading');
    } on MissingPluginException {
      debugPrint('MethodChannel nativo do LED não foi encontrado.');
    } catch (error) {
      debugPrint('Erro ao executar loading dos LEDs: $error');
    }
  }

  Future<void> startFaceLedBlink() async {
    try {
      await _channel.invokeMethod('startFaceLedBlink');
    } on MissingPluginException {
      debugPrint('MethodChannel nativo do LED facial não foi encontrado.');
    } catch (error) {
      debugPrint('Erro ao piscar LED facial: $error');
    }
  }

  Future<void> stopFaceLedBlink() async {
    try {
      await _channel.invokeMethod('stopFaceLedBlink');
    } catch (_) {}
  }

  Future<void> testLed({
    required String target,
    required String color,
    String effect = 'solid',
    int? code,
    int? index,
    int? red,
    int? green,
    int? blue,
  }) async {
    try {
      await _channel.invokeMethod('testLed', {
        'target': target,
        'color': color,
        'effect': effect,
        if (code != null) 'code': code,
        if (index != null) 'index': index,
        if (red != null) 'red': red,
        if (green != null) 'green': green,
        if (blue != null) 'blue': blue,
      });
    } on MissingPluginException {
      debugPrint('MethodChannel nativo do LED não foi encontrado.');
    } catch (error) {
      debugPrint('Erro ao testar LED: $error');
    }
  }

  Future<dynamic> _invokeReader(
    String method, [
    Object? arguments,
    Duration timeout = const Duration(seconds: 1),
  ]) {
    return _channel.invokeMethod(method, arguments).timeout(timeout);
  }

  Future<void> _invokeOptionalReader(String method, [Object? arguments]) async {
    try {
      await _invokeReader(method, arguments);
    } on MissingPluginException {
      // Método opcional ausente no build nativo atual.
    } on TimeoutException {
      debugPrint('Tempo esgotado ao chamar $method no SDK do leitor.');
    } catch (_) {}
  }

  Future<dynamic> _handleNativeEvent(MethodCall call) async {
    final args = call.arguments;
    final data = args is Map ? args : null;

    switch (call.method) {
      case 'onCardInserted':
      case 'cardInserted':
      case 'onIcCardDetected':
      case 'onIcCardInserted':
      case 'onChipCardDetected':
      case 'onChipCardInserted':
      case 'onInsertCardDetected':
        _events.add(
          CardReaderEvent(CardReaderEventType.icInserted, data: data),
        );
        break;
      case 'onMagCardDetected':
      case 'onMagCardSwiped':
      case 'onMagneticCardRead':
      case 'onMagneticCardDetected':
      case 'onMagneticCardSwiped':
      case 'onMagStripeDetected':
      case 'onMagStripeRead':
      case 'onMagStripeSwiped':
      case 'onMagneticStripeDetected':
      case 'onMagneticStripeRead':
      case 'onMagneticStripeSwiped':
      case 'onSwipeCard':
      case 'onCardSwipe':
      case 'onCardSwiped':
      case 'cardSwiped':
      case 'magCardDetected':
      case 'magCardSwiped':
      case 'magneticCardRead':
      case 'magneticCardSwiped':
      case 'onMsrRead':
      case 'onMsrCardRead':
      case 'onMsrCardDetected':
      case 'msrCardRead':
        _events.add(CardReaderEvent(CardReaderEventType.magSwiped, data: data));
        break;
      case 'onNfcCardDetected':
      case 'onNfcCardApproached':
      case 'onContactlessCardDetected':
      case 'onNfcPollingDetected':
      case 'onContactlessDetected':
      case 'onPiccCardDetected':
      case 'onRfCardDetected':
        _events.add(
          CardReaderEvent(CardReaderEventType.nfcApproached, data: data),
        );
        break;
      case 'onFingerprintDetected':
      case 'onFingerDetected':
      case 'onFingerTouched':
        _events.add(
          CardReaderEvent(CardReaderEventType.fingerprintDetected, data: data),
        );
        break;
      case 'onFingerprintFailed':
      case 'onFingerprintCancelled':
        _events.add(
          CardReaderEvent(CardReaderEventType.fingerprintFailed, data: data),
        );
        break;
      case 'onFingerprintError':
        debugPrint('Erro biometria digital: $data');
        _events.add(
          CardReaderEvent(CardReaderEventType.fingerprintError, data: data),
        );
        break;
      case 'onPinpadEnter':
        _events.add(
          CardReaderEvent(CardReaderEventType.pinpadEnter, data: data),
        );
        break;
      case 'onPinpadCancel':
        _events.add(
          CardReaderEvent(CardReaderEventType.pinpadCancel, data: data),
        );
        break;
      case 'onPinpadClear':
        _events.add(
          CardReaderEvent(CardReaderEventType.pinpadClear, data: data),
        );
        break;
      case 'onLedError':
        debugPrint('Erro LED: $data');
        _events.add(CardReaderEvent(CardReaderEventType.ledError, data: data));
        break;
      default:
        final inferredType = _inferEventType(call.method, data);
        if (inferredType != null) {
          _events.add(CardReaderEvent(inferredType, data: data));
          return;
        }

        debugPrint('Evento desconhecido do SDK: ${call.method}');
        _events.add(CardReaderEvent(CardReaderEventType.unknown, data: data));
    }
  }

  CardReaderEventType? _inferEventType(
    String method,
    Map<dynamic, dynamic>? data,
  ) {
    final normalizedMethod = method.toLowerCase();
    final normalizedData = data == null ? '' : data.toString().toLowerCase();
    final source = '$normalizedMethod $normalizedData';

    if (source.contains('pinpad') && source.contains('enter')) {
      return CardReaderEventType.pinpadEnter;
    }
    if (source.contains('pinpad') && source.contains('cancel')) {
      return CardReaderEventType.pinpadCancel;
    }
    if (source.contains('pinpad') && source.contains('clear')) {
      return CardReaderEventType.pinpadClear;
    }
    if (source.contains('finger')) {
      return CardReaderEventType.fingerprintDetected;
    }
    if (source.contains('mag') ||
        source.contains('swipe') ||
        source.contains('msr') ||
        source.contains('tarja')) {
      return CardReaderEventType.magSwiped;
    }
    if (source.contains('nfc') ||
        source.contains('contactless') ||
        source.contains('picc') ||
        source.contains('rfcard')) {
      return CardReaderEventType.nfcApproached;
    }
    if (source.contains('insert') ||
        source.contains('chip') ||
        source.contains('iccard')) {
      return CardReaderEventType.icInserted;
    }

    return null;
  }
}
