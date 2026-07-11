# Portuguese — Brazil (pt-BR) — Tier 1 App Store metadata

> Status: **re-derived 2026-07-11 from the frozen canonical (`docs/app-store-copy.md`) — needs one native-speaker read before ASC paste.**
> Register: "você" (implicit), Brazilian vocabulary. No "nós"-forms (first-person-singular rule).
> Storefront reach: Brazil. Portugal uses pt-PT (not planned; Brazil is the market).

## App name (30 max)

```
Unit — Diário de Treino
```

23 chars. "Diário de treino" = training log — the log-family identity the EN name moved to (`Gym Workout Log`). Replaces "Ficha de Treino" (the paper workout sheet), which carried the superseded metaphor; *ficha* keeps its search value from the keyword field instead.

## Subtitle (30 max)

```
Registro de cargas e séries
```

27 chars. Mirrors the EN subtitle logic ("Strength tracker for lifters"): the name owns the log terms, so the subtitle adds *registro / cargas / séries*. The old "3 segundos" claim lives on in the description's first line.

## Promotional text (170 max)

```
Você já conhece seu treino. Unit registra mais rápido que papel — os números da última sessão já preenchidos, cada série um toque. Sem IA. Só seus números.
```

Evergreen (derives from the canonical paper-comparison promo, not the superseded "New in v2" line).

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
academia,musculação,hipertrofia,progressão,supino,agachamento,peso,anotar,ficha,halteres
```

88 chars. Re-deduped 2026-07-11 against the new name (*diário*) and subtitle (*registro, cargas, séries*): removed `diário`, `carga`; added `ficha` (displaced from the name — still the high-volume cultural term) and `halteres` (dumbbells). Intent notes:
- "academia" — Brazilian for gym; the category's anchor term.
- "musculação" — weight training as Brazilians name it; category term Unit must rank for.
- "anotar" — "anotar treino" (write down the workout) is the notebook behavior in verb form.
- "supino"/"agachamento" (bench/squat) — exercise-name searches with app intent; cheap long-tail.

## What's New — v2 (4000 max)

```
• Registre uma série em 3 segundos — as cargas da última vez já vêm preenchidas
• Cole qualquer ficha e comece do primeiro dia com suas cargas reais
• Primeiro uso refeito: da instalação à primeira série registrada em menos de um minuto

O Unit agora exige uma compra paga após a configuração — os planos aparecem antes de pagar. Não há teste grátis. Seus dados de treino ficam neste iPhone.
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
