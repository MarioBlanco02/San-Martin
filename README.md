# La Matanza de San Martín 🐷🔪

Web del cumpleaños en Cañaveras (sábado 7 de noviembre). Cada invitado entra con su nombre y un PIN y ve:

- **Personaje**: disfraz (pieza clave ⭐ + extras), su **arma** (un solo uso) y su **canción maldita**.
- **Misión**: su víctima y su **acción secreta**. Se desbloquea sola a la hora de la cena; el sorteo forma un único círculo.
- **Juegos**: normas del pueblo (una al azar cada 20 min), control de disfraces, Juicio de la Matanza, canción maldita, chupito de luto y premios.
- **Programa** de la noche.

## Piezas

| Archivo | Qué hace |
|---|---|
| `template.html` | Toda la web: personajes, acciones, canciones y normas (se editan al principio del `<script>`). |
| `build.py` | Genera `site/index.html` con la conexión a Supabase. Sin conexión funciona en modo prueba. |
| `supabase/schema.sql` | Tablas, sorteo y PIN. Las tablas no son legibles desde la web: solo devuelve la tarjeta de quien mete su PIN. |
| `supabase/roster.sql` | Lista de invitados. |
| `.github/workflows/publicar.yml` | Publica la web en GitHub Pages en cada cambio. |

## Puesta en marcha (una vez)

1. **Supabase** → crea un proyecto **nuevo** (no el de la Fantasy).
   - *SQL Editor → New query*: pega `supabase/schema.sql` y **Run**. Después pega `supabase/roster.sql` con los nombres y **Run**.
   - *Project Settings → API*: copia la **Project URL** y la clave **anon**.
2. **GitHub** → *Settings → Secrets and variables → Actions → New repository secret*:
   - `SUPABASE_URL` y `SUPABASE_ANON_KEY`.
3. *Settings → Pages → Source*: **GitHub Actions**.
4. *Actions → Publicar web → Run workflow*. La URL sale en el despliegue: `https://marioblanco02.github.io/San-Martin/`.

## Durante la fiesta (SQL Editor)

- Cambiar la hora de desbloqueo: `update matanza_config set start_at = '2026-11-07 22:00 Europe/Madrid';`
- Añadir a alguien: `insert into matanza_roster (name) values ('Nombre');`
- Repetir el sorteo (si alguien entra tarde, antes de que nadie haya mirado su misión): `select matanza_regenerate();`
- Olvidó su PIN: `delete from matanza_players where name = 'Nombre';` (antes del sorteo; vuelve a entrar como nuevo).

**Para jugar limpio:** no abras la tabla `matanza_missions` en Supabase.

## Probar en local

`python build.py` y abre `site/index.html`. Añade `?ahora` a la URL para simular que ya es la hora de la cena.

- Asignar personaje a alguien pendiente: `update public.matanza_roster set character_id = 14 where name = 'Carlos';` (y añadir el personaje al array `CHARACTERS` de `template.html`).
- Cualquiera no listado puede apuntarse desde la web (botón «¿No estás en la lista?»); queda sin personaje hasta que se le asigne.
