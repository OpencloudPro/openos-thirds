# OpenOS Thirds

Overlay de zonas no ecrã. Menu bar = widget para escolher o layout.

Não é da App Store. Corre em fundo (sem ícone no Dock) via LaunchAgent `pro.openos.thirds`.

## Zonas (v1.4)

No ícone da barra (preview do layout actual):

| Menu | O quê |
|---|---|
| **Auto (por ecrã)** | ≥ 3000 px → 3 iguais; senão → 2 |
| **2 iguais** | Esq / Dir |
| **3 iguais** | Esq / Meio / Dir |
| **2/3 + 1/3** | 1 grande + 1 menor (direita) |
| **1/3 + 2/3** | 1 menor + 1 grande |
| **4 cantos** | TL / TR / BL / BR |
| **Cima / Baixo** | 2 faixas |
| **1 grande + 2 dir.** | metade + 2 quadrantes |
| **2 esq. + 1 grande** | espelho |
| **1/4 + 1/2 + 1/4** | editor no meio |
| **4 colunas** | ultrawide |

A escolha fica em `defaults` `pro.openos.thirds` / `zoneMode`.

## Como usar

1. Clica a janela (esquerdo) para ela ficar à frente.
2. **Segura o direito** (~⅓ s). Abrem as zonas.
3. Sem largar, leva o rato à zona e **larga**.

Também: arrastar ao **bordo direito** · **⌃⌥1/2/3** (terços). Esc fecha.

O tab permanente no bordo vem **desligado**. Liga no ícone → **Tab no bordo**.

## Dependência

O overlay é desta app. O snap é o [Rectangle](https://github.com/rxhanson/Rectangle).

## Instalar

```bash
./install.sh
```

`~/Applications/OpenOSThirds.app` v1.4 + LaunchAgent. Rectangle: Definições → Privacidade → Acessibilidade.
