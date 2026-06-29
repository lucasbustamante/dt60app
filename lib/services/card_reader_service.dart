import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum CardReaderEventType {
  icInserted,
  magSwiped,
  nfcApproached,
  fingerprintDetected,
  fingerprintFailed,
  fingerprintError,
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

  Future<void> startDetection() async {
    try {
      await _channel.invokeMethod('startCardDetection');
    } on MissingPluginException {
      debugPrint('MethodChannel nativo do leitor não foi encontrado.');
    } catch (error) {
      debugPrint('Erro ao iniciar detecção chip/tarja/NFC: $error');
    }
  }

  Future<void> stopDetection() async {
    try {
      await _channel.invokeMethod('stopCardDetection');
    } catch (_) {}
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
  }) async {
    try {
      await _channel.invokeMethod('testLed', {
        'target': target,
        'color': color,
        'effect': effect,
        if (code != null) 'code': code,
      });
    } on MissingPluginException {
      debugPrint('MethodChannel nativo do LED não foi encontrado.');
    } catch (error) {
      debugPrint('Erro ao testar LED: $error');
    }
  }

  Future<dynamic> _handleNativeEvent(MethodCall call) async {
    final args = call.arguments;
    final data = args is Map ? args : null;

    switch (call.method) {
      case 'onCardInserted':
      case 'cardInserted':
      case 'onIcCardDetected':
      case 'onIcCardInserted':
        _events.add(
          CardReaderEvent(CardReaderEventType.icInserted, data: data),
        );
        break;
      case 'onMagCardDetected':
      case 'onMagCardSwiped':
      case 'onMagneticCardRead':
      case 'magCardSwiped':
        _events.add(CardReaderEvent(CardReaderEventType.magSwiped, data: data));
        break;
      case 'onNfcCardDetected':
      case 'onNfcCardApproached':
      case 'onContactlessCardDetected':
      case 'onNfcPollingDetected':
      case 'onContactlessDetected':
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
      case 'onLedError':
        debugPrint('Erro LED: $data');
        _events.add(CardReaderEvent(CardReaderEventType.ledError, data: data));
        break;
      default:
        debugPrint('Evento desconhecido do SDK: ${call.method}');
        _events.add(CardReaderEvent(CardReaderEventType.unknown, data: data));
    }
  }
}
