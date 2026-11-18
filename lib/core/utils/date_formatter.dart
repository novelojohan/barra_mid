/// Utilidad sencilla para mostrar fechas en español sin depender de `intl`.
class DateFormatter {
  DateFormatter._(); // Clase estática, no se instancia.

  static const _meses = [
    'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
    'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
  ];

  static const _dias = [
    'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo',
  ];

  /// Ej: "martes 17 de noviembre de 2026"
  static String fechaLarga(DateTime fecha) {
    final dia = _dias[fecha.weekday - 1];
    return '$dia ${fecha.day} de ${_meses[fecha.month - 1]} de ${fecha.year}';
  }

  /// Ej: "17 nov · 16:26"
  static String fechaCorta(DateTime fecha) {
    final mes = _meses[fecha.month - 1].substring(0, 3);
    return '${fecha.day} $mes · ${hora(fecha)}';
  }

  /// Ej: "16:26"
  static String hora(DateTime fecha) {
    final h = fecha.hour.toString().padLeft(2, '0');
    final m = fecha.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
