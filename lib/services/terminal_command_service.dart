import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/bank_product.dart';

enum TerminalCommand {
  standby('standby'),
  cartao('cartao'),
  senha('senha'),
  inserirCartao('inserir_cartao'),
  biometria('biometria'),
  biometriaDigital('biometria_digital'),
  aproximar('aproximar'),
  sucesso('sucesso'),
  erro('erro'),
  docinho('docinho'),
  led('led'),
  seguroPet('seguro_pet'),
  seguroBolsaProtegida('seguro_bolsa_protegida'),
  assistenciaSaude('assistencia_saude'),
  protecaoCartao('protecao_cartao'),
  assistenciaResidencial('assistencia_residencial'),
  seguroCelular('seguro_celular'),
  ledRed('led_red'),
  ledGreen('led_green'),
  ledBlue('led_blue'),
  ledYellow('led_yellow'),
  ledPurple('led_purple'),
  ledWhite('led_white'),
  ledOff('led_off'),
  ledLoading('led_loading');

  const TerminalCommand(this.value);

  final String value;

  BankProductKind? get productKind {
    switch (this) {
      case TerminalCommand.seguroPet:
        return BankProductKind.pet;
      case TerminalCommand.seguroBolsaProtegida:
        return BankProductKind.protectedBag;
      case TerminalCommand.assistenciaSaude:
        return BankProductKind.health;
      case TerminalCommand.protecaoCartao:
        return BankProductKind.cardProtection;
      case TerminalCommand.assistenciaResidencial:
        return BankProductKind.homeAssistance;
      case TerminalCommand.seguroCelular:
        return BankProductKind.phoneInsurance;
      case TerminalCommand.standby:
      case TerminalCommand.cartao:
      case TerminalCommand.senha:
      case TerminalCommand.inserirCartao:
      case TerminalCommand.biometria:
      case TerminalCommand.biometriaDigital:
      case TerminalCommand.aproximar:
      case TerminalCommand.sucesso:
      case TerminalCommand.erro:
      case TerminalCommand.docinho:
      case TerminalCommand.led:
      case TerminalCommand.ledRed:
      case TerminalCommand.ledGreen:
      case TerminalCommand.ledBlue:
      case TerminalCommand.ledYellow:
      case TerminalCommand.ledPurple:
      case TerminalCommand.ledWhite:
      case TerminalCommand.ledOff:
      case TerminalCommand.ledLoading:
        return null;
    }
  }

  String? get ledColor {
    switch (this) {
      case TerminalCommand.ledRed:
        return 'red';
      case TerminalCommand.ledGreen:
        return 'green';
      case TerminalCommand.ledBlue:
        return 'blue';
      case TerminalCommand.ledYellow:
        return 'yellow';
      case TerminalCommand.ledPurple:
        return 'purple';
      case TerminalCommand.ledWhite:
        return 'white';
      case TerminalCommand.standby:
      case TerminalCommand.cartao:
      case TerminalCommand.senha:
      case TerminalCommand.inserirCartao:
      case TerminalCommand.biometria:
      case TerminalCommand.biometriaDigital:
      case TerminalCommand.aproximar:
      case TerminalCommand.sucesso:
      case TerminalCommand.erro:
      case TerminalCommand.docinho:
      case TerminalCommand.led:
      case TerminalCommand.seguroPet:
      case TerminalCommand.seguroBolsaProtegida:
      case TerminalCommand.assistenciaSaude:
      case TerminalCommand.protecaoCartao:
      case TerminalCommand.assistenciaResidencial:
      case TerminalCommand.seguroCelular:
      case TerminalCommand.ledOff:
      case TerminalCommand.ledLoading:
        return null;
    }
  }

