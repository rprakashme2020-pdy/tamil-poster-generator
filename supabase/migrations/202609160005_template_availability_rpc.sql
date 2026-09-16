create or replace function public.is_template_active(p_template_key text)
returns boolean language sql stable security definer set search_path=public as $$
 select exists(select 1 from public.poster_templates where template_key=p_template_key and is_active=true)
$$;
revoke all on function public.is_template_active(text) from public;
grant execute on function public.is_template_active(text) to anon,authenticated;
