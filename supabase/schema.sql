-- Run once in your own Supabase project's SQL editor.
create table if not exists public.player_saves (
 user_id uuid primary key references auth.users(id) on delete cascade,
 save jsonb not null,
 revision bigint not null default 1 check(revision>0),
 updated_at timestamptz not null default now()
);
alter table public.player_saves enable row level security;
revoke all on public.player_saves from anon;
revoke all on public.player_saves from authenticated;
grant select on public.player_saves to authenticated;
drop policy if exists own_save_read on public.player_saves;
create policy own_save_read on public.player_saves for select to authenticated using ((select auth.uid())=user_id);
create or replace function public.save_player_game(p_save jsonb,p_expected_revision bigint)
returns table(revision bigint,updated_at timestamptz)
language plpgsql security definer set search_path='' as $$
declare owner_id uuid:=auth.uid();
begin
 if owner_id is null then raise exception 'AUTH_REQUIRED'; end if;
 if p_expected_revision is null or p_expected_revision<0 then raise exception 'INVALID_REVISION'; end if;
 if p_save is null or jsonb_typeof(p_save)<>'object'
  or p_save->>'version' is distinct from '1'
  or jsonb_typeof(p_save->'profile') is distinct from 'object'
  or jsonb_typeof(p_save->'world') is distinct from 'object'
  or jsonb_typeof(p_save->'position') is distinct from 'object'
  or pg_column_size(p_save)>8000000 then raise exception 'INVALID_SAVE'; end if;
 if p_expected_revision=0 then
  return query insert into public.player_saves as s(user_id,save,revision,updated_at)
   values(owner_id,p_save,1,clock_timestamp()) on conflict(user_id) do nothing returning s.revision,s.updated_at;
 else
  return query update public.player_saves as s set save=p_save,revision=s.revision+1,updated_at=clock_timestamp()
   where s.user_id=owner_id and s.revision=p_expected_revision returning s.revision,s.updated_at;
 end if;
 if not found then raise exception 'SAVE_CONFLICT'; end if;
end; $$;
revoke all on function public.save_player_game(jsonb,bigint) from public;
grant execute on function public.save_player_game(jsonb,bigint) to authenticated;
