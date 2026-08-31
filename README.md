# Royale — Ops & Finance

Single-page app. No build step, no dependencies to install. `index.html` loads the
Supabase client from a CDN at runtime.

```
royale-site/
├── index.html    the whole app
├── schema.sql    run once in Supabase
└── README.md
```

## 1. Set up the database

In your Supabase project, open **SQL Editor**, paste the contents of `schema.sql`,
and run it. That creates five tables — `bookings`, `costs`, `revenue`, `personal`,
`settings` — and seeds the settings row.

Read the row level security section at the bottom of the file before you finish.
Option A leaves the data open to anyone with the URL, which is fine while it's just
you and your partner. Option B requires sign-in and is the right move once the data
matters.

## 2. Deploy to Render

New → **Static Site** → connect the repo containing this folder.

| Setting | Value |
|---|---|
| Build command | *(leave empty)* |
| Publish directory | `.` (or `royale-site` if the folder sits in a larger repo) |

That's it. Render serves `index.html` directly.

## 3. Connect the app

Open the deployed site → **Personal** tab → **Database connection**.

Paste your Supabase **Project URL** and **anon public key** (Supabase → Project
Settings → API). Press Connect. The app loads from the database and saves there
from then on.

The anon key belongs in client-side code — it's public by design, and RLS is what
controls access. Hiding it would achieve nothing.

### Alternative: bake the config in

If you'd rather not enter it in the UI, add this before the `<script type="module">`
tag in `index.html`:

```html
<script>
  window.ROYALE_CONFIG = {
    url: "https://xxxx.supabase.co",
    key: "eyJhbGci..."
  };
</script>
```

## How saving works

Every change writes to `localStorage` first, then syncs to Supabase. If the network
drops or the connection isn't set up, you keep working and the indicator by the
cycle date reads *Saved locally only*. Reconnecting and pressing **Refresh** pulls
the server copy back down.

On a completely empty database the app plants its current starting data on first
load, so you're not staring at a blank screen.

## Things worth knowing

- The cycle runs the **22nd to the 22nd**; a booking counts in the cycle it starts.
- Payment fees are **derived**, never typed — they come from *charged* minus
  *received in bank*, and are stored as a `costs` row with `linked` set to the
  booking or revenue id. Editing the booking recalculates the fee; deleting it
  removes the fee.
- The **Personal** tab shares the same database as everything else under Option A.
  If you want it private, leave the `personal` policy out of your RLS setup and it
  will stay in local storage on your device.
- **Backup & restore** under the Personal tab exports everything as JSON. Worth
  taking a copy before any schema change.
