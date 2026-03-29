# Data Contracts (from current React + Firebase implementation)

Source of truth extracted from `src/App.tsx` and `src/firebase.ts`.

## Firebase setup contract

- Auth provider: Firebase Auth (Google popup login).
- Database: Firestore with explicit `firestoreDatabaseId` from config.

## Collection contracts

### `users/{uid}`

```ts
{
  uid: string;
  email: string;
  name: string;
  role: 'admin' | 'user';
}
```

### `farmers/{id}`

```ts
{
  id: string;
  name: string;
  phone: string;
  location: string;
  joinedAt: Timestamp;
}
```

### `collections/{id}`

```ts
{
  id: string;
  farmerId: string;
  amount: number;
  quality: number;
  timestamp: Timestamp;
  collectedBy: string;
}
```

### `payments/{id}`

```ts
{
  id: string;
  farmerId: string;
  amount: number;
  period: string; // e.g. "March 2026"
  status: 'pending' | 'paid';
  timestamp: Timestamp;
}
```

## Query contracts

- `farmers`: list all docs.
- `collections`: list ordered by `timestamp desc`.
- `payments`: list ordered by `timestamp desc`.

## Write contracts

- Farmer create/update/delete.
- Collection create.
- Payment batch create (monthly) + mark paid.
- User profile create-on-first-login.
