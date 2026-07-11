# Spanish — Mexico (es-MX) — Tier 1 App Store metadata

> Status: **re-derived 2026-07-11 from the frozen canonical (`docs/app-store-copy.md`) — needs one native-speaker read before ASC paste.**
> Register: informal "tú", neutral Latin American Spanish. No "nosotros"-forms (first-person-singular rule).
> Storefront reach: Mexico + most Latin American storefronts use es-MX metadata. Spain uses es-ES (Tier 2). Bonus: the **US storefront also indexes the es-MX keyword field** — see note at the bottom.

## App name (30 max)

```
Unit: Diario de Gym
```

19 chars. "Diario de gym" — survives the 2026-07-11 re-derivation unchanged: *diario* is already the log-family term (the EN name moved to "Gym Workout Log"), and Mexican gym-goers say "gym" more than "gimnasio".

## Subtitle (30 max)

```
Registro de fuerza y series
```

27 chars. Mirrors the EN subtitle logic ("Strength tracker for lifters"): the name owns the log terms, so the subtitle adds *registro / fuerza / series*. The old "3 segundos" claim lives on in the description's first line.

## Promotional text (170 max)

```
Ya conoces tu programa. Unit lo registra más rápido que el papel — los números de la última sesión ya están puestos, cada serie un toque. Sin IA. Solo tus números.
```

Evergreen (derives from the canonical paper-comparison promo, not the superseded "New in v2" line).

## Description (4000 max)

```
Registra una serie en 3 segundos y vuelve a la barra.

Tus pesos de la última sesión ya están precargados — confirma, ajusta, listo. Pega tu rutina como texto y tus pesos de trabajo quedan listos desde el día uno.

Sin cuenta. Sin anuncios. Sin feed social. Tu entrenamiento se queda en tu iPhone.

Un cuaderno de gym, no una plataforma.

Nota: la interfaz de la app está en inglés por ahora.

Unit requiere una compra de pago después de la configuración. Hay suscripciones semanales, mensuales y anuales con renovación automática. La opción Lifetime aparece solo si está configurada. Los precios se muestran en la app antes de comprar. No hay prueba gratuita.

Términos de uso (EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Política de privacidad: https://unitlift.app/privacy
```

## Keywords (100 max, no spaces, none repeated from name/subtitle)

```
rutina,gimnasio,pesas,entrenamiento,musculación,ejercicio,bitácora,progreso,reps,sentadilla
```

91 chars. Re-deduped 2026-07-11 against the new subtitle (*registro, fuerza, series*): removed `fuerza`, added `sentadilla` (squat — exercise-name search with app intent). Intent notes:
- "rutina" — the word LatAm lifters use for their program ("pega tu rutina"); highest intent.
- "pesas" — colloquial for lifting ("hacer pesas"), stronger than the formal "levantamiento".
- "bitácora" — log/journal; the notebook concept in search form.
- English queries stay with the en-US field.

## What's New — v2 (4000 max)

```
• Registra una serie en 3 segundos — los pesos de la última vez ya están precargados
• Pega tu rutina y empieza desde el día uno con tus pesos reales
• Primer arranque rediseñado: de la instalación a tu rutina lista en menos de un minuto

Unit ahora requiere una compra de pago después de la configuración — los planes se muestran antes de pagar. No hay prueba gratuita. Tus datos de entrenamiento se quedan en este iPhone.
```

## Subscriptions (display name ≤30 / description ≤45)

| Product ID | Display name | Description |
|---|---|---|
| `com.unit.weekly` | `Unit Semanal` | `Acceso semanal a Unit.` |
| `com.unit.monthly` | `Unit Mensual` | `Acceso mensual a Unit.` |
| `com.unit.annual` | `Unit Anual` | `Acceso anual a Unit.` |
| `com.unit.lifetime` | `Unit de por Vida` | `Pago único. Acceso a Unit para siempre.` |

Group display name: `Unit Pro` (unchanged — brand).

## Screenshot captions (pre-translated for a later Figma pass; v2 ships English screenshots)

1. `3 segundos y de vuelta a la barra`
2. `Pega tu rutina, empieza a entrenar`
3. `Sin cuenta. Funciona sin conexión.`
4. `Un cuaderno, no una red social`
5. `Descanso cronometrado en tu pantalla de bloqueo`

## Review-risk notes

- Copy is neutral-LatAm; a Spain reader will find "gym" and "pega tu rutina" informal but comprehensible. Spain gets its own es-ES pass in Tier 2.
- "Unit de por Vida" (16 chars) — native should confirm it reads as a product name and not a sentence fragment; fallback `Unit Lifetime`.

## Later ASO experiment (not v1)

The US storefront indexes es-MX keywords alongside en-US. Swapping this field to English overflow keywords would add ~100 chars of US keyword space at the cost of Mexican local intent. Decide only with storefront-level install data; keep Spanish for launch.
