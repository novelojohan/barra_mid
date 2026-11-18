#!/usr/bin/env bash
# Versión para Git Bash / Mac / Linux. Úsalo UNA vez desde la carpeta barra_mid:
#   bash scripts/commits_iniciales.sh
set -e
git init
git branch -M main

commit() { msg="$1"; shift; git add -- "$@"; git commit -q -m "$msg"; echo "OK  $msg"; }

git add .
git reset -q -- lib test docs scripts
git commit -q -m "chore: proyecto Flutter, dependencias y permisos de Android"

commit "feat(core): excepciones propias, tema y formato de fechas en español" lib/core/errors lib/core/utils lib/core/theme
commit "feat(domain): modelos Insumo, Registro y Pendiente con serialización JSON y contratos de repositorio" lib/domain
commit "feat(data): base de datos SQLite con transacciones, manejo de errores y datos iniciales de la barra" lib/data
commit "feat(services): biometría, cámara/galería, dictado por voz y GPS con manejo de permisos" lib/services
commit "feat(ui): widgets reutilizables de evidencia, dictado, mapa y estados de carga" lib/presentation/widgets
commit "feat(inventario): login con huella e inventario por nevera con conteo físico" lib/presentation/screens/login_screen.dart lib/presentation/screens/inventario_screen.dart
commit "feat(bitacora): lista, detalle con Hero y mapa, y formulario con foto, dictado y GPS" lib/presentation/screens/bitacora_screen.dart lib/presentation/screens/registro_detalle_screen.dart lib/presentation/screens/registro_form_screen.dart
commit "feat(pendientes): pendientes con foto de evidencia y verificación de tienda por GPS" lib/presentation/screens/pendientes_screen.dart lib/presentation/screens/pendiente_form_screen.dart lib/presentation/screens/pendiente_detalle_screen.dart lib/presentation/screens/completar_pendiente_screen.dart lib/presentation/screens/tienda_screen.dart
commit "feat(app): rutas con nombre, transiciones e inyección de dependencias" lib/presentation/screens/acerca_screen.dart lib/core/routes lib/core/di lib/app.dart lib/main.dart
commit "test: pruebas de serialización de modelos" test
commit "docs: reporte técnico y script de commits" docs scripts

git log --oneline
