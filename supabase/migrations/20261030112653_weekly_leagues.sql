-- Weekly leagues. Only authenticated RPCs expose public aliases and scores.
begin;
create schema if not exists league_private;
revoke all on schema league_private from public, anon, authenticated;
create table league_private.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  alias text not null check (char_length(alias) between 2 and 24),
  avatar integer not null default 0 check (avatar between 0 and 7),
  active boolean not null default true,
  tier integer not null default 0 check (tier between 0 and 4),
  joined_at timestamptz not null default now()
);
create table league_private.groups (
  id uuid primary key default gen_random_uuid(),
  week date not null,
  tier integer not null check (tier between 0 and 4),
  created_at timestamptz not null default now()
);
create index on league_private.groups(week, tier, created_at, id);
create table league_private.members (
  user_id uuid references league_private.profiles(user_id) on delete cascade,
  week date not null,
  group_id uuid not null references league_private.groups(id),
  eligible boolean not null default true,
  points integer not null default 0 check (points >= 0),
  reached_at timestamptz not null default now(),
  primary key(user_id, week)
);
create index on league_private.members(group_id, points desc, reached_at, user_id);
create table league_private.questions (
  id text primary key,
  lesson_id text not null,
  thai text not null,
  meaning text not null
);
create index on league_private.questions(lesson_id);
create table league_private.rounds (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references league_private.profiles(user_id) on delete cascade,
  week date not null,
  lesson_id text not null,
  phrase_ids text[] not null,
  payload jsonb not null,
  answers integer[] not null,
  created_at timestamptz not null default clock_timestamp(),
  finished_at timestamptz,
  result jsonb
);
create index on league_private.rounds(user_id, created_at);
create table league_private.credits (
  user_id uuid not null references league_private.profiles(user_id) on delete cascade,
  day date not null,
  kind text not null check (kind in ('review', 'lesson')),
  source_id text not null,
  points integer not null check (points between 1 and 20),
  primary key(user_id, day, kind, source_id)
);
create table league_private.completed (
  user_id uuid not null references league_private.profiles(user_id) on delete cascade,
  lesson_id text not null,
  primary key(user_id, lesson_id)
);
alter table league_private.profiles enable row level security;
alter table league_private.groups enable row level security;
alter table league_private.members enable row level security;
alter table league_private.questions enable row level security;
alter table league_private.rounds enable row level security;
alter table league_private.credits enable row level security;
alter table league_private.completed enable row level security;
revoke all on all tables in schema league_private from public, anon, authenticated;

create function league_private.league_join(p_alias text, p_avatar integer default 0)
returns void language plpgsql security definer set search_path = '' as $$
declare
  u uuid := auth.uid();
  w date := date_trunc('week', clock_timestamp() at time zone 'Asia/Bangkok')::date;
  t integer; g uuid; old_group uuid; old_week date; old_rank integer; active_count integer;
begin
  if u is null then raise exception 'Sign in required'; end if;
  if not exists(select 1 from auth.users where id = u and email_confirmed_at is not null) then raise exception 'Verify email first'; end if;
  if char_length(trim(p_alias)) not between 2 and 24 or p_avatar not between 0 and 7
     or p_alias ~ '[[:cntrl:]]' then raise exception 'Invalid profile'; end if;
  insert into league_private.profiles(user_id, alias, avatar)
    values (u, trim(p_alias), p_avatar)
    on conflict(user_id) do update set alias = excluded.alias, avatar = excluded.avatar, active = true;
  select tier into t from league_private.profiles where user_id = u for update;
  if exists(select 1 from league_private.members where user_id = u and week = w) then
    update league_private.members set eligible = true where user_id = u and week = w; return; end if;
  select group_id, week into old_group, old_week from league_private.members
    where user_id = u order by week desc limit 1;
  if old_group is not null then
    select count(*) into active_count from league_private.members where group_id = old_group and points > 0 and eligible;
    select pos into old_rank from (
      select user_id, row_number() over(order by points desc, reached_at, user_id)::integer pos
      from league_private.members where group_id = old_group and points > 0 and eligible
    ) ranked where user_id = u;
    -- Small groups stay together; no demotions in the initial release.
    if active_count >= 5 and old_rank <= ceil(active_count / 4.0) then t := least(4, t + 1); end if;
    update league_private.profiles set tier = t where user_id = u;
  end if;
  perform pg_advisory_xact_lock(hashtext('thai-league:' || w::text || ':' || t::text));
  select lg.id into g from league_private.groups lg
    where lg.week = w and lg.tier = t
    and (select count(*) from league_private.members m where m.group_id = lg.id) < 20
    order by lg.created_at, lg.id limit 1;
  if g is null then
    insert into league_private.groups(week, tier) values(w, t) returning id into g;
  end if;
  insert into league_private.members(user_id, week, group_id) values(u, w, g);