  static TerminalCommand? parse(String? raw) {
    if (raw == null) return null;

    final normalized = _normalize(raw);

    switch (normalized) {
      case 'standby':
      case 'carousel':
      case 'carrossel':
      case 'show_carousel':
      case 'show_carrossel':
      case 'show_standby':
        return TerminalCommand.standby;

      case 'cartao':
      case 'card':
      case 'passar_cartao':
      case 'tarja':
      case 'tarja_magnetica':
      case 'show_card':
      case 'show_cartao':
      case 'show_tarja':
        return TerminalCommand.cartao;

      case 'senha':
      case 'password':
      case 'pin':
      case 'show_password':
      case 'show_senha':
        return TerminalCommand.senha;

      case 'inserir_cartao':
      case 'insert_card':
      case 'chip':
      case 'show_insert_card':
      case 'show_inserir_cartao':
      case 'show_chip':
        return TerminalCommand.inserirCartao;

      case 'biometria':
      case 'face':
      case 'biometria_facial':
      case 'face_biometry':
      case 'show_face':
      case 'show_biometria':
        return TerminalCommand.biometria;

      case 'digital':
      case 'biometria_digital':
      case 'fingerprint':
      case 'dedo':
      case 'show_digital':
      case 'show_fingerprint':
      case 'show_biometria_digital':
        return TerminalCommand.biometriaDigital;

      case 'aproximar':
      case 'aproxime':
      case 'aproximacao':
      case 'nfc':
      case 'contactless':
      case 'celular':
      case 'aproximar_cartao':
      case 'show_aproximar':
      case 'show_nfc':
      case 'show_contactless':
        return TerminalCommand.aproximar;

      case 'sucesso':
      case 'success':
      case 'aprovado':
      case 'show_success':
      case 'show_sucesso':
        return TerminalCommand.sucesso;

      case 'erro':
      case 'error':
      case 'negado':
      case 'recusado':
      case 'cancelado':
      case 'show_error':
      case 'show_erro':
        return TerminalCommand.erro;

      case 'docinho':
      case 'doce':
      case 'docinho_de_leite':
      case 'show_docinho':
      case 'show_doce':
        return TerminalCommand.docinho;

      case 'led':
      case 'leds':
      case 'teste_led':
      case 'teste_leds':
      case 'show_led':
      case 'show_leds':
        return TerminalCommand.led;

      case 'seguro_pet':
      case 'pet':
      case 'jornada_seguro_pet':
      case 'contratar_seguro_pet':
      case 'show_seguro_pet':
      case 'show_pet':
        return TerminalCommand.seguroPet;

      case 'seguro_bolsa_protegida':
      case 'bolsa_protegida':
      case 'bolsa':
      case 'jornada_bolsa_protegida':
      case 'contratar_bolsa_protegida':
      case 'show_bolsa_protegida':
      case 'show_seguro_bolsa':
        return TerminalCommand.seguroBolsaProtegida;

      case 'plano_saude':
      case 'plano_de_saude':
      case 'assistencia_saude':
      case 'seguro_saude':
      case 'saude':
      case 'jornada_saude':
      case 'contratar_saude':
      case 'show_saude':
      case 'show_assistencia_saude':
      case 'show_seguro_saude':
        return TerminalCommand.assistenciaSaude;

      case 'protecao_cartao':
      case 'proteger_cartao':
      case 'seguro_cartao':
      case 'cartao_protegido':
      case 'jornada_protecao_cartao':
      case 'contratar_protecao_cartao':
      case 'show_protecao_cartao':
        return TerminalCommand.protecaoCartao;

      case 'assistencia_residencial':
      case 'protecao_residencial':
      case 'residencial':
      case 'casa':
      case 'lar':
      case 'jornada_assistencia_residencial':
      case 'jornada_protecao_residencial':
      case 'contratar_assistencia_residencial':
      case 'contratar_protecao_residencial':
      case 'show_assistencia_residencial':
      case 'show_protecao_residencial':
        return TerminalCommand.assistenciaResidencial;

      case 'seguro_celular':
      case 'celular_seguro':
      case 'jornada_seguro_celular':
      case 'contratar_seguro_celular':
      case 'show_seguro_celular':
        return TerminalCommand.seguroCelular;

      case 'led_red':
      case 'led_vermelho':
      case 'teste_led_red':
      case 'teste_led_vermelho':
      case 'test_led_red':
        return TerminalCommand.ledRed;

      case 'led_green':
      case 'led_verde':
      case 'teste_led_green':
      case 'teste_led_verde':
      case 'test_led_green':
        return TerminalCommand.ledGreen;

      case 'led_blue':
      case 'led_azul':
      case 'teste_led_blue':
      case 'teste_led_azul':
      case 'test_led_blue':
        return TerminalCommand.ledBlue;

      case 'led_yellow':
      case 'led_amarelo':
      case 'teste_led_yellow':
      case 'teste_led_amarelo':
      case 'test_led_yellow':
        return TerminalCommand.ledYellow;

      case 'led_purple':
      case 'led_roxo':
      case 'led_violeta':
      case 'teste_led_purple':
      case 'teste_led_roxo':
      case 'test_led_purple':
        return TerminalCommand.ledPurple;

      case 'led_white':
      case 'led_branco':
      case 'teste_led_white':
      case 'teste_led_branco':
      case 'test_led_white':
        return TerminalCommand.ledWhite;

      case 'led_off':
      case 'led_desligar':
      case 'led_desligado':
      case 'desligar_led':
      case 'desligar_leds':
        return TerminalCommand.ledOff;

      case 'led_loading':
      case 'led_carregando':
      case 'led_animacao':
      case 'led_animacao_carregamento':
      case 'teste_led_loading':
        return TerminalCommand.ledLoading;
    }

    for (final command in values) {
      if (command.value == normalized) return command;
    }

    return null;
  }

