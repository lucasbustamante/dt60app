import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/card_reader_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_frame.dart';

class LedTestScreen extends StatefulWidget {
  const LedTestScreen({super.key});

  @override
  State<LedTestScreen> createState() => _LedTestScreenState();
}

class _LedTestScreenState extends State<LedTestScreen> {
  final TextEditingController _redController = TextEditingController(
    text: '255',
  );
  final TextEditingController _greenController = TextEditingController(
    text: '0',
  );
  final TextEditingController _blueController = TextEditingController(
    text: '0',
  );
  final TextEditingController _indexController = TextEditingController(
    text: '0',
  );
  final TextEditingController _codeController = TextEditingController(
    text: '0',
  );

  String _lastAction = 'Nenhum teste executado ainda';
  String _rgbTarget = 'top_rgb_config';
  String _rgbEffect = 'solid';

  Future<void> _run({
    required String label,
    required String target,
    required String color,
    String effect = 'solid',
    int? code,
    int? index,
    int? red,
    int? green,
    int? blue,
  }) async {
    setState(() => _lastAction = 'Executando: $label');
    await CardReaderService.instance.testLed(
      target: target,
      color: color,
      effect: effect,
      code: code,
      index: index,
      red: red,
      green: green,
      blue: blue,
    );
    if (!mounted) return;
    setState(() => _lastAction = 'Último teste: $label');
  }

  Future<void> _runCustomRgb() async {
    final red = _readByte(_redController);
    final green = _readByte(_greenController);
    final blue = _readByte(_blueController);
    final index = _readNumber(_indexController).clamp(0, 12);
    final code = _readNumber(_codeController).clamp(0, 99);

    await _run(
      label:
          'RGB livre R$red G$green B$blue / alvo $_rgbTarget / índice $index / código $code',
      target: _rgbTarget,
      color: 'custom',
      effect: _rgbEffect,
      code: code,
      index: index,
      red: red,
      green: green,
      blue: blue,
    );
  }

  Future<void> _runLightStripCode() async {
    final code = _readNumber(_codeController).clamp(0, 99);
    await _run(
      label: 'Light strip código $code',
      target: 'strip_code',
      color: 'code',
      code: code,
    );
  }

  Future<void> _runAggressiveOff() async {
    await _run(
      label: 'Desligamento agressivo SDK',
      target: 'aggressive_off',
      color: 'off',
    );
  }

  int _readByte(TextEditingController controller) {
    return _readNumber(controller).clamp(0, 255);
  }

  int _readNumber(TextEditingController controller) {
    return int.tryParse(controller.text.trim()) ?? 0;
  }

  Future<void> _allOff() async {
    setState(() => _lastAction = 'Desligando todos os LEDs');
    await CardReaderService.instance.ledOff();
    if (!mounted) return;
    setState(() => _lastAction = 'Todos os LEDs desligados');
  }

  Future<void> _loading() async {
    setState(() => _lastAction = 'Executando: carregamento azul');
    await CardReaderService.instance.playFixedLedLoading();
    if (!mounted) return;
    setState(() => _lastAction = 'Último teste: carregamento azul');
  }

