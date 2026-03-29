# UX Parity Specification (locked from current React app)

This is the baseline parity checklist for Flutter.

## Primary navigation

Sidebar tabs:

1. Dashboard
2. Farmers
3. Collections
4. Payments
5. Settings

## Auth states

### Logged out

- Branded sign-in card.
- "Sign in with Google" CTA.

### Loading

- Full-screen loading spinner + loading text.

### Logged in

- Sidebar + top header.
- Current tab title in header.

## Screen-level parity

### Dashboard

- KPI cards:
  - total farmers
  - total milk
  - paid payments total
  - pending payments total
- Recent collections list.
- Collection trend chart.

### Farmers

- Search by name/phone/location.
- Table/list of farmers.
- Admin-only create/edit/delete.

### Collections

- Search by farmer name.
- List with farmer lookup.
- Admin-only add collection.

### Payments

- Generate monthly payments from collections.
- List payments with paid/pending status.
- Admin-only mark payment as paid.

### Settings

- Show current user profile fields.
- Notification preference controls.

## Quality gates for parity

A Flutter module is considered parity-complete when:

- Required controls and data shown for the matching React tab.
- Matching role restrictions (`admin` vs `user`).
- Matching loading and error states.
