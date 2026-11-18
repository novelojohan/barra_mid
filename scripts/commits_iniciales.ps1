# Crea el repositorio y los commits por capas con mensajes descriptivos.
# Úsalo UNA vez, desde la carpeta barra_mid, después de "flutter create".
#   PowerShell:  .\scripts\commits_iniciales.ps1
# Si PowerShell no deja correr scripts:  Set-ExecutionPolicy -Scope Process Bypass

git init
git branch -M main

function Commit($archivos, $mensaje) {
    git add -- $archivos
    git commit -q -m $mensaje
    Write-Host "OK  $mensaje"
}

# 1. Configuración (todo menos lib, test, docs y scripts)
git add .
git reset -q -- lib test docs scripts
git commit -q -m "chore: proyecto Flutter, dependencias y permisos de Android"
Write-Host "OK  chore: proyecto Flutter, dependencias y permisos de Android"

Commit @("lib/core/errors", "lib/core/utils", "lib/core/theme") "feat(core): excepciones propias, tema y formato de fechas en español"
Commit @("lib/domain") "feat(domain): modelos Insumo, Registro y Pendiente con serialización JSON y contratos de repositorio"
Commit @("lib/data") "feat(data): base de datos SQLite con transacciones, manejo de errores y datos iniciales de la barra"
Commit @("lib/services") "feat(services): biometría, cámara/galería, dictado por voz y GPS con manejo de permisos"
Commit @("lib/presentation/widgets") "feat(ui): widgets reutilizables de evidencia, dictado, mapa y estados de carga"
Commit @("lib/presentation/screens/login_screen.dart", "lib/presentation/screens/inventario_screen.dart") "feat(inventario): login con huella e inventario por nevera con conteo físico"
Commit @("lib/presentation/screens/bitacora_screen.dart", "lib/presentation/screens/registro_detalle_screen.dart", "lib/presentation/screens/registro_form_screen.dart") "feat(bitacora): lista, detalle con Hero y mapa, y formulario con foto, dictado y GPS"
Commit @("lib/presentation/screens/pendientes_screen.dart", "lib/presentation/screens/pendiente_form_screen.dart", "lib/presentation/screens/pendiente_detalle_screen.dart", "lib/presentation/screens/completar_pendiente_screen.dart", "lib/presentation/screens/tienda_screen.dart") "feat(pendientes): pendientes con foto de evidencia y verificación de tienda por GPS"
Commit @("lib/presentation/screens/acerca_screen.dart", "lib/core/routes", "lib/core/di", "lib/app.dart", "lib/main.dart") "feat(app): rutas con nombre, transiciones e inyección de dependencias"
Commit @("test") "test: pruebas de serialización de modelos"
Commit @("docs", "scripts") "docs: reporte técnico y script de commits"

git log --oneline
