import 'package:flutter_test/flutter_test.dart';

import 'package:barra_mid/domain/models/geo_punto.dart';
import 'package:barra_mid/domain/models/insumo.dart';
import 'package:barra_mid/domain/models/pendiente.dart';
import 'package:barra_mid/domain/models/registro.dart';

/// Pruebas de los modelos: que se guarden y se lean igual de SQLite
/// (incluyendo la lista de items serializada en JSON).
void main() {
  test('Insumo detecta cuando está bajo el mínimo', () {
    const insumo = Insumo(
      nombre: 'Plátano',
      ubicacion: UbicacionInsumo.neveraGrande,
      unidad: 'botes',
      cantidad: 1,
      minimo: 3,
    );
    expect(insumo.bajoMinimo, isTrue);
    expect(insumo.copyWith(cantidad: 5).bajoMinimo, isFalse);
  });

  test('Registro se serializa y deserializa sin perder datos', () {
    final original = Registro(
      id: 7,
      tipo: TipoRegistro.produccion,
      items: const [
        RegistroItem(insumoId: 1, nombre: 'Plátano', unidad: 'botes', cantidad: 2),
        RegistroItem(insumoId: 3, nombre: 'Piña', unidad: 'botes', cantidad: 5),
      ],
      nota: 'Hay 5 en la nevera grande y 2 en barra',
      empleado: 'Johan',
      fecha: DateTime(2026, 11, 17, 8, 20),
      fotoPath: '/evidencias/evid_1.jpg',
      ubicacion: const GeoPunto(21.0285, -89.6227),
      enTienda: true,
    );

    final copia = Registro.fromMap(original.toMap());

    expect(copia.id, 7);
    expect(copia.tipo, TipoRegistro.produccion);
    expect(copia.items.length, 2);
    expect(copia.items[1].nombre, 'Piña');
    expect(copia.resumen, '2 Plátano, 5 Piña');
    expect(copia.ubicacion?.latitud, 21.0285);
    expect(copia.enTienda, isTrue);
    expect(copia.fecha, original.fecha);
  });

  test('Pendiente se completa con evidencia', () {
    final pendiente = Pendiente(
      id: 1,
      titulo: 'Limpieza de la Breville',
      descripcion: '',
      area: 'Breville',
      creadoPor: 'Sistema',
      fechaCreacion: DateTime(2026, 11, 17),
    );
    expect(pendiente.hecho, isFalse);

    final hecho = pendiente.completar(
      empleado: 'Mariana',
      evidenciaPath: '/evidencias/breville.jpg',
      nota: 'Se realiza limpieza de la breville :)',
    );
    final leido = Pendiente.fromMap(hecho.toMap());

    expect(leido.hecho, isTrue);
    expect(leido.completadoPor, 'Mariana');
    expect(leido.evidenciaPath, '/evidencias/breville.jpg');
  });
}
