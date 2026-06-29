# Comandos externos

O servidor existente foi mantido nas mesmas portas:

- TCP: `0.0.0.0:5050`
- HTTP: `http://127.0.0.1:8787`

Exemplos:

```powershell
Invoke-RestMethod http://127.0.0.1:8787/command/senha
Invoke-RestMethod http://127.0.0.1:8787/command/seguro_pet
Invoke-RestMethod http://127.0.0.1:8787/led/red
```

```bash
echo SHOW_CARD | nc 127.0.0.1 5050
echo seguro_pet | nc 127.0.0.1 5050
echo led_green | nc 127.0.0.1 5050
```

## Jornadas de contratação

- `seguro_pet` ou `SHOW_SEGURO_PET`
- `bolsa_protegida` ou `SHOW_BOLSA_PROTEGIDA`
- `assistencia_saude` ou `SHOW_SAUDE`
- `protecao_cartao` ou `SHOW_PROTECAO_CARTAO`
- `assistencia_residencial` ou `SHOW_ASSISTENCIA_RESIDENCIAL`
- `seguro_celular` ou `SHOW_SEGURO_CELULAR`

Também funciona via HTTP com caminhos compostos:

- `/produto/seguro_pet`
- `/produto/bolsa_protegida`
- `/produto/assistencia_saude`
- `/produto/protecao_cartao`
- `/produto/assistencia_residencial`
- `/produto/seguro_celular`

## LEDs

- `led_red` ou `/led/red`
- `led_green` ou `/led/green`
- `led_blue` ou `/led/blue`
- `led_yellow` ou `/led/yellow`
- `led_purple` ou `/led/purple`
- `led_white` ou `/led/white`
- `led_off` ou `/led/off`
- `led_loading` ou `/led/loading`

## Comandos antigos preservados

- `standby`, `SHOW_CAROUSEL`
- `cartao`, `SHOW_CARD`
- `senha`, `SHOW_PASSWORD`
- `inserir_cartao`, `SHOW_INSERT_CARD`
- `biometria`, `SHOW_FACE`
- `digital`, `SHOW_FINGERPRINT`
- `aproximar`, `SHOW_APROXIMAR`
- `sucesso`, `SHOW_SUCCESS`
- `erro`, `SHOW_ERROR`
- `docinho`, `SHOW_DOCINHO`
- `led`, `SHOW_LED`

