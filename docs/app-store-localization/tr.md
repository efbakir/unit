# Turkish (tr) — Tier 1 App Store metadata

> Status: **re-derived 2026-07-11 from the frozen canonical (`docs/app-store-copy.md`) — founder must re-review before ASC paste (native speaker; no external review needed).**
> Register: "sen". No "biz"-forms (first-person-singular rule).
> Storefront reach: Turkey.

## App name (30 max)

```
Unit — Antrenman Günlüğü
```

24 chars. "Antrenman günlüğü" = training log — the standard Turkish term and the log-family identity the EN name moved to (`Gym Workout Log`). Replaces "Antrenman Defteri" (notebook), which carried the superseded name metaphor.

## Subtitle (30 max)

```
Kuvvet ve ağırlık takibi
```

24 chars. Mirrors the EN subtitle logic ("Strength tracker for lifters"): the name owns the log terms, so the subtitle adds *kuvvet / ağırlık / takip*. The old "Seti 3 saniyede kaydet" claim lives on in the description's first line.

## Promotional text (170 max)

```
Programını zaten biliyorsun. Unit kağıttan hızlı kaydeder — geçen seferki sayıların zaten dolu, her set tek dokunuş. Yapay zekâ yok, sosyal yok. Sadece sayıların.
```

Evergreen (derives from the canonical paper-comparison promo, not the superseded "New in v2" line).

## Description (4000 max)

```
Bir seti 3 saniyede kaydet, barın altına dön.

Son antrenmandaki ağırlıkların zaten dolu — onayla, gerekirse düzelt, bitti. Programını metin olarak yapıştır; çalışma ağırlıkların ilk günden hazır.

Hesap yok. Reklam yok. Sosyal akış yok. Antrenmanın iPhone'unda kalır.

Bir antrenman defteri, platform değil.

Not: Uygulama arayüzü şimdilik İngilizce.

Unit, kurulumdan sonra ücretli satın alma gerektirir. Haftalık, aylık ve yıllık otomatik yenilenen abonelikler sunulur. Lifetime seçeneği yalnızca yapılandırılmışsa görünür. Fiyatlar satın almadan önce uygulamada gösterilir. Ücretsiz deneme yoktur.

Kullanım Koşulları (EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Gizlilik Politikası: https://unitlift.app/privacy
```

## Keywords (100 max, no spaces, none repeated from name/subtitle)

```
gym,fitness,vücut,geliştirme,egzersiz,program,spor,salonu,demir,kayıt,halter,tekrar
```

83 chars. Re-deduped 2026-07-11 against the new name (*günlüğü*) and subtitle (*kuvvet, ağırlık, takip*): removed `günlük`, `ağırlık`, `takip`; added `kayıt` (logging), `halter` (barbell/weights), `tekrar` (reps). Intent notes:
- "gym" + "spor,salonu" — Turkish gym-goers use both the English word and "spor salonu"; comma-split covers the two-word phrase's parts.
- "vücut,geliştirme" — bodybuilding ("vücut geliştirme"), split the same way.
- "demir" — "demir basmak" (pressing iron) is lifter slang; cheap long-tail.
- Parser already reads Turkish pasted programs (v1.1) — honest to market the paste path here.

## What's New — v2 (4000 max)

```
• Bir seti 3 saniyede kaydet — geçen seferki ağırlıkların zaten dolu
• Herhangi bir programı yapıştır, ilk günden gerçek çalışma ağırlıklarınla başla
• Yenilenen ilk kurulum: yüklemeden ilk kayıtlı sete bir dakikadan kısa sürede

Unit artık kurulumdan sonra ücretli satın alma gerektiriyor — planlar ödemeden önce gösterilir. Ücretsiz deneme yok. Mevcut antrenman verilerin bu iPhone'da kalır.
```

## Subscriptions (display name ≤30 / description ≤45)

| Product ID | Display name | Description |
|---|---|---|
| `com.unit.weekly` | `Unit Haftalık` | `Unit'e haftalık erişim.` |
| `com.unit.monthly` | `Unit Aylık` | `Unit'e aylık erişim.` |
| `com.unit.annual` | `Unit Yıllık` | `Unit'e yıllık erişim.` |
| `com.unit.lifetime` | `Unit Ömür Boyu` | `Tek seferlik satın alma. Ömür boyu erişim.` |

Group display name: `Unit Pro` (unchanged — brand).

## Screenshot captions (pre-translated for a later Figma pass; v2 ships English screenshots)

1. `3 saniye, tekrar barın altına`
2. `Programını yapıştır, kaldırmaya başla`
3. `Hesap yok. Çevrimdışı çalışır.`
4. `Bir defter, sosyal ağ değil`
5. `Dinlenme sayacı kilit ekranında`

## Review-risk notes

- Willingness to pay in Turkey is low and the lira is volatile — this is the storefront to watch in the quarterly price spot-check (README §Pricing). Auto-converted prices only; no custom TRY prices.
- Founder: read the description once out loud — the only quality gate this file needs.
