# Portuguese — Brazil (pt-BR) — Tier 1 App Store metadata

> Status: **draft — needs one native-speaker read before ASC paste.**
> Register: "você" (implicit), Brazilian vocabulary. No "nós"-forms (first-person-singular rule).
> Storefront reach: Brazil. Portugal uses pt-PT (not planned; Brazil is the market).

## App name (30 max)

```
Unit — Ficha de Treino
```

22 chars. "Ficha de treino" is the paper workout sheet every Brazilian gym hands out — the exact cultural object Unit replaces, and a high-volume search term.

## Subtitle (30 max)

```
Registre séries em 3 segundos
```

29 chars.

## Promotional text (170 max)

```
Novo na v2: cole sua ficha e comece do primeiro dia com suas cargas reais. Sem conta, sem anúncios — registro rápido que fica no seu iPhone.
```

## Description (4000 max)

```
Registre uma série em 3 segundos e volte para a barra.

Suas cargas do último treino já vêm preenchidas — confirme, ajuste, pronto. Cole sua ficha como texto e suas cargas de trabalho ficam prontas desde o primeiro dia.

Sem conta. Sem anúncios. Sem feed social. Seu treino fica no seu iPhone.

Uma ficha de treino, não uma plataforma.

Observação: a interface do app está em inglês por enquanto.

O Unit exige uma compra paga após a configuração. Há assinaturas semanais, mensais e anuais com renovação automática. A opção Lifetime aparece somente se estiver configurada. Os preços são mostrados no app antes da compra. Não há teste grátis.

Termos de uso (EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Política de privacidade: https://unitlift.app/privacy
```

## Keywords (100 max, no spaces, none repeated from name/subtitle)

```
academia,musculação,hipertrofia,carga,progressão,diário,supino,agachamento,peso,anotar
```

86 chars. Intent notes:
- "academia" — Brazilian for gym; the category's anchor term.
- "musculação" — weight training as Brazilians name it; category term Unit must rank for.
- "anotar" — "anotar treino" (write down the workout) is the notebook behavior in verb form.
- "supino"/"agachamento" (bench/squat) — exercise-name searches with app intent; cheap long-tail.

## What's New — v2 (4000 max)

```
• Registre uma série em 3 segundos — as cargas da última vez já vêm preenchidas
• Cole qualquer ficha e comece do primeiro dia com suas cargas reais
• Primeiro uso refeito: da instalação à primeira série registrada em menos de um minuto
```

## Subscriptions (display name ≤30 / description ≤45)

| Product ID | Display name | Description |
|---|---|---|
| `com.unit.weekly` | `Unit Semanal` | `Acesso semanal ao Unit.` |
| `com.unit.monthly` | `Unit Mensal` | `Acesso mensal ao Unit.` |
| `com.unit.annual` | `Unit Anual` | `Acesso anual ao Unit.` |
| `com.unit.lifetime` | `Unit Vitalício` | `Pagamento único. Acesso vitalício.` |

Group display name: `Unit Pro` (unchanged — brand).

## Screenshot captions (pre-translated for a later Figma pass; v2 ships English screenshots)

1. `3 segundos e de volta à barra`
2. `Cole sua ficha, comece a treinar`
3. `Sem conta. Funciona offline.`
4. `Um caderno, não um feed`
5. `Timer de descanso na tela de bloqueio`

## Review-risk notes

- Willingness to pay is lower in Brazil; the auto-converted Yearly (~R$ equivalent of $29.99) is the tier that will carry conversion there. No custom pricing — see README §Pricing.
- Native should confirm "cole sua ficha" reads naturally (paste your sheet) and that "O Unit" vs "Unit" article use is consistent.
