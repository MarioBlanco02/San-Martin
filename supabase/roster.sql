-- Lista de invitados. Pégalo en SQL Editor > New query > Run DESPUÉS de schema.sql.
-- Para añadir a alguien más tarde: insert into public.matanza_roster (name) values ('Nombre');
insert into public.matanza_roster (name) values
  ('Mario')
  -- , ('Nombre 2')
  -- , ('Nombre 3')
on conflict do nothing;
