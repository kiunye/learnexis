## Goal

Make auth pages feel **minimalist** by switching them to a **light theme** (background, card, typography) without changing the rest of the application.

## Scope

- Applies only to pages rendered with `layouts/auth`.
- Keeps existing component classes (`auth-bg`, `auth-card`, `auth-input`, etc.) but introduces a light-theme switch via a body class.

## Approach

- Add `auth--light` to the `<body>` in `app/views/layouts/auth.html.erb`.
- In `app/assets/stylesheets/application.tailwind.css`, keep the current dark auth styles as the default and add scoped overrides:
  - `auth--light` sets a light background and dark text.
  - `auth--light .auth-card`, `auth--light .auth-input`, `auth--light .auth-label`, `auth--light .auth-button` adjust colors/borders/shadows for light UI.
- Remove the `auth-grid` overlay element from auth views for a cleaner background.
- Update auth view text/link utility classes (e.g., `text-white`, `text-gray-300`, `text-blue-300`) to appropriate light-theme equivalents.

## Success criteria

- Auth pages render with a clean light background, legible dark text, and a simple white card.
- No visual/theming changes on non-auth pages.

