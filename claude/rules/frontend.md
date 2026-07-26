---
paths:
  - "**/*.{ts,tsx,js,jsx,mjs,cjs}"
  - "**/*.{css,scss,vue,svelte}"
  - "**/package.json"
---

# Frontend

## Package Manager (pnpm) Policy
- For projects using pnpm, pin its version in the `packageManager` field and use
  Corepack so local execution follows the pin
- Install with `--frozen-lockfile` from CI, e2e scripts, Dockerfiles, and other
  non-interactive entry points so they cannot rewrite `pnpm-lock.yaml`
- Update `pnpm-lock.yaml` only through an explicit manual `pnpm install`. A
  frozen-lockfile failure calls for investigating version or manifest drift

## CSS Styling
When a project defines design-token CSS variables, use them for colors, spacing,
and sizes instead of introducing raw values.

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

## Keyboard & IME Input
Guard an Enter handler that saves, submits, changes mode, or navigates against
IME composition. CJK users press Enter to confirm conversions, so check
`event.isComposing` (or `event.nativeEvent.isComposing` in React) or
`keyCode === 229` before triggering the side effect.

## Internationalization (i18n)
When a project has an i18n system, route new user-facing text through it.
Register the key centrally and update every supported language file in the same
change.

## Verification
When a frontend file changes, run the project's frontend unit tests and lint
command (typically `pnpm test` and `pnpm lint`) once. Both must pass before
reporting the task complete; lint enforces interaction invariants such as IME and
keyboard handling even for small changes.
