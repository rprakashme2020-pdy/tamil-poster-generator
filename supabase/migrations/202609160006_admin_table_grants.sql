-- RLS decides which rows an administrator may access, but PostgreSQL table
-- privileges are still required before those policies can be evaluated.
grant select, insert, update, delete on table public.tamil_contents to authenticated;
grant select, insert, update, delete on table public.poster_templates to authenticated;
grant select, insert, update, delete on table public.branding_assets to authenticated;
grant select on table public.download_records to authenticated;
grant select, insert, update, delete on table public.app_settings to authenticated;
grant select, insert on table public.audit_logs to authenticated;
grant select on table public.admin_users to authenticated;

-- The public generator reads only active rows, as constrained by RLS.
grant select on table public.poster_templates to anon;
grant select on table public.branding_assets to anon;
