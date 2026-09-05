# OpenOS Thirds

Overlay de **2 ou 3** colunas iguais, altura total, para macOS. Feito para o C49 5120×1440 (3 zonas) e para o MacBook (2 zonas).

Não é da App Store. Corre em fundo (sem ícone no Dock) via LaunchAgent `pro.openos.thirds`.

## Zonas

No ícone da barra de menu (2 ou 3 riscos):

- **Auto (por ecrã)** — ecrã ≥ 3000 px de largura → 3 zonas; senão → 2
- **2 zonas** — Esquerda / Direita (`left-half` / `right-half`)
- **3 zonas** — Esquerda / Meio / Direita (`first-third` / `center-third` / `last-third`)

A escolha fica em `defaults` `pro.openos.thirds` / `zoneMode` (`auto` | `two` | `three`).

## Como usar

1. Clica a janela (botão esquerdo) para ela ficar à frente.
2. **Segura o botão direito** (~⅓ de segundo). Abrem as zonas.
3. Sem largar, leva o rato à zona e **larga**.

Também dá:

- arrastar a janela até ao **bordo direito**
- **⌃⌥1 / ⌃⌥2 / ⌃⌥3** (terços; no modo 2 zonas usa o overlay)

O tab permanente no bordo vem **desligado**. Liga no ícone da barra → **Tab no bordo** se o quiseres.

Clique direito curto continua a ser o menu. Esc fecha o overlay.

## Dependência

O overlay é desta app. O snap é o [Rectangle](https://github.com/rxhanson/Rectangle).

## Instalar

No Mac (Xcode CLT ou Xcode):

```bash
./install.sh
```

Instala `~/Applications/OpenOSThirds.app` v1.3, LaunchAgent no login, e configura atalhos do Rectangle.

Rectangle: System Settings → Privacy & Security → Accessibility → ligar **Rectangle**.
