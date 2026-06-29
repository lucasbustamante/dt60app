import 'package:flutter/material.dart';

enum BankProductKind {
  pet,
  protectedBag,
  health,
  cardProtection,
  homeAssistance,
  phoneInsurance,
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
  });

  final BankProductKind kind;
  final String title;
  final String shortTitle;
  final String description;
  final String estimatedValue;
  final List<String> benefits;
  final IconData icon;

  String get successMessage => '$shortTitle contratado com sucesso.';
}

class ProductJourneySession {
  const ProductJourneySession({required this.product});

  final BankProduct product;
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
    ),
    BankProduct(
      kind: BankProductKind.protectedBag,
      title: 'Seguro Bolsa Protegida',
      shortTitle: 'Seguro Bolsa Protegida',
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
    ),
    BankProduct(
      kind: BankProductKind.health,
      title: 'Plano de Saúde / Assistência Saúde',
      shortTitle: 'Assistência Saúde',
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
    ),
    BankProduct(
      kind: BankProductKind.homeAssistance,
      title: 'Assistência Residencial',
      shortTitle: 'Assistência Residencial',
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
    ),
  ];

  static BankProduct byKind(BankProductKind kind) {
    return all.firstWhere((product) => product.kind == kind);
  }
}
