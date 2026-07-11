# German (de-DE) — Tier 1 App Store metadata

> Status: **re-derived 2026-07-11 from the frozen canonical (`docs/app-store-copy.md`) — needs one native-speaker read before ASC paste.**
> Register: informal "du" (standard for German fitness apps). No "wir"-forms anywhere (first-person-singular rule).
> Storefront reach: Germany, Austria, Switzerland (de is the primary metadata language on all three).

## App name (30 max)

```
Unit: Trainingstagebuch
```

23 chars. "Trainingstagebuch" (training log/diary) — survives the 2026-07-11 re-derivation unchanged: it is already the log-family term (the German for "workout log"), not the notebook metaphor the EN name moved away from.

## Subtitle (30 max)

```
Krafttraining-Tracker
```

21 chars. Mirrors the EN subtitle logic ("Strength tracker for lifters"): the name owns the log terms, so the subtitle adds *Krafttraining* + *Tracker* — the two highest-volume German category terms not yet indexed. The old "3 Sekunden" claim lives on in the description's first line.

## Promotional text (170 max)

```
Du kennst dein Programm. Unit loggt es schneller als Papier — die Zahlen vom letzten Mal sind schon eingetragen, jeder Satz ein Tap. Keine KI. Nur deine Zahlen.
```

Evergreen (derives from the canonical paper-comparison promo, not the superseded "New in v2" line).

## Description (4000 max)

```
Logge einen Satz in 3 Sekunden und geh zurück an die Stange.

Deine Gewichte vom letzten Training sind schon eingetragen — bestätigen, anpassen, fertig. Füge dein Programm als Text ein und deine Arbeitsgewichte stehen ab Tag eins bereit.

Kein Konto. Keine Werbung. Kein Feed. Dein Training bleibt auf deinem iPhone.

Ein Trainingstagebuch, keine Plattform.

Hinweis: Die App-Oberfläche ist derzeit auf Englisch.

Unit erfordert nach der Einrichtung einen kostenpflichtigen Kauf. Wöchentliche, monatliche und jährliche Abos mit automatischer Verlängerung sind verfügbar. Eine optionale Lifetime-Option erscheint nur, falls konfiguriert. Preise werden vor dem Kauf in der App angezeigt. Es gibt keine kostenlose Testphase.

Nutzungsbedingungen (EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Datenschutzrichtlinie: https://unitlift.app/privacy
```

## Keywords (100 max, no spaces, none repeated from name/subtitle)

```
kraftsport,fitness,muskelaufbau,trainingsplan,hantel,gewichte,wiederholungen,protokoll,gym
```

90 chars. Re-deduped 2026-07-11 against the new subtitle (*Krafttraining-Tracker*): removed `krafttraining` (now in the subtitle), added `kraftsport`. Intent notes:
- "kraftsport" — the strength-sport category term; "krafttraining" now sits in the subtitle, "trainingstagebuch" in the name.
- "trainingsplan" — what users paste into Unit; high intent for the import path.
- "gym" — German gym-goers use the English word; cheap 3-char catch.
- English queries ("gym tracker", "workout log") are covered by the en-US keyword field; this field chases German-only queries.

## What's New — v2 (4000 max)

```
• Logge einen Satz in 3 Sekunden — die Gewichte vom letzten Mal sind schon eingetragen
• Füge dein Programm als Text ein und starte ab Tag eins mit echten Arbeitsgewichten
• Neuer erster Start: von der Installation zum fertigen Programm in unter einer Minute

Unit erfordert nach der Einrichtung jetzt einen kostenpflichtigen Kauf — die Tarife werden vor dem Kauf angezeigt. Keine kostenlose Testphase. Vorhandene Trainingsdaten bleiben auf diesem iPhone.
```

## Subscriptions (display name ≤30 / description ≤45)

| Product ID | Display name | Description |
|---|---|---|
| `com.unit.weekly` | `Unit Wöchentlich` | `Wöchentlicher Zugriff auf Unit.` |
| `com.unit.monthly` | `Unit Monatlich` | `Monatlicher Zugriff auf Unit.` |
| `com.unit.annual` | `Unit Jährlich` | `Jährlicher Zugriff auf Unit.` |
| `com.unit.lifetime` | `Unit Lifetime` | `Einmalkauf. Dauerhafter Zugriff auf Unit.` |

Group display name: `Unit Pro` (unchanged — brand).

## Screenshot captions (pre-translated for a later Figma pass; v2 ships English screenshots)

1. `3 Sekunden, zurück an die Stange`
2. `Programm einfügen, loslegen`
3. `Kein Konto. Funktioniert offline.`
4. `Ein Tagebuch, kein Feed`
5. `Dein Pausen-Timer auf dem Sperrbildschirm`

## Review-risk notes

- German copy runs long; every string above is inside its ASC limit, but a native should check register ("du" throughout) and compound-word naturalness ("Arbeitsgewichte", "Pausen-Timer").
- "loggen" is established German fitness slang; a conservative reviewer might prefer "erfassen" — keep "loggen", it matches the audience.
