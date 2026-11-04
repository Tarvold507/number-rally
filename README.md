# Number Rally

Math practice for kids (roughly grades 1–4): math facts, missing numbers, carrying and borrowing, comparing, rounding, place value, remainders, telling time, and money. Practice, beat-the-clock drills, worksheets, and races against Robo. Built for tablets.

- Runs entirely in the browser. No accounts, no server, no tracking.
- Each kid's progress is saved only on the tablet it's played on. Grown-ups can save and restore backups from the "For grown-ups" screen, which is protected by a 4-digit PIN.
- Add it to the home screen to open it full screen and use it offline.

## Hosting

Served by GitHub Pages from the `main` branch root. When you change any file, bump `VERSION` in `sw.js` so installed copies update.

Font: Atkinson Hyperlegible Mono, SIL Open Font License (see `fonts/`).

## Family sync (Supabase)

Lets grown-ups see every kid's progress from any tablet or a computer.

1. In the Supabase SQL Editor, run `supabase/setup.sql` once.
2. Put the project URL and the publishable (anon) key into `SUPA_URL` and `SUPA_KEY` near the top of the family sync section in `index.html`. Never use the secret or service_role key.
3. On the first tablet: For grown-ups → Family sync → Create a family code. On other devices: join with that code. On a computer, open the site with `#grownups` at the end of the address.

The app only calls the `nr_put_kid`, `nr_get_family`, and `nr_delete_kid` functions. The table itself is not readable with the publishable key. Family data is stored under a SHA-256 hash of the family code.
