/// Para enseñar las fechas bonitas y en español (ej. "martes 17 de noviembre")
class DateFormatter {
  DateFormatter._(); // Nadie crea objetos de esta clase, solo uso sus funciones

  static const _meses = [
    'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
    'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
  ];

  static const _dias = [
    'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo',
  ];

  /// Fecha completa. Ej: "martes 17 de noviembre de 2026"
  static String fechaLarga(DateTime fecha) {
    // weekday va de 1 a 7, por eso le resto 1 para usarlo en la lista
    final dia = _dias[fecha.weekday - 1];
    return '$dia ${fecha.day} de ${_meses[fecha.month - 1]} de ${fecha.year}';
  }

  /// Fecha corta para las listas. Ej: "17 nov · 16:26"
  static String fechaCorta(DateTime fecha) {
    final mes = _meses[fecha.month - 1].substring(0, 3);
    return '${fecha.day} $mes · ${hora(fecha)}';
  }

  /// Solo la hora. padLeft pone un 0 adelante (9 -> 09)
  static String hora(DateTime fecha) {
    final h = fecha.hour.toString().padLeft(2, '0');
    final m = fecha.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
