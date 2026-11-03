-- La Matanza de San Martín · esquema de Supabase
-- Pégalo entero en SQL Editor > New query > Run (proyecto NUEVO, no el de la Fantasy).
-- Nadie accede a las tablas directamente: todo pasa por funciones que solo
-- devuelven la tarjeta de quien mete su nombre y su PIN.

create extension if not exists pgcrypto with schema extensions;

-- ---------- Configuración ----------
create table public.matanza_config (
  id          int primary key default 1 check (id = 1),
  start_at    timestamptz not null,          -- cuándo se desbloquean las misiones
  n_characters int not null default 20,      -- nº de personajes del juego (página)
  n_actions   int not null default 30,       -- nº de acciones aleatorias (página)
  n_songs     int not null default 24        -- nº de canciones malditas (página)
);
insert into public.matanza_config (start_at)
values ('2026-11-07 21:30:00 Europe/Madrid');  -- CAMBIA AQUÍ LA HORA DE LA CENA

-- ---------- Jugadores ----------
create table public.matanza_roster (            -- lista de invitados (ver roster.sql)
  name text primary key
);

create table public.matanza_players (
  name         text primary key references public.matanza_roster on delete cascade,
  pin_hash     text not null,
  character_id int  not null,
  song_id      int  not null,
  created_at   timestamptz not null default now()
);

create table public.matanza_missions (          -- se rellena sola al llegar la hora
  name      text primary key references public.matanza_players on delete cascade,
  target    text not null references public.matanza_players,
  action_id int  not null
);

alter table public.matanza_config   enable row level security;
alter table public.matanza_roster   enable row level security;
alter table public.matanza_players  enable row level security;
alter table public.matanza_missions enable row level security;
-- Sin políticas: la web no puede leer ninguna tabla. Solo las funciones de abajo.

-- ---------- Sorteo de la cadena (un único círculo) ----------
create function public.matanza_generate() returns void
language plpgsql security definer set search_path = public, extensions as $$
declare
  cfg   public.matanza_config;
  names text[];
  acts  int[];
  n     int;
  i     int;
begin
  select * into cfg from public.matanza_config where id = 1 for update;  -- evita dos sorteos a la vez
  if exists (select 1 from public.matanza_missions) then return; end if;

  select array_agg(name order by random()) into names from public.matanza_players;
  n := coalesce(array_length(names, 1), 0);
  if n < 2 then return; end if;

  -- acciones barajadas; si hay más jugadores que acciones, se repiten
  select array_agg(a order by random()) into acts from generate_series(1, cfg.n_actions) a;

  for i in 1..n loop
    insert into public.matanza_missions (name, target, action_id)
    values (names[i], names[(i % n) + 1], acts[((i - 1) % cfg.n_actions) + 1]);
  end loop;
end $$;

-- Solo desde el editor SQL, si hay que repetir el sorteo:  select public.matanza_regenerate();
create function public.matanza_regenerate() returns void
language plpgsql security definer set search_path = public as $$
begin
  delete from public.matanza_missions;
  perform public.matanza_generate();
end $$;
revoke execute on function public.matanza_generate()   from public, anon, authenticated;
revoke execute on function public.matanza_regenerate() from public, anon, authenticated;

-- ---------- Lo que ve la pantalla de entrada ----------
create function public.matanza_status() returns json
language sql security definer stable set search_path = public as $$
  select json_build_object(
    'roster',   coalesce((select json_agg(name order by name) from public.matanza_roster), '[]'),
    'claimed',  coalesce((select json_agg(name) from public.matanza_players), '[]'),
    'start_at', (select start_at from public.matanza_config where id = 1),
    'now',      now());
$$;

-- ---------- Entrar (la primera vez crea el PIN) ----------
create function public.matanza_enter(p_name text, p_pin text) returns json
language plpgsql security definer set search_path = public, extensions as $$
declare
  cfg  public.matanza_config;
  pl   public.matanza_players;
  m    public.matanza_missions;
  ch   int;
  so   int;
  late boolean := false;
begin
  if p_pin !~ '^\d{4}$' then raise exception 'El PIN son 4 cifras'; end if;
  if not exists (select 1 from public.matanza_roster where name = p_name) then
    raise exception 'Ese nombre no está en la lista';
  end if;
  select * into cfg from public.matanza_config where id = 1;
  select * into pl  from public.matanza_players where name = p_name;

  if pl.name is null then
    -- primera vez: personaje y canción al azar, sin repetir mientras queden libres
    perform pg_advisory_xact_lock(4242);
    select c into ch from generate_series(1, cfg.n_characters) c
      where c not in (select character_id from public.matanza_players)
      order by random() limit 1;
    if ch is null then ch := 1 + floor(random() * cfg.n_characters)::int; end if;
    select s into so from generate_series(1, cfg.n_songs) s
      where s not in (select song_id from public.matanza_players)
      order by random() limit 1;
    if so is null then so := 1 + floor(random() * cfg.n_songs)::int; end if;
    insert into public.matanza_players (name, pin_hash, character_id, song_id)
    values (p_name, crypt(p_pin, gen_salt('bf')), ch, so)
    returning * into pl;
    late := exists (select 1 from public.matanza_missions);
  elsif pl.pin_hash <> crypt(p_pin, pl.pin_hash) then
    raise exception 'PIN incorrecto';
  end if;

  if now() >= cfg.start_at then
    perform public.matanza_generate();
    select * into m from public.matanza_missions where name = p_name;
    if m.name is null then late := true; end if;
  end if;

  return json_build_object(
    'name',         pl.name,
    'character_id', pl.character_id,
    'song_id',      pl.song_id,
    'start_at',     cfg.start_at,
    'now',          now(),
    'started',      now() >= cfg.start_at,
    'late',         late,
    'target',       m.target,
    'action_id',    m.action_id);
end $$;

grant execute on function public.matanza_status()          to anon, authenticated;
grant execute on function public.matanza_enter(text, text) to anon, authenticated;
