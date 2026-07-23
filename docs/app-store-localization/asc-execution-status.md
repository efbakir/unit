# Unit 2.1 localization status

> PRO-32 is a hard pre-submission gate. **Do not paste any locale into App Store Connect until every row is approved and this file says READY TO PASTE.**

## Current state

| Locale | Regenerated from frozen 2.1 English | Machine validation | Human approval | ASC |
|---|---:|---:|---|---|
| de-DE | Yes | Passed | Native read pending | Do not paste |
| es-MX | Yes | Passed | Native Mexican read pending | Do not paste |
| pt-BR | Yes | Passed | Native Brazilian read and final name pending | Do not paste |
| fr-FR | Yes | Passed | Native read and vous/tu decision pending | Do not paste |
| tr | Yes | Passed | Founder read pending | Do not paste |

Machine command:

```
npm run test:localizations
```

It validates:

- Name, subtitle, promotional text, description, keywords, and subscription limits
- Exactly five description bullets and three What’s New bullets
- No spaces in keywords
- No exact keyword duplication with the localized name or subtitle
- English-only UI disclosure
- EULA and privacy URLs
- Removal of the retired “you already know your program” positioning

## Human review evidence

Record each approval here before changing the status:

| Locale | Reviewer | Date | Result / edits |
|---|---|---|---|
| de-DE | — | — | Pending |
| es-MX | — | — | Pending |
| pt-BR | — | — | Pending |
| fr-FR | — | — | Pending |
| tr | Efe | — | Pending |

## Release rule

After all five approvals:

1. Apply reviewer edits to the locale files.
2. Run `npm run test:localizations` again.
3. Change every ASC cell above to `Ready to paste`.
4. Mark PRO-32 Done.
5. Only then follow `asc-paste-checklist.md`.
