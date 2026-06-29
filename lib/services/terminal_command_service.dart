import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Comandos aceitos pelo terminal/pinpad.
///
/// Você pode enviar tanto em português quanto no formato SHOW_*. Exemplos:
/// standby, carrossel, show_carousel
/// cartao, card, show_card
/// senha, password, show_password
/// inserir_cartao, insert_card, show_insert_card
/// biometria, face, show_face
/// digital, biometria_digital, show_fingerprint
/// aproximar, nfc, contactless, show_aproximar
/// sucesso, success, show_success
/// erro, error, show_error
/// docinho, doce, show_docinho
/// led, leds, show_led
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
  led('led');

  const TerminalCommand(this.value);

  final String value;

  static TerminalCommand? parse(String? raw) {
    if (raw == null) return null;

    final normalized = raw
        .trim()
        .toLowerCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');

    switch (normalized) {
      case 'standby':
      case 'carousel':
      case 'carrossel':
      case 'show_carousel':
      case 'show_carrossel':
      case 'show_standby':
        return TerminalCommand.standby;

      case 'cartao':
      case 'cartão':
      case 'card':
      case 'passar_cartao':
      case 'passar_cartão':
      case 'show_card':
      case 'show_cartao':
      case 'show_cartão':
        return TerminalCommand.cartao;

      case 'senha':
      case 'password':
      case 'pin':
      case 'show_password':
      case 'show_senha':
        return TerminalCommand.senha;

      case 'inserir_cartao':
      case 'inserir_cartão':
      case 'insert_card':
      case 'chip':
      case 'show_insert_card':
      case 'show_inserir_cartao':
      case 'show_inserir_cartão':
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
      case 'nfc':
      case 'contactless':
      case 'celular':
      case 'aproximar_cartao':
      case 'aproximar_cartão':
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
    }

    for (final command in values) {
      if (command.value == normalized) return command;
    }

    return null;
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

  /// Porta TCP simples para comandos em texto.
  /// Exemplo: echo SHOW_CARD | nc 127.0.0.1 5050
  final int tcpPort;

  /// Porta HTTP opcional para comandos por navegador/PowerShell.
  /// Exemplo: Invoke-RestMethod http://127.0.0.1:8787/command/senha
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
        .transform(utf8.decoder as StreamTransformer<Uint8List, dynamic>)
        .transform(const LineSplitter())
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
        ..write(jsonEncode({
          'ok': false,
          'message': 'Comando inválido.',
          'validCommands': _validCommands,
        }));
      await request.response.close();
      return;
    }

    onCommand(command);

    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({
        'ok': true,
        'source': 'http',
        'command': command.value,
      }));

    await request.response.close();
  }

  Future<String?> _readCommandFromRequest(HttpRequest request) async {
    final segments = request.uri.pathSegments;

    if (segments.length >= 2 && segments.first == 'command') {
      return segments[1];
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
      debugPrint(
        'Comando "$raw" ignorado. Use: ${_validCommands.join(', ')}',
      );
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
      ];
}
