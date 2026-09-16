# Tamil Poster Generator

Mobile-first Next.js application for generating DMK posters from administrator-approved Tamil content and authorized branding. Visitors do not need an account; administrators use Supabase Auth.

## Implemented

- WhatsApp (1080×1920) and Instagram (1080×1350) PNG rendering
- Three reusable templates with cover-cropped photos and Tamil-aware wrapping
- Locked, randomly selected content from the active Supabase library
- Basic personal-detail editor; protected content and branding stay immutable
- Phone collection at download, keyed hashing, Asia/Kolkata daily boundary, atomic 3-download limit, and secondary IP throttling
- Admin sign-in, searchable content library, enable/disable/delete controls, download totals, RLS, Storage policies, and audit records

Phone collection without OTP is **not identity verification**. A visitor can submit a number they do not own or change numbers. This is a reasonable abuse control, not a guarantee. Administrators are responsible for reviewing content and confirming permission for every branding asset.

## Setup

1. Create a Supabase project.
2. Run every SQL file in `supabase/migrations` in filename order in the SQL editor or with the Supabase CLI.
3. Copy `.env.example` to `.env.local` and fill every value. Generate `PHONE_HASH_SECRET` with a cryptographically secure random generator.
4. Run `npm install`, then `npm run dev`.
5. Open `http://localhost:3000`.

No campaign content is hardcoded in the frontend. Add 15–20 reviewed items through `/admin` before testing generation.

## First administrator

Create an email/password user in Supabase Authentication, copy the UUID, then run:

```sql
insert into public.admin_users (user_id, role)
values ('USER_UUID', 'admin');
```

Sign in at `/admin/login`. Every admin mutation and query is authorized server-side.

## Authorized branding

Upload only an officially supplied DMK symbol to the `branding` Storage bucket (PNG/JPG/WebP, max 5 MB). Add its public URL and storage path to `branding_assets` with `asset_type = 'party_symbol'`. Enable one authorized symbol at a time. End users cannot upload or replace it.

## Download-limit design

`authorize_poster_download` takes a PostgreSQL advisory transaction lock derived from the keyed phone hash and India date. Concurrent requests for the same number serialize before counting and inserting. Only a successful authorization records a download. The API also caps a hashed IP at 20 downloads per India day.

The database stores an HMAC of the normalized `+91` number, not the raw number. Rotate the HMAC secret only with a migration plan because changing it resets historical matching.

## Vercel

Import this directory into Vercel, add the four variables from `.env.example`, and deploy. Use production Supabase values. Add the Vercel production URL to Supabase Authentication's allowed redirect URLs and run migrations before opening the public site.

## Test checklist

- Add, search, disable, re-enable, and delete admin content.
- Verify a non-admin cannot read downloads or mutate protected tables.
- Generate both formats and inspect saved PNG dimensions.
- Test long Tamil messages, names, and portrait/landscape photos.
- Download three times using one number; attempt four must return HTTP 429.
- Send concurrent authorizations and confirm only the allowed count is inserted.
- Confirm counters reset at midnight Asia/Kolkata.
- Test current desktop and mobile browsers.

## Future OTP

Add a verified-number table keyed to a short-lived OTP challenge, require that verified challenge ID in the authorization RPC, and keep the existing atomic daily counter. Update consent and retention notices before collecting verification metadata.
