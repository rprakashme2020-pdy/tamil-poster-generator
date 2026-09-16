create or replace function public.admin_create_tamil_content(p_title text,p_content_text text,p_is_active boolean)
returns public.tamil_contents language plpgsql security definer set search_path=public as $$
declare v_row public.tamil_contents;
begin
 if auth.uid() is null or not public.is_admin() then raise exception 'Administrator access required';end if;
 if char_length(trim(p_title)) not between 2 and 100 then raise exception 'Title must contain 2 to 100 characters';end if;
 if char_length(trim(p_content_text)) not between 5 and 500 then raise exception 'Content must contain 5 to 500 characters';end if;
 insert into public.tamil_contents(title,content_text,is_active,created_by) values(trim(p_title),trim(p_content_text),p_is_active,auth.uid()) returning * into v_row;
 insert into public.audit_logs(actor_id,action,entity_type,entity_id,new_data) values(auth.uid(),'create','tamil_content',v_row.id::text,to_jsonb(v_row));
 return v_row;
end $$;
revoke all on function public.admin_create_tamil_content(text,text,boolean) from public;
grant execute on function public.admin_create_tamil_content(text,text,boolean) to authenticated;
