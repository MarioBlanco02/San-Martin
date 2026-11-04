-- Invitados y su personaje. Pégalo en SQL Editor > New query > Run DESPUÉS de schema.sql.
-- character_id: ver la lista PERSONAJES en template.html
--   1 Padrino · 2 Alien (Marco) · 3 Alien (Monti) · 4 FBI (Alba) · 5 FBI (Vero)
--   6 Vaquera (Alicia) · 7 Vaquera (Sandra) · 8 Hombre de Negro · 9 Preso · 10 Sonámbulo
--   11 King África · 12 Runner · 13 Ned Flanders · 14 Viejo (Manu) · 15 Vieja (Carmen) · 16 Viejo (Carlos)
-- Los que van con null aún no han confirmado disfraz.
-- Cuando confirmen:  update public.matanza_roster set character_id = 14 where name = 'Carlos';
insert into public.matanza_roster (name, character_id) values
  ('Mario', 1),
  ('Marco', 2),
  ('Monti', 3),
  ('Alba', 4),
  ('Vero', 5),
  ('Alicia', 6),
  ('Sandra', 7),
  ('Ignacio', 8),
  ('Pablo Blanco', 9),
  ('Rubén', 10),
  ('Elena', 11),
  ('Juanjo', 12),
  ('Ismael', 13),
  ('Carlos', 16),
  ('Carmen', 15),
  ('Sabina', null),
  ('Manu', 14)
on conflict (name) do update set character_id = excluded.character_id;
