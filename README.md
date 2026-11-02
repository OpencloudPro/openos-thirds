# OpenOS Thirds

Overlay de zonas no ecrã. Menu bar = widget para escolher o layout.

Não é da App Store. Corre em fundo (sem ícone no Dock) via LaunchAgent `pro.openos.thirds`.

## Zonas (v1.6)

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
2. **Segura o direito e arrasta** (~⅓ s + 16 px). Abrem as zonas.
3. Sem largar, leva o rato à zona e **larga**.

Também: **arrastar a janela** ao bordo direito · **⌃⌥1/2/3** (terços do ecrã focado, snap nativo). Esc fecha.

O overlay **não** abre ao seleccionar ficheiros, no menu de contexto, nem noutro arrasto que não mexa a janela.

O tab permanente no bordo vem **desligado**. Liga no ícone → **Tab no bordo**.

## Snap

O overlay e o snap são nativos. Largar uma janela numa zona move-a com a API de Acessibilidade, para o retângulo visível dessa zona. Não usa o Rectangle nem qualquer URL scheme (`rectangle://`, `execute-action`, etc.).

Na primeira execução o macOS pede Acessibilidade. Se o snap não acontecer: Definições do Sistema → Privacidade e Segurança → Acessibilidade → ativa **OpenOS Thirds**. Se a app já estiver na lista e continuar sem mover janelas, desliga e volta a ligar — cada `./install.sh` muda a assinatura ad-hoc.

Um `defaults` antigo em `pro.openos.thirds` que ainda tenha `rectangle://execute-action?name=…` (ou outro URL `execute-action`) é reescrito para o id nativo (`last-third`, `first-third`, …) ao arrancar.

## Instalar

```bash
./install.sh
```

`~/Applications/OpenOSThirds.app` v1.6 (build 7) + LaunchAgent. Acessibilidade: a própria app OpenOS Thirds.

Testes da geometria e da migração (não precisam da app):

```bash
swiftc -o /tmp/snap-tests SnapGeometry.swift SnapGeometryTests.swift && /tmp/snap-tests
```