  static String _normalize(String raw) {
    return raw
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[-\s]+'), '_')
        .replaceAll(RegExp('[áàãâä]'), 'a')
        .replaceAll(RegExp('[éêë]'), 'e')
        .replaceAll(RegExp('[íîï]'), 'i')
        .replaceAll(RegExp('[óôõö]'), 'o')
        .replaceAll(RegExp('[úü]'), 'u')
        .replaceAll('ç', 'c');
  }
}

typedef TerminalCommandHandler = void Function(TerminalCommand command);

class TerminalCommandService {
  TerminalCommandService({
    required this.onCommand,
    this.tcpPort = 5050,
    this.httpPort = 8787,
  });

  final TerminalCommandHandler onCommand;
  final int tcpPort;
  final int httpPort;

  ServerSocket? _tcpServer;
  HttpServer? _httpServer;

  Future<void> start() async {
    await _startTcpServer();
    await _startHttpServer();
    _printHelp();
  }

  void dispose() {
    final tcpServer = _tcpServer;
    final httpServer = _httpServer;

    if (tcpServer != null) {
      unawaited(tcpServer.close());
    }
    if (httpServer != null) {
      unawaited(httpServer.close(force: true));
    }
  }

  Future<void> _startTcpServer() async {
    try {
      _tcpServer = await ServerSocket.bind(
        InternetAddress.anyIPv4,
        tcpPort,
        shared: true,
      );

      _tcpServer!.listen(_handleTcpClient);
      debugPrint('TCP pronto: 0.0.0.0:$tcpPort');
    } catch (error) {
      debugPrint('Não foi possível abrir TCP na porta $tcpPort: $error');
    }
  }

  void _handleTcpClient(Socket client) {
    final remote = '${client.remoteAddress.address}:${client.remotePort}';
    debugPrint('Cliente TCP conectado: $remote');

    client
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(
          const LineSplitter(),
        )
        .listen(
      (line) {
        final result = _dispatch(line, source: 'tcp');
        client.write(result ? 'OK $line\n' : 'ERRO comando invalido\n');
      },
      onError: (Object error) {
        debugPrint('Erro no cliente TCP $remote: $error');
      },
      onDone: () {
        client.destroy();
        debugPrint('Cliente TCP desconectado: $remote');
      },
      cancelOnError: true,
    );
  }

  Future<void> _startHttpServer() async {
    try {
      _httpServer = await HttpServer.bind(
        InternetAddress.anyIPv4,
        httpPort,
        shared: true,
      );

      _httpServer!.listen(_handleHttpRequest);
      debugPrint('HTTP pronto: http://0.0.0.0:$httpPort');
    } catch (error) {
      debugPrint('Não foi possível abrir HTTP na porta $httpPort: $error');
    }
  }