end $$;

create function league_private.league_board()
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  u uuid := auth.uid(); w date := date_trunc('week', clock_timestamp() at time zone 'Asia/Bangkok')::date;
  d date := (clock_timestamp() at time zone 'Asia/Bangkok')::date;
  p league_private.profiles; m league_private.members; rows jsonb; daily integer;
begin
  if u is null then raise exception 'Sign in required'; end if;
  select * into p from league_private.profiles where user_id = u;
  if p.user_id is null or not p.active then return jsonb_build_object('joined', false); end if;
  perform league_private.league_join(p.alias, p.avatar);
  select * into p from league_private.profiles where user_id = u;
  select * into m from league_private.members where user_id = u and week = w;
  select coalesce(jsonb_agg(jsonb_build_object('rank', pos, 'alias', alias,
      'avatar', avatar, 'points', points, 'mine', user_id = u) order by pos), '[]'::jsonb)
    into rows from (
      select mm.user_id, pp.alias, pp.avatar, mm.points,
        row_number() over(order by mm.points desc, mm.reached_at, mm.user_id) pos
      from league_private.members mm join league_private.profiles pp on pp.user_id = mm.user_id
      where mm.group_id = m.group_id and mm.eligible
    ) ranked;
  select coalesce(sum(points), 0) into daily from league_private.credits where user_id = u and day = d;
  return jsonb_build_object('joined', true, 'tier', p.tier, 'alias', p.alias,
    'avatar', p.avatar, 'week', w, 'ends_at', (w + 7)::timestamp at time zone 'Asia/Bangkok',
    'server_now', clock_timestamp(), 'daily_points', daily, 'daily_cap', 100, 'rows', rows);
end $$;

create function league_private.league_begin_round()
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  u uuid := auth.uid(); d date := (clock_timestamp() at time zone 'Asia/Bangkok')::date;
  w date := date_trunc('week', clock_timestamp() at time zone 'Asia/Bangkok')::date;
  p league_private.profiles; r league_private.rounds; q record;
  lid text; opts text[]; answer integer; payload jsonb := '[]'; answers integer[] := '{}'; ids text[] := '{}';
begin
  if u is null then raise exception 'Sign in required'; end if;
  select * into p from league_private.profiles where user_id = u for update;
  if p.user_id is null or not p.active then raise exception 'Join the league first'; end if;
  perform league_private.league_join(p.alias, p.avatar);
  if (select coalesce(sum(points),0) from league_private.credits where user_id = u and day = d) >= 100
    then raise exception 'Daily limit reached'; end if;
  select * into r from league_private.rounds where user_id = u and finished_at is null
    and week = w and created_at > clock_timestamp() - interval '20 minutes' order by created_at desc limit 1;
  if r.id is not null then return jsonb_build_object('id', r.id, 'questions', r.payload); end if;
  if (select count(*) from league_private.rounds where user_id = u
      and created_at >= d::timestamp at time zone 'Asia/Bangkok') >= 40
    then raise exception 'Too many rounds today'; end if;
  select lesson_id into lid from league_private.questions qq
    group by lesson_id order by
      exists(select 1 from league_private.completed cc where cc.user_id = u and cc.lesson_id = qq.lesson_id),
      random() limit 1;
  if lid is null then raise exception 'Question catalog unavailable'; end if;
  for q in select * from league_private.questions where lesson_id = lid order by id loop
    select array_agg(meaning order by random()) into opts from (
      (select meaning from league_private.questions where meaning <> q.meaning group by meaning order by random() limit 3)
      union all select q.meaning
    ) choices;
    answer := array_position(opts, q.meaning) - 1;
    payload := payload || jsonb_build_array(jsonb_build_object('phrase_id', q.id, 'thai', q.thai, 'options', opts));
    answers := array_append(answers, answer); ids := array_append(ids, q.id);
  end loop;
  insert into league_private.rounds(user_id, week, lesson_id, phrase_ids, payload, answers)
    values(u, w, lid, ids, payload, answers) returning * into r;
  return jsonb_build_object('id', r.id, 'questions', payload);
end $$;

create function league_private.league_submit_round(p_round uuid, p_choices integer[])
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  u uuid := auth.uid(); d date := (clock_timestamp() at time zone 'Asia/Bangkok')::date;
  w date := date_trunc('week', clock_timestamp() at time zone 'Asia/Bangkok')::date;
  r league_private.rounds; daily integer; earned integer := 0; bonus integer := 0;
  correct integer := 0; award integer; i integer; expected jsonb;