  @override
  void dispose() {
    _redController.dispose();
    _greenController.dispose();
    _blueController.dispose();
    _indexController.dispose();
    _codeController.dispose();
    unawaited(CardReaderService.instance.ledOff());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppFrame(
      showSteps: false,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Teste de LEDs',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 30,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _allOff,
                    icon: const Icon(Icons.lightbulb_outline),
                    label: const Text('Desligar todos'),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/', (_) => false),
                    icon: const Icon(Icons.home_outlined),
                    label: const Text('Início'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.line),
                ),
                child: Text(
                  _lastAction,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _RgbLab(
                        redController: _redController,
                        greenController: _greenController,
                        blueController: _blueController,
                        indexController: _indexController,
                        codeController: _codeController,
                        target: _rgbTarget,
                        effect: _rgbEffect,
                        onTargetChanged: (value) {
                          if (value == null) return;
                          setState(() => _rgbTarget = value);
                        },
                        onEffectChanged: (value) {
                          if (value == null) return;
                          setState(() => _rgbEffect = value);
                        },
                        onApplyRgb: _runCustomRgb,
                        onApplyCode: _runLightStripCode,
                        onAggressiveOff: _runAggressiveOff,
                      ),
                      const SizedBox(height: 10),
                      _Section(
                        title: 'Cores do fluxo',
                        subtitle:
                            'Testa os estados usados nas jornadas de contratação.',
                        children: [
                          _LedButton(
                            'Erro vermelho',
                            Icons.cancel,
                            () => _run(
                              label: 'Fluxo erro vermelho',
                              target: 'all',
                              color: 'red',
                            ),
                          ),
                          _LedButton(
                            'Sucesso verde',
                            Icons.check_circle,
                            () => _run(
                              label: 'Fluxo sucesso verde',
                              target: 'all',
                              color: 'green',
                            ),
                          ),
                          _LedButton(
                            'Cartão azul',
                            Icons.credit_card_outlined,
                            () => _run(
                              label: 'Fluxo cartão azul',
                              target: 'all',
                              color: 'blue',
                            ),
                          ),
                          _LedButton(
                            'Senha amarelo',
                            Icons.lock_outline,
                            () => _run(
                              label: 'Fluxo senha amarelo',
                              target: 'all',
                              color: 'yellow',
                            ),
                          ),
                          _LedButton(
                            'Face roxo',
                            Icons.face,
                            () => _run(
                              label: 'Fluxo face roxo',
                              target: 'all',
                              color: 'purple',
                            ),
                          ),
                          _LedButton(
                            'Face branco',
                            Icons.light_mode,
                            () => _run(
                              label: 'Fluxo face branco',
                              target: 'all',
                              color: 'white',
                            ),
                          ),
                          _LedButton('Carregamento', Icons.sync, _loading),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _Section(
                        title: 'LEDs fixos do leitor',
                        subtitle: 'Testa os LEDs fixos já mapeados pelo SDK.',
                        children: [
                          _LedButton(
                            'Azul',
                            Icons.circle,
                            () => _run(
                              label: 'Fixo azul',
                              target: 'fixed',
                              color: 'blue',
                            ),
                          ),
                          _LedButton(
                            'Verde',
                            Icons.check_circle,
                            () => _run(
                              label: 'Fixo verde',
                              target: 'fixed',
                              color: 'green',
                            ),
                          ),
                          _LedButton(
                            'Vermelho',
                            Icons.cancel,
                            () => _run(
                              label: 'Fixo vermelho',
                              target: 'fixed',
                              color: 'red',
                            ),
                          ),
                          _LedButton(
                            'Amarelo',
                            Icons.circle_outlined,
                            () => _run(
                              label: 'Fixo amarelo',
                              target: 'fixed',
                              color: 'yellow',
                            ),
                          ),
                          _LedButton(
                            'Desligar fixos',
                            Icons.power_settings_new,
                            () => _run(
                              label: 'Fixos desligados',
                              target: 'fixed',
                              color: 'off',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _Section(
                        title: 'RGB acima da tela',
                        subtitle:
                            'Usa o LED RGB superior. Roxo é o comportamento observado no sucesso.',
                        children: [
                          _LedButton(
                            'Roxo',
                            Icons.auto_awesome,
                            () => _run(
                              label: 'Superior roxo',
                              target: 'top_rgb',
                              color: 'purple',
                            ),
                          ),
                          _LedButton(
                            'Azul',
                            Icons.circle,
                            () => _run(
                              label: 'Superior azul',
                              target: 'top_rgb',
                              color: 'blue',
                            ),
                          ),
                          _LedButton(
                            'Verde',
                            Icons.check_circle,
                            () => _run(
                              label: 'Superior verde',
                              target: 'top_rgb',
                              color: 'green',
                            ),
                          ),
                          _LedButton(
                            'Vermelho',
                            Icons.cancel,
                            () => _run(
                              label: 'Superior vermelho',
                              target: 'top_rgb',
                              color: 'red',
                            ),
                          ),
                          _LedButton(
                            'Branco',
                            Icons.light_mode,
                            () => _run(
                              label: 'Superior branco',
                              target: 'top_rgb',
                              color: 'white',
                            ),
                          ),
                          _LedButton(
                            'Respirar roxo',
                            Icons.blur_on,
                            () => _run(
                              label: 'Superior respirar roxo',
                              target: 'top_rgb',
                              color: 'purple',
                              effect: 'breath',
                            ),
                          ),
                          _LedButton(
                            'Desligar superior',
                            Icons.power_settings_new,
                            () => _run(
                              label: 'Superior desligado',
                              target: 'top_rgb',
                              color: 'off',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _Section(
                        title:
                            'RGB circular do finger (tapeLamp/breath/marquee)',
                        subtitle:
                            'Testa comandos diretos e códigos da faixa/anel para você mapear no aparelho.',
                        children: [
                          _LedButton(
                            'Finger vermelho',
                            Icons.fingerprint,
                            () => _run(
                              label: 'Finger vermelho',
                              target: 'finger_rgb',
                              color: 'red',
                            ),
                          ),
                          _LedButton(
                            'Finger verde',
                            Icons.fingerprint,
                            () => _run(
                              label: 'Finger verde',
                              target: 'finger_rgb',
                              color: 'green',
                            ),
                          ),
                          _LedButton(
                            'Finger azul',
                            Icons.fingerprint,
                            () => _run(
                              label: 'Finger azul',
                              target: 'finger_rgb',
                              color: 'blue',
                            ),
                          ),
                          _LedButton(
                            'Finger roxo',
                            Icons.fingerprint,
                            () => _run(
                              label: 'Finger roxo',
                              target: 'finger_rgb',
                              color: 'purple',
                            ),
                          ),
                          _LedButton(
                            'Desligar finger',
                            Icons.power_settings_new,
                            () => _run(
                              label: 'Finger desligado',
                              target: 'finger_rgb',
                              color: 'off',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _Section(
                        title: 'Mapeamento do anel / light strip',
                        subtitle:
                            'Aperte cada código e anote qual LED/cor acendeu no equipamento.',
                        children: List.generate(
                          9,
                          (index) => _LedButton(
                            'Código $index',
                            Icons.tune,
                            () => _run(
                              label: 'Light strip código $index',
                              target: 'strip_code',
                              color: 'code',
                              code: index,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RgbLab extends StatelessWidget {
  const _RgbLab({
    required this.redController,
    required this.greenController,
    required this.blueController,
    required this.indexController,
    required this.codeController,
    required this.target,
    required this.effect,
    required this.onTargetChanged,
    required this.onEffectChanged,
    required this.onApplyRgb,
    required this.onApplyCode,
    required this.onAggressiveOff,
  });

  final TextEditingController redController;
  final TextEditingController greenController;
  final TextEditingController blueController;
  final TextEditingController indexController;
  final TextEditingController codeController;
  final String target;
  final String effect;
  final ValueChanged<String?> onTargetChanged;
  final ValueChanged<String?> onEffectChanged;
  final VoidCallback onApplyRgb;
  final VoidCallback onApplyCode;
  final VoidCallback onAggressiveOff;

  static const _targets = [
    DropdownMenuItem(
      value: 'top_rgb_config',
      child: Text('Superior RGB + tapeLamp'),
    ),
    DropdownMenuItem(value: 'finger_index', child: Text('Finger índice')),
    DropdownMenuItem(value: 'finger_all', child: Text('Finger todos índices')),
    DropdownMenuItem(value: 'breath_rgb', child: Text('Breath RGB')),
    DropdownMenuItem(value: 'marquee_rgb', child: Text('Marquee RGB')),
    DropdownMenuItem(value: 'rgb_probe', child: Text('Probe todos métodos')),
  ];

  static const _effects = [
    DropdownMenuItem(value: 'solid', child: Text('Fixo')),
    DropdownMenuItem(value: 'breath', child: Text('Respirar')),
    DropdownMenuItem(value: 'marquee', child: Text('Girar')),
  ];

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'RGB livre / diagnóstico avançado',
      subtitle:
          'Digite RGB, índice e código para testar caminhos diferentes do SDK.',
      children: [
        SizedBox(
          width: 92,
          child: _NumberInput(label: 'R', controller: redController, max: 255),
        ),
        SizedBox(
          width: 92,
          child:
              _NumberInput(label: 'G', controller: greenController, max: 255),
        ),
        SizedBox(
          width: 92,
          child: _NumberInput(label: 'B', controller: blueController, max: 255),
        ),
        SizedBox(
          width: 110,
          child: _NumberInput(
            label: 'Índice',
            controller: indexController,
            max: 12,
          ),
        ),
        SizedBox(
          width: 110,
          child: _NumberInput(
            label: 'Código',
            controller: codeController,
            max: 99,
          ),
        ),
        SizedBox(
          width: 220,
          child: DropdownButtonFormField<String>(
            initialValue: target,
            isExpanded: true,
            items: _targets,
            onChanged: onTargetChanged,
            decoration: const InputDecoration(
              labelText: 'Alvo',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        SizedBox(
          width: 150,
          child: DropdownButtonFormField<String>(
            initialValue: effect,
            isExpanded: true,
            items: _effects,
            onChanged: onEffectChanged,
            decoration: const InputDecoration(
              labelText: 'Efeito',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        _LedButton('Aplicar RGB', Icons.palette_outlined, onApplyRgb),
        _LedButton('LightStrip código', Icons.tune, onApplyCode),
        _LedButton(
            'Desligar agressivo', Icons.power_settings_new, onAggressiveOff),
      ],
    );
  }
}

class _NumberInput extends StatelessWidget {
  const _NumberInput({
    required this.label,
    required this.controller,
    required this.max,
  });

  final String label;
  final TextEditingController controller;
  final int max;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(3),
      ],
      decoration: InputDecoration(
        labelText: '$label 0-$max',
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: children),
        ],
      ),
    );
  }
}

class _LedButton extends StatelessWidget {
  const _LedButton(this.label, this.icon, this.onPressed);

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 156,
      height: 42,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
