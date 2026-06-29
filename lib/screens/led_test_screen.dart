import 'dart:async';

import 'package:flutter/material.dart';

import '../services/card_reader_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_frame.dart';

class LedTestScreen extends StatefulWidget {
  const LedTestScreen({super.key});

  @override
  State<LedTestScreen> createState() => _LedTestScreenState();
}

class _LedTestScreenState extends State<LedTestScreen> {
  String _lastAction = 'Nenhum teste executado ainda';

  Future<void> _run({
    required String label,
    required String target,
    required String color,
    String effect = 'solid',
    int? code,
  }) async {
    setState(() => _lastAction = 'Executando: $label');
    await CardReaderService.instance.testLed(
      target: target,
      color: color,
      effect: effect,
      code: code,
    );
    if (!mounted) return;
    setState(() => _lastAction = 'Último teste: $label');
  }

  Future<void> _allOff() async {
    setState(() => _lastAction = 'Desligando todos os LEDs');
    await CardReaderService.instance.ledOff();
    if (!mounted) return;
    setState(() => _lastAction = 'Todos os LEDs desligados');
  }

  @override
  void dispose() {
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
                    onPressed: () => Navigator.of(context)
                        .pushNamedAndRemoveUntil('/', (_) => false),
                    icon: const Icon(Icons.home_outlined),
                    label: const Text('Início'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                      _Section(
                        title: 'LEDs fixos do leitor',
                        subtitle: 'Testa os LEDs fixos já mapeados pelo SDK.',
                        children: [
                          _LedButton('Azul', Icons.circle, () => _run(label: 'Fixo azul', target: 'fixed', color: 'blue')),
                          _LedButton('Verde', Icons.check_circle, () => _run(label: 'Fixo verde', target: 'fixed', color: 'green')),
                          _LedButton('Vermelho', Icons.cancel, () => _run(label: 'Fixo vermelho', target: 'fixed', color: 'red')),
                          _LedButton('Amarelo', Icons.circle_outlined, () => _run(label: 'Fixo amarelo', target: 'fixed', color: 'yellow')),
                          _LedButton('Desligar fixos', Icons.power_settings_new, () => _run(label: 'Fixos desligados', target: 'fixed', color: 'off')),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _Section(
                        title: 'RGB acima da tela',
                        subtitle: 'Usa o LED RGB superior. Roxo é o comportamento observado no sucesso.',
                        children: [
                          _LedButton('Roxo', Icons.auto_awesome, () => _run(label: 'Superior roxo', target: 'top_rgb', color: 'purple')),
                          _LedButton('Azul', Icons.circle, () => _run(label: 'Superior azul', target: 'top_rgb', color: 'blue')),
                          _LedButton('Verde', Icons.check_circle, () => _run(label: 'Superior verde', target: 'top_rgb', color: 'green')),
                          _LedButton('Vermelho', Icons.cancel, () => _run(label: 'Superior vermelho', target: 'top_rgb', color: 'red')),
                          _LedButton('Branco', Icons.light_mode, () => _run(label: 'Superior branco', target: 'top_rgb', color: 'white')),
                          _LedButton('Respirar roxo', Icons.blur_on, () => _run(label: 'Superior respirar roxo', target: 'top_rgb', color: 'purple', effect: 'breath')),
                          _LedButton('Desligar superior', Icons.power_settings_new, () => _run(label: 'Superior desligado', target: 'top_rgb', color: 'off')),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _Section(
                        title: 'RGB circular do finger (tapeLamp/breath/marquee)',
                        subtitle: 'Testa comandos diretos e códigos da faixa/anel para você mapear no aparelho.',
                        children: [
                          _LedButton('Finger vermelho', Icons.fingerprint, () => _run(label: 'Finger vermelho', target: 'finger_rgb', color: 'red')),
                          _LedButton('Finger verde', Icons.fingerprint, () => _run(label: 'Finger verde', target: 'finger_rgb', color: 'green')),
                          _LedButton('Finger azul', Icons.fingerprint, () => _run(label: 'Finger azul', target: 'finger_rgb', color: 'blue')),
                          _LedButton('Finger roxo', Icons.fingerprint, () => _run(label: 'Finger roxo', target: 'finger_rgb', color: 'purple')),
                          _LedButton('Desligar finger', Icons.power_settings_new, () => _run(label: 'Finger desligado', target: 'finger_rgb', color: 'off')),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _Section(
                        title: 'Mapeamento do anel / light strip',
                        subtitle: 'Aperte cada código e anote qual LED/cor acendeu no equipamento.',
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: children,
          ),
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
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          textStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
