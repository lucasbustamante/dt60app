# Terminal Control Mobile Flutter

App Flutter para rodar no celular em pé e enviar comandos para o Raspberry via WebSocket.

Fluxo:

Celular Flutter → Wi‑Fi → Raspberry `ws://IP:8787/ws` → USB → PinPad

## Como usar

1. Abra este projeto no VS Code/Android Studio.
2. Rode:

```bash
flutter pub get
flutter run
```

3. No app, informe o IP do Raspberry, por exemplo:

```text
192.168.1.50
```

4. Porta padrão: `8787`.
5. Toque em **Conectar**.
6. Use os botões para enviar os comandos.

## Teste antes no Raspberry

No Raspberry, o bridge precisa estar rodando:

```bash
cd ~/Desktop/raspberry_pinpad_bridge
source .venv/bin/activate
python run.py
```

No navegador do celular em pé/celular, teste:

```text
http://IP_DO_RASPBERRY:8787/status
```

## Mensagem enviada pelo app

O app envia assim:

```json
{"command":"senha"}
```

Se configurar token no Raspberry, preencha o token no app. A mensagem vira:

```json
{"command":"senha","token":"SEU_TOKEN"}
```

## Comandos incluídos

- `standby`
- `aproximar`
- `inserir_cartao`
- `cartao`
- `senha`
- `biometria_facial`
- `biometria_digital`
- `sucesso`
- `erro`
- `docinho`
- `seguro_pet`
- `bolsa_protegida`
- `seguro_saude`
- `protecao_cartao`
- `assistencia_residencial`
- `seguro_celular`
- `abertura_conta`
- `credito_consignado`
- LEDs: vermelho, verde, azul, amarelo, roxo, branco, loading e desligar.


## Ajustes desta versão

- Travado em modo retrato (`portraitUp`/`portraitDown`).
- Tela inteira com `SingleChildScrollView` para não quebrar em celulares menores.
- Botões responsivos: 2 colunas quando couber, 1 coluna em telas estreitas.
- Painel de log com altura limitada e scroll interno.
