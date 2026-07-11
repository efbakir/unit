# German (de-DE) — Tier 1 App Store metadata

> Status: **draft — needs one native-speaker read before ASC paste.**
> Register: informal "du" (standard for German fitness apps). No "wir"-forms anywhere (first-person-singular rule).
> Storefront reach: Germany, Austria, Switzerland (de is the primary metadata language on all three).

## App name (30 max)

```
Unit — Trainingstagebuch
```

24 chars. "Trainingstagebuch" (training diary) is the exact German term for the object Unit replaces — highest-weight keyword placed in the highest-weight field.

## Subtitle (30 max)

```
Sätze in 3 Sekunden loggen
```

26 chars.

## Promotional text (170 max)

```
Neu in v2: Programm einfügen und ab Tag eins mit echten Arbeitsgewichten starten. Kein Konto, keine Werbung — schnelles Logging, das auf deinem iPhone bleibt.
```

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
krafttraining,fitness,muskelaufbau,trainingsplan,hantel,gewichte,wiederholungen,protokoll,gym
```

93 chars. Intent notes:
- "krafttraining" — the category term German lifters search; "trainingstagebuch" already sits in the name.
- "trainingsplan" — what users paste into Unit; high intent for the import path.
- "gym" — German gym-goers use the English word; cheap 3-char catch.
- English queries ("gym tracker", "workout log") are covered by the en-US keyword field; this field chases German-only queries.

## What's New — v2 (4000 max)

```
• Logge einen Satz in 3 Sekunden — die Gewichte vom letzten Mal sind schon eingetragen
• Füge dein Programm als Text ein und starte ab Tag eins mit echten Arbeitsgewichten
• Neuer erster Start: von der Installation zum ersten geloggten Satz in unter einer Minute
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
