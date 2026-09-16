create extension if not exists pgcrypto;

create type public.poster_format as enum ('whatsapp','instagram');
create table public.admin_users (user_id uuid primary key references auth.users(id) on delete cascade, role text not null default 'editor' check(role in ('editor','admin')), created_at timestamptz not null default now());
create table public.tamil_contents (id uuid primary key default gen_random_uuid(), title text not null check(char_length(title) between 2 and 100), content_text text not null check(char_length(content_text) between 5 and 500), is_active boolean not null default false, created_by uuid references auth.users(id), created_at timestamptz not null default now(), updated_at timestamptz not null default now());
create table public.poster_templates (id uuid primary key default gen_random_uuid(), template_key text unique not null, name text not null, format public.poster_format not null, width integer not null, height integer not null, configuration jsonb not null default '{}', is_active boolean not null default true, created_at timestamptz not null default now(), updated_at timestamptz not null default now());
create table public.branding_assets (id uuid primary key default gen_random_uuid(), asset_type text not null check(asset_type in ('party_symbol','background','logo')), asset_url text not null, storage_path text not null, allowed_templates text[] not null default '{}', is_active boolean not null default false, created_by uuid references auth.users(id), created_at timestamptz not null default now(), updated_at timestamptz not null default now());
create table public.download_records (id uuid primary key default gen_random_uuid(), phone_number_hash text not null, ip_hash text, template_key text not null, tamil_content_id uuid not null references public.tamil_contents(id), output_format public.poster_format not null, india_day date not null default (timezone('Asia/Kolkata',now()))::date, created_at timestamptz not null default now());
create index download_daily_limit_idx on public.download_records(phone_number_hash,india_day);
create index download_ip_day_idx on public.download_records(ip_hash,india_day);
create table public.app_settings (key text primary key, value jsonb not null, updated_by uuid references auth.users(id), updated_at timestamptz not null default now());
insert into public.app_settings(key,value) values ('daily_download_limit','3');
create table public.audit_logs (id bigint generated always as identity primary key, actor_id uuid references auth.users(id), action text not null, entity_type text not null, entity_id text, old_data jsonb, new_data jsonb, created_at timestamptz not null default now());

create or replace function public.is_admin() returns boolean language sql stable security definer set search_path=public as $$ select exists(select 1 from public.admin_users where user_id=auth.uid()) $$;
create or replace function public.get_random_active_content() returns setof public.tamil_contents language sql volatile security definer set search_path=public as $$ select * from public.tamil_contents where is_active=true order by random() limit 1 $$;
revoke all on function public.get_random_active_content() from public; grant execute on function public.get_random_active_content() to anon,authenticated;

create or replace function public.authorize_poster_download(p_phone_hash text,p_ip_hash text,p_template_key text,p_content_id uuid,p_output_format text)
returns table(allowed boolean,remaining integer) language plpgsql security definer set search_path=public as $$
declare v_day date:=(timezone('Asia/Kolkata',now()))::date;v_limit integer;v_count integer;
begin
 perform pg_advisory_xact_lock(hashtextextended(p_phone_hash||v_day::text,0));
 select coalesce((value#>>'{}')::integer,3) into v_limit from public.app_settings where key='daily_download_limit';
 select count(*) into v_count from public.download_records where phone_number_hash=p_phone_hash and india_day=v_day;
 if v_count>=v_limit then return query select false,0;return;end if;
 if (select count(*) from public.download_records where ip_hash=p_ip_hash and india_day=v_day)>=20 then raise exception 'Download rate limit reached';end if;
 if not exists(select 1 from public.tamil_contents where id=p_content_id and is_active) then raise exception 'Content is no longer active';end if;
 insert into public.download_records(phone_number_hash,ip_hash,template_key,tamil_content_id,output_format,india_day) values(p_phone_hash,p_ip_hash,p_template_key,p_content_id,p_output_format::public.poster_format,v_day);
 return query select true,v_limit-v_count-1;
end $$;
revoke all on function public.authorize_poster_download(text,text,text,uuid,text) from public;grant execute on function public.authorize_poster_download(text,text,text,uuid,text) to anon,authenticated;

alter table public.admin_users enable row level security;alter table public.tamil_contents enable row level security;alter table public.poster_templates enable row level security;alter table public.branding_assets enable row level security;alter table public.download_records enable row level security;alter table public.app_settings enable row level security;alter table public.audit_logs enable row level security;
create policy "admins read own roles" on public.admin_users for select using(user_id=auth.uid());
create policy "public reads active templates" on public.poster_templates for select using(is_active or public.is_admin());
create policy "public reads active branding" on public.branding_assets for select using(is_active or public.is_admin());
create policy "admins manage content" on public.tamil_contents for all using(public.is_admin()) with check(public.is_admin());
create policy "admins manage templates" on public.poster_templates for all using(public.is_admin()) with check(public.is_admin());
create policy "admins manage branding" on public.branding_assets for all using(public.is_admin()) with check(public.is_admin());
create policy "admins read downloads" on public.download_records for select using(public.is_admin());
create policy "admins manage settings" on public.app_settings for all using(public.is_admin()) with check(public.is_admin());
create policy "admins read audits" on public.audit_logs for select using(public.is_admin());

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values('branding','branding',true,5242880,array['image/png','image/jpeg','image/webp']) on conflict(id) do nothing;
create policy "public reads branding objects" on storage.objects for select using(bucket_id='branding');
create policy "admins upload branding objects" on storage.objects for insert to authenticated with check(bucket_id='branding' and public.is_admin());
create policy "admins update branding objects" on storage.objects for update to authenticated using(bucket_id='branding' and public.is_admin());
create policy "admins delete branding objects" on storage.objects for delete to authenticated using(bucket_id='branding' and public.is_admin());

insert into public.poster_templates(template_key,name,format,width,height) values
('rising-sun-whatsapp','எழுச்சி','whatsapp',1080,1920),('heritage-whatsapp','மரபு','whatsapp',1080,1920),('modern-lines-whatsapp','முன்னேற்றம்','whatsapp',1080,1920),
('rising-sun-instagram','எழுச்சி','instagram',1080,1350),('heritage-instagram','மரபு','instagram',1080,1350),('modern-lines-instagram','முன்னேற்றம்','instagram',1080,1350);