begin
  if u is null then raise exception 'Sign in required'; end if;
  perform 1 from league_private.profiles where user_id = u for update;
  if not exists(select 1 from league_private.profiles where user_id = u and active) then raise exception 'Join the league first'; end if;
  select * into r from league_private.rounds where id = p_round and user_id = u for update;
  if r.id is null then raise exception 'Round not found'; end if;
  if r.finished_at is not null then return r.result; end if;
  if r.week <> w or clock_timestamp() > r.created_at + interval '20 minutes'
    then raise exception 'Round expired'; end if;
  if clock_timestamp() < r.created_at + interval '5 seconds' then raise exception 'Please finish the round'; end if;
  if cardinality(p_choices) is distinct from cardinality(r.answers) or array_ndims(p_choices) <> 1
    or array_lower(p_choices, 1) <> 1 or exists(select 1 from unnest(p_choices) x where x is null or x not between 0 and 3)
    then raise exception 'Invalid answers'; end if;
  select coalesce(sum(points),0) into daily from league_private.credits where user_id = u and day = d;
  for i in 1..cardinality(r.answers) loop
    if p_choices[i] = r.answers[i] then
      correct := correct + 1;
      if daily + earned < 100 and not exists(select 1 from league_private.credits
          where user_id = u and day = d and kind = 'review' and source_id = r.phrase_ids[i]) then
        award := least(5, 100 - daily - earned);
        insert into league_private.credits values(u, d, 'review', r.phrase_ids[i], award);
        earned := earned + award;
      end if;
    end if;
  end loop;
  if correct = cardinality(r.answers) and daily + earned < 100
    and not exists(select 1 from league_private.completed where user_id = u and lesson_id = r.lesson_id) then
    bonus := least(20, 100 - daily - earned);
    insert into league_private.credits values(u, d, 'lesson', r.lesson_id, bonus);
    insert into league_private.completed values(u, r.lesson_id);
    earned := earned + bonus;
  end if;
  update league_private.members set points = points + earned,
    reached_at = case when earned > 0 then clock_timestamp() else reached_at end where user_id = u and week = w;
  select jsonb_agg(jsonb_build_object('correct', p_choices[n] = r.answers[n], 'answer', r.answers[n]) order by n)
    into expected from generate_subscripts(r.answers, 1) n;
  r.result := jsonb_build_object('earned', earned, 'bonus', bonus, 'correct', correct,
    'total', cardinality(r.answers), 'daily_points', daily + earned, 'answers', expected);
  update league_private.rounds set finished_at = clock_timestamp(), result = r.result where id = r.id;
  return r.result;
end $$;

create function league_private.league_leave() returns void language plpgsql security definer set search_path = '' as $$
begin
  if auth.uid() is null then raise exception 'Sign in required'; end if;
  update league_private.profiles set active = false where user_id = auth.uid();
  update league_private.members set eligible = false where user_id = auth.uid()
    and week = date_trunc('week', clock_timestamp() at time zone 'Asia/Bangkok')::date;
end $$;

-- Public invoker wrappers call tightly scoped, non-exposed implementations.
grant usage on schema league_private to authenticated;
create function public.league_join(p_alias text, p_avatar integer default 0) returns void
language sql security invoker set search_path = '' as $$ select league_private.league_join(p_alias, p_avatar) $$;
revoke all on function public.league_join(text, integer) from public, anon;
revoke all on function league_private.league_join(text, integer) from public, anon;
grant execute on function public.league_join(text, integer) to authenticated;
grant execute on function league_private.league_join(text, integer) to authenticated;
create function public.league_board() returns jsonb
language sql security invoker set search_path = '' as $$ select league_private.league_board() $$;
revoke all on function public.league_board() from public, anon;
revoke all on function league_private.league_board() from public, anon;
grant execute on function public.league_board() to authenticated;
grant execute on function league_private.league_board() to authenticated;
create function public.league_begin_round() returns jsonb
language sql security invoker set search_path = '' as $$ select league_private.league_begin_round() $$;
revoke all on function public.league_begin_round() from public, anon;
revoke all on function league_private.league_begin_round() from public, anon;
grant execute on function public.league_begin_round() to authenticated;
grant execute on function league_private.league_begin_round() to authenticated;
create function public.league_submit_round(p_round uuid, p_choices integer[]) returns jsonb
language sql security invoker set search_path = '' as $$ select league_private.league_submit_round(p_round, p_choices) $$;
revoke all on function public.league_submit_round(uuid, integer[]) from public, anon;
revoke all on function league_private.league_submit_round(uuid, integer[]) from public, anon;
grant execute on function public.league_submit_round(uuid, integer[]) to authenticated;
grant execute on function league_private.league_submit_round(uuid, integer[]) to authenticated;
create function public.league_leave() returns void
language sql security invoker set search_path = '' as $$ select league_private.league_leave() $$;
revoke all on function public.league_leave() from public, anon;
revoke all on function league_private.league_leave() from public, anon;
grant execute on function public.league_leave() to authenticated;
grant execute on function league_private.league_leave() to authenticated;
commit;
