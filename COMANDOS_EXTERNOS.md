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

A tela `SHOW_LED` / `led` também possui uma bancada de teste RGB livre:

- informe R/G/B de `0` a `255`;
- informe o índice do `tapeLamp` de `0` a `12`;
- informe o código da `lightStrip`;
- selecione alvo/efeito e aplique o teste.

Alvos disponíveis na bancada:

- Superior RGB + `tapeLamp`
- Finger por índice
- Finger em todos os índices
- `breathOn`
- `marqueeOn`
- Probe com todos os métodos
- Desligamento agressivo do SDK

Se o finger continuar azul mesmo após “Desligar agressivo”, o LED pode estar sendo mantido pelo firmware como indicador físico não controlável por essas APIs do SDK.

## Câmera externa

A biometria facial agora usa a implementação Android Camera2 (`camera_android`) e consulta o `CameraManager` nativo para priorizar câmeras externas/USB. Se nenhuma câmera abrir, a própria tela mostra diagnóstico com quantidade de câmeras Android, presença de USB vídeo, recurso de câmera externa e câmera preferida detectada.

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
