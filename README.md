# OpenOS Thirds

Overlay de 3 colunas iguais (esquerda / meio / direita) para macOS. Feito para o C49 5120×1440, funciona em qualquer ecrã.

Não é da App Store. Corre em fundo (sem ícone no Dock) via LaunchAgent `pro.openos.thirds`.

## Como usar

1. Clica a janela (botão esquerdo) para ela ficar à frente.
2. **Segura o botão direito** (~⅓ de segundo). Abrem as 3 zonas.
3. Sem largar, leva o rato a Esquerda / Meio / Direita e **larga**.

Também dá:

- arrastar a janela até ao **bordo direito** (faixa escura a altura toda)
- clicar nessa faixa e depois clicar a zona
- **⌃⌥1 / ⌃⌥2 / ⌃⌥3**

Clique direito curto continua a ser o menu. Esc fecha o overlay.

## Dependência

O overlay é desta app. O snap é o [Rectangle](https://github.com/rxhanson/Rectangle) (`first-third` / `center-third` / `last-third`).

## Instalar

No Mac (Xcode CLT ou Xcode):

```bash
./install.sh
```

Instala `~/Applications/OpenOSThirds.app` v1.1, LaunchAgent no login, e configura atalhos do Rectangle.

Rectangle: System Settings → Privacy & Security → Accessibility → ligar **Rectangle**.
