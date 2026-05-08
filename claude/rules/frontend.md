# Frontend

## Package Manager (pnpm) Policy
- The pnpm version should be pinned in `package.json` (`packageManager` field). Use Corepack (`corepack enable`) so the local pnpm matches the pin; do NOT install pnpm globally
- All non-interactive entry points (CI, e2e scripts, Dockerfile, etc.) MUST install with `--frozen-lockfile`. Never invoke a bare `pnpm install` from a script — it silently rewrites `pnpm-lock.yaml` on version/peer drift
- `pnpm-lock.yaml` is updated only by an explicit, manual `pnpm install`. If `--frozen-lockfile` fails, investigate the drift (pnpm version mismatch, deliberate `package.json` change) — do not just re-run with `pnpm install` to "fix" it

## CSS Styling
**NEVER hardcode color values, spacing, or sizes in CSS files.** Always use the design-token CSS variables defined by the project (typically in a `global.css` / `tokens.css`).

- Use semantic variables for colors (borders, backgrounds, text, status, primary)
- Use spacing scale variables instead of raw px/rem values
- Use rem for responsive units (1rem = 16px). Convert pixel values to rem (e.g. `20px` → `1.25rem`). 1px borders may remain as px

**Bad:**
```css
border: 1px solid #E5E7EB;
padding: 14px 16px;
right: 20px;
```

**Good:**
```css
border: 1px solid var(--border-default);
padding: var(--spacing-md-lg) var(--spacing-md);
right: 1.25rem;
```

## Keyboard & IME Input — MANDATORY
**Any keyboard handler that triggers a destructive action on Enter (save, submit, mode change, navigation) MUST guard against IME composition.** CJK users press Enter to confirm IME conversions — un-guarded handlers silently corrupt their input. Never write `if (e.key === 'Enter') { ...side effect... }` without checking `event.isComposing` (or `event.nativeEvent.isComposing` in React) / `keyCode === 229`.

## Internationalization (i18n)
**All user-facing text in both frontend and backend MUST go through the project's i18n system. Hardcoding strings is prohibited.** When adding new UI text or backend messages, register the key in the central key registry and add translations to every supported language file in the same change.