  Future<void> _handleHttpRequest(HttpRequest request) async {
    _setCorsHeaders(request.response);

    if (request.method == 'OPTIONS') {
      await request.response.close();
      return;
    }

    final rawCommand = await _readCommandFromRequest(request);
    final command = TerminalCommand.parse(rawCommand);

    if (command == null) {
      request.response
        ..statusCode = HttpStatus.badRequest
        ..headers.contentType = ContentType.json
        ..write(
          jsonEncode({
            'ok': false,
            'message': 'Comando inválido.',
            'validCommands': _validCommands,
          }),
        );
      await request.response.close();
      return;
    }

    onCommand(command);

    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.json
      ..write(
        jsonEncode({'ok': true, 'source': 'http', 'command': command.value}),
      );

    await request.response.close();
  }

  Future<String?> _readCommandFromRequest(HttpRequest request) async {
    final segments = request.uri.pathSegments;

    if (segments.length >= 2 && segments.first == 'command') {
      return segments.skip(1).join('_');
    }

    if (segments.isNotEmpty && segments.first == 'produto') {
      return segments.length >= 2 ? segments.skip(1).join('_') : null;
    }

    if (segments.isNotEmpty && segments.first == 'led') {
      final ledCommand = segments.length >= 2
          ? segments[1]
          : request.uri.queryParameters['color'];
      return ledCommand == null ? null : 'led_$ledCommand';
    }

    final queryCommand = request.uri.queryParameters['command'];
    if (queryCommand != null) return queryCommand;

    if (request.method == 'POST') {
      final body = await utf8.decoder.bind(request).join();
      if (body.trim().isEmpty) return null;

      try {
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) {
          return decoded['command']?.toString() ?? decoded['cmd']?.toString();
        }
      } catch (_) {
        return body;
      }
    }

    return null;
  }

  bool _dispatch(String raw, {required String source}) {
    final command = TerminalCommand.parse(raw);

    if (command == null) {
      debugPrint('Comando "$raw" ignorado. Use: ${_validCommands.join(', ')}');
      return false;
    }

    debugPrint('Comando "$raw" recebido via $source => ${command.value}');
    onCommand(command);
    return true;
  }

  void _setCorsHeaders(HttpResponse response) {
    response.headers
      ..set('Access-Control-Allow-Origin', '*')
      ..set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
      ..set('Access-Control-Allow-Headers', 'Content-Type');
  }

  void _printHelp() {
    debugPrint('Comandos aceitos: ${_validCommands.join(', ')}');
    debugPrint('TCP:  echo SHOW_CARD | nc 127.0.0.1:$tcpPort');
    debugPrint('HTTP: http://127.0.0.1:$httpPort/command/senha');
  }

  List<String> get _validCommands => const [
        'SHOW_CAROUSEL',
        'SHOW_CARD',
        'SHOW_PASSWORD',
        'SHOW_INSERT_CARD',
        'SHOW_FACE',
        'SHOW_FINGERPRINT',
        'SHOW_APROXIMAR',
        'SHOW_SUCCESS',
        'SHOW_ERROR',
        'SHOW_DOCINHO',
        'SHOW_LED',
        'SHOW_SEGURO_PET',
        'SHOW_BOLSA_PROTEGIDA',
        'SHOW_SAUDE',
        'SHOW_PROTECAO_CARTAO',
        'SHOW_ASSISTENCIA_RESIDENCIAL',
        'SHOW_PROTECAO_RESIDENCIAL',
        'SHOW_SEGURO_CELULAR',
        'standby',
        'cartao',
        'senha',
        'inserir_cartao',
        'biometria',
        'digital',
        'biometria_digital',
        'aproximar',
        'nfc',
        'sucesso',
        'erro',
        'docinho',
        'led',
        'leds',
        'seguro_pet',
        'bolsa_protegida',
        'assistencia_saude',
        'seguro_saude',
        'protecao_cartao',
        'assistencia_residencial',
        'protecao_residencial',
        'seguro_celular',
        'led_red',
        'led_green',
        'led_blue',
        'led_yellow',
        'led_purple',
        'led_white',
        'led_off',
        'led_loading',
      ];
}
