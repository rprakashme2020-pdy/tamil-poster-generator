alter table public.download_records add column if not exists phone_last4 text check(phone_last4 ~ '^\d{4}$');

drop function if exists public.authorize_poster_download(text,text,text,uuid,text);
create or replace function public.authorize_poster_download(p_phone_hash text,p_phone_last4 text,p_ip_hash text,p_template_key text,p_content_id uuid,p_output_format text)
returns table(allowed boolean,remaining integer) language plpgsql security definer set search_path=public as $$
declare v_day date:=(timezone('Asia/Kolkata',now()))::date;v_limit integer;v_count integer;
begin
 if p_phone_last4 !~ '^\d{4}$' then raise exception 'Invalid phone suffix';end if;
 perform pg_advisory_xact_lock(hashtextextended(p_phone_hash||v_day::text,0));
 select coalesce((value#>>'{}')::integer,3) into v_limit from public.app_settings where key='daily_download_limit';
 select count(*) into v_count from public.download_records where phone_number_hash=p_phone_hash and india_day=v_day;
 if v_count>=v_limit then return query select false,0;return;end if;
 if (select count(*) from public.download_records where ip_hash=p_ip_hash and india_day=v_day)>=20 then raise exception 'Download rate limit reached';end if;
 if not exists(select 1 from public.tamil_contents where id=p_content_id and is_active) then raise exception 'Content is no longer active';end if;
 insert into public.download_records(phone_number_hash,phone_last4,ip_hash,template_key,tamil_content_id,output_format,india_day) values(p_phone_hash,p_phone_last4,p_ip_hash,p_template_key,p_content_id,p_output_format::public.poster_format,v_day);
 return query select true,v_limit-v_count-1;
end $$;
revoke all on function public.authorize_poster_download(text,text,text,text,uuid,text) from public;
grant execute on function public.authorize_poster_download(text,text,text,text,uuid,text) to anon,authenticated;
