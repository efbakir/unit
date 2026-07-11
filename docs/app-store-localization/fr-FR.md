# French (fr-FR) — Tier 1 App Store metadata

> Status: **re-derived 2026-07-11 from the frozen canonical (`docs/app-store-copy.md`) — needs one native-speaker read before ASC paste.**
> Register: "vous" — safer default for a paid app. **Open question for the native reader:** French lifter culture leans "tu"; if the reviewer says "tu" reads better for this audience, switch the description + promo consistently. No "nous"-forms (first-person-singular rule).
> Storefront reach: France (+ fr-FR shown in Belgium, Luxembourg, francophone Africa storefronts). Canada uses fr-CA (not planned).

## App name (30 max)

```
Unit — Journal de Muscu
```

23 chars. "Journal de muscu" = lifting log — the log-family identity the EN name moved to (`Gym Workout Log`), keeping "muscu" as the colloquial category anchor. Replaces "Carnet de Muscu" (notebook), which carried the superseded metaphor.

## Subtitle (30 max)

```
Suivi de force et de séries
```

27 chars. Mirrors the EN subtitle logic ("Strength tracker for lifters"), and the old subtitle's *journal* would now duplicate the name. Adds *suivi / force / séries*; *musculation* moves to the keyword field.

## Promotional text (170 max)

```
Vous connaissez votre programme. Unit le note plus vite que le papier — les charges de la dernière séance déjà remplies, chaque série en un tap. Pas d'IA. Vos chiffres.
```

Evergreen (derives from the canonical paper-comparison promo, not the superseded "New in v2" line).

## Description (4000 max)

```
Enregistrez une série en 3 secondes et retournez sous la barre.

Vos charges de la dernière séance sont déjà remplies — confirmez, ajustez, terminé. Collez votre programme en texte et vos charges de travail sont prêtes dès le premier jour.

Pas de compte. Pas de publicité. Pas de fil social. Votre entraînement reste sur votre iPhone.

Un carnet de muscu, pas une plateforme.

Remarque : l'interface de l'app est en anglais pour le moment.

Unit nécessite un achat payant après la configuration. Des abonnements hebdomadaires, mensuels et annuels à renouvellement automatique sont proposés. L'option Lifetime n'apparaît que si elle est configurée. Les prix sont affichés dans l'app avant l'achat. Il n'y a pas d'essai gratuit.

Conditions d'utilisation (CLUF) : https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Politique de confidentialité : https://unitlift.app/privacy
```

## Keywords (100 max, no spaces, none repeated from name/subtitle)

```
entraînement,fitness,salle,haltères,squat,répétitions,poids,programme,musculation,développé
```

92 chars. Re-deduped 2026-07-11 against the new name (*journal, muscu*) and subtitle (*suivi, force, séries*): removed `force`, `séries`; added `musculation` (displaced from the old subtitle — the category's biggest term) and `développé` (bench-press family). Intent notes:
- "salle" — "la salle" is how French lifters say the gym; short and high volume.
- "entraînement" — the training category term.
- "squat" — exercise-name search with app intent.

## What's New — v2 (4000 max)

```
• Enregistrez une série en 3 secondes — les charges de la dernière fois sont déjà remplies
• Collez n'importe quel programme et démarrez dès le premier jour avec vos charges réelles
• Premier lancement repensé : de l'installation à la première série enregistrée en moins d'une minute

Unit nécessite désormais un achat payant après la configuration — les formules s'affichent avant de payer. Pas d'essai gratuit. Vos données d'entraînement restent sur cet iPhone.
```

## Subscriptions (display name ≤30 / description ≤45)

| Product ID | Display name | Description |
|---|---|---|
| `com.unit.weekly` | `Unit Hebdo` | `Accès hebdomadaire à Unit.` |
| `com.unit.monthly` | `Unit Mensuel` | `Accès mensuel à Unit.` |
| `com.unit.annual` | `Unit Annuel` | `Accès annuel à Unit.` |
| `com.unit.lifetime` | `Unit à Vie` | `Achat unique. Accès à Unit à vie.` |

Group display name: `Unit Pro` (unchanged — brand).

## Screenshot captions (pre-translated for a later Figma pass; v2 ships English screenshots)

1. `3 secondes, retour sous la barre`
2. `Collez votre programme, c'est parti`
3. `Pas de compte. Fonctionne hors ligne.`
4. `Un carnet, pas un réseau social`
5. `Minuteur de repos sur l'écran verrouillé`

## Review-risk notes

- The tu/vous call is the main register risk — resolve with the native reader before paste (see header).
- French typography uses a space before `:` and `!`; kept above. ASC renders it fine.
- "Muscu" in the app name is informal; if App Review or the native reader objects, fallback name: `Unit — Journal d'entraînement` (29 chars).
