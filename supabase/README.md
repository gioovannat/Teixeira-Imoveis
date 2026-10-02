# Supabase setup

1. Create a Supabase project, then copy its Project URL and anon key into `.env.local` using `.env.example` as the template.
2. Run `supabase link --project-ref <ref>` and `supabase db push`, or paste `migrations/001_initial_schema.sql` into the SQL Editor.
3. Create the first administrator in Authentication, then run:

```sql
insert into public.profiles (id, full_name)
values ('AUTH_USER_UUID', 'Bernardino Teixeira');
```

4. Keep `SUPABASE_SERVICE_ROLE_KEY` only on the server. Lead creation must call a server route that validates and rate-limits the request before inserting it.

The public static pages remain in demonstration mode until they are migrated to Next.js (or another server runtime) and connected with the anon key.
