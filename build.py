#!/usr/bin/env python3
"""Genera site/index.html. Con SUPABASE_URL y SUPABASE_ANON_KEY se conecta al servidor; sin ellas funciona en modo prueba."""
import json, os
tpl = open("template.html", encoding="utf-8").read()
url, key = os.environ.get("SUPABASE_URL"), os.environ.get("SUPABASE_ANON_KEY")
cfg = json.dumps({"url": url, "key": key}) if url and key else "null"
os.makedirs("site", exist_ok=True)
open("site/index.html", "w", encoding="utf-8").write(tpl.replace("/*CONFIG*/null", cfg))
print("site/index.html generado", "con Supabase" if cfg != "null" else "en modo prueba")
