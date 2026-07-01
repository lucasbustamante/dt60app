import 'package:flutter/material.dart';

enum BankProductKind {
  pet,
  protectedBag,
  health,
  cardProtection,
  homeAssistance,
  phoneInsurance,
}

enum PaymentMethod {
  nfc(
    label: 'Aproximação (NFC)',
    shortLabel: 'Aproximação',
    description: 'Aproxime o cartão ou celular do sensor do terminal.',
  ),
  chip(
    label: 'Inserção do cartão (Chip)',
    shortLabel: 'Chip',
    description: 'Insira o cartão na leitora com o chip voltado para cima.',
  ),
  magneticStripe(
    label: 'Tarja Magnética',
    shortLabel: 'Tarja',
    description: 'Passe o cartão na leitora usando a tarja magnética.',
  );

  const PaymentMethod({
    required this.label,
    required this.shortLabel,
    required this.description,
  });

  final String label;
  final String shortLabel;
  final String description;
}

enum AuthenticationMethod {
  faceBiometry(
    label: 'Biometria Facial',
    shortLabel: 'Facial',
    description: 'Validação por captura facial no terminal.',
  ),
  fingerprintBiometry(
    label: 'Biometria Digital',
    shortLabel: 'Digital',
    description: 'Validação pelo sensor de biometria digital.',
  ),
  password(
    label: 'Digitação da Senha',
    shortLabel: 'Senha',
    description: 'Validação pela senha digitada no pinpad.',
  );

  const AuthenticationMethod({
    required this.label,
    required this.shortLabel,
    required this.description,
  });

  final String label;
  final String shortLabel;
  final String description;
}

class BankProduct {
  const BankProduct({
    required this.kind,
    required this.title,
    required this.shortTitle,
    required this.description,
    required this.estimatedValue,
    required this.benefits,
    required this.icon,
    required this.paymentMethod,
    required this.authenticationMethod,
  });

  final BankProductKind kind;
  final String title;
  final String shortTitle;
  final String description;
  final String estimatedValue;
  final List<String> benefits;
  final IconData icon;
  final PaymentMethod paymentMethod;
  final AuthenticationMethod authenticationMethod;

  String get successMessage => '$shortTitle contratado com sucesso.';
}

class ProductJourneySession {
  const ProductJourneySession({required this.product});

  final BankProduct product;
}

class OperationFailure {
  const OperationFailure({
    required this.title,
    required this.message,
    this.session,
  });

  factory OperationFailure.cancelled(ProductJourneySession? session) {
    return OperationFailure(
      title: 'Operação cancelada',
      message: session == null
          ? 'A transação foi cancelada com segurança.'
          : 'A contratação de ${session.product.shortTitle} foi cancelada com segurança.',
      session: session,
    );
  }

  final String title;
  final String message;
  final ProductJourneySession? session;
}

class BankProductCatalog {
  const BankProductCatalog._();

  static const all = <BankProduct>[
    BankProduct(
      kind: BankProductKind.pet,
      title: 'Seguro Pet',
      shortTitle: 'Seguro Pet',
      description:
          'Proteção para cuidar do seu pet em momentos de emergência, com apoio para despesas veterinárias e assistência.',
      estimatedValue: 'R\$ 29,90/mês',
      benefits: [
        'Atendimento veterinário emergencial',
        'Orientação por telefone para cuidados rápidos',
        'Auxílio em consultas, exames e medicamentos',
        'Cobertura simples para imprevistos do dia a dia',
      ],
      icon: Icons.pets_outlined,
      paymentMethod: PaymentMethod.nfc,
      authenticationMethod: AuthenticationMethod.faceBiometry,
    ),
    BankProduct(
      kind: BankProductKind.protectedBag,
      title: 'Bolsa Protegida',
      shortTitle: 'Bolsa Protegida',
      description:
          'Cobertura para reduzir prejuízos em caso de roubo ou furto da bolsa e dos itens essenciais transportados.',
      estimatedValue: 'R\$ 12,90/mês',
      benefits: [
        'Proteção para bolsa, mochila ou pasta',
        'Auxílio para documentos e chaves',
        'Cobertura para pertences pessoais selecionados',
        'Atendimento para bloqueios e orientações',
      ],
      icon: Icons.work_outline,
      paymentMethod: PaymentMethod.magneticStripe,
      authenticationMethod: AuthenticationMethod.password,
    ),
    BankProduct(
      kind: BankProductKind.health,
      title: 'Seguro Saúde',
      shortTitle: 'Seguro Saúde',
      description:
          'Assistência para facilitar o acesso a cuidados básicos de saúde, orientação médica e serviços de apoio.',
      estimatedValue: 'R\$ 39,90/mês',
      benefits: [
        'Orientação médica remota',
        'Descontos em consultas e exames parceiros',
        'Apoio para agendamento de serviços',
        'Atendimento assistencial para toda a família',
      ],
      icon: Icons.health_and_safety_outlined,
      paymentMethod: PaymentMethod.chip,
      authenticationMethod: AuthenticationMethod.fingerprintBiometry,
    ),
    BankProduct(
      kind: BankProductKind.cardProtection,
      title: 'Proteção Cartão',
      shortTitle: 'Proteção Cartão',
      description:
          'Proteção adicional para o cartão em situações de perda, roubo, furto ou uso indevido após ocorrência.',
      estimatedValue: 'R\$ 9,90/mês',
      benefits: [
        'Assistência para bloqueio de cartão',
        'Cobertura para compras indevidas elegíveis',
        'Apoio emergencial em perda ou roubo',
        'Canal de atendimento para orientação imediata',
      ],
      icon: Icons.credit_card_outlined,
      paymentMethod: PaymentMethod.nfc,
      authenticationMethod: AuthenticationMethod.password,
    ),
    BankProduct(
      kind: BankProductKind.homeAssistance,
      title: 'Proteção Residencial',
      shortTitle: 'Proteção Residencial',
      description:
          'Serviços de apoio para emergências em casa, como chaveiro, elétrica, hidráulica e pequenos reparos.',
      estimatedValue: 'R\$ 19,90/mês',
      benefits: [
        'Chaveiro emergencial',
        'Serviços hidráulicos e elétricos básicos',
        'Apoio em pequenos reparos residenciais',
        'Atendimento 24 horas para emergências',
      ],
      icon: Icons.home_repair_service_outlined,
      paymentMethod: PaymentMethod.chip,
      authenticationMethod: AuthenticationMethod.faceBiometry,
    ),
    BankProduct(
      kind: BankProductKind.phoneInsurance,
      title: 'Seguro Celular',
      shortTitle: 'Seguro Celular',
      description:
          'Seguro para proteger seu celular contra eventos como roubo, furto qualificado e danos acidentais elegíveis.',
      estimatedValue: 'R\$ 24,90/mês',
      benefits: [
        'Cobertura para roubo e furto qualificado',
        'Proteção para danos acidentais elegíveis',
        'Assistência para bloqueio e orientação',
        'Processo simples de acionamento',
      ],
      icon: Icons.phone_iphone_outlined,
      paymentMethod: PaymentMethod.magneticStripe,
      authenticationMethod: AuthenticationMethod.fingerprintBiometry,
    ),
  ];

  static BankProduct byKind(BankProductKind kind) {
    return all.firstWhere((product) => product.kind == kind);
  }
}
