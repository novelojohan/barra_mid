# Guía para la defensa (preguntas que te pueden hacer)

**¿Qué problema resuelve tu app?**
En la barra de Mid Market todo se reportaba por WhatsApp con fotos, la producción, los mixes y las limpiezas, y nadie sabía cuántos botes quedaban ni quién hizo qué. La app lleva el inventario por nevera, guarda cada movimiento con foto, nota y ubicación, y los pendientes solo se cierran con foto de evidencia

**¿Cómo está organizado el código?**
Por capas. core tiene rutas, errores y el injector. domain tiene los modelos y las interfaces de los repositorios. data es la parte de SQLite. services es todo lo de hardware: huella, cámara, micrófono y GPS. presentation son las pantallas y los widgets

**¿Dónde aplicas SOLID?**
Lo más claro es la D. Las pantallas no usan SQLite directo, piden un RegistroRepository que es una interfaz y el Injector decide que por dentro sea SQLite. Si mañana lo cambio a Firebase no toco las pantallas. La S también se ve, cada servicio hace una sola cosa, MediaService solo fotos y LocationService solo GPS

**¿Por qué SQLite y no SharedPreferences?**
Porque tengo datos con relación y muchos registros. SharedPreferences es para cosas chiquitas tipo configuración. Además con SQLite puedo usar transacciones

**¿Para qué usas una transacción?**
Cuando guardo un registro hago dos cosas: inserto el registro y actualizo las cantidades del inventario. Si una falla no quiero que quede a medias, entonces va todo junto o no se guarda nada

**¿Dónde usas JSON?**
Un registro puede tener varios insumos, por ejemplo 2 de plátano y 5 de piña. Esa lista la convierto a JSON con jsonEncode y la guardo en la columna items_json. Al leerla uso jsonDecode y la vuelvo a convertir en objetos

**¿Cómo manejas los errores?**
Los repositorios usan un mixin que se llama ManejoErroresDb con un try-catch que convierte cualquier error de SQLite en StorageException con un mensaje entendible. Los servicios hacen lo mismo con PermissionDeniedException y DeviceServiceException. La pantalla nada más muestra el mensaje en un SnackBar o una vista con botón de reintentar, la app no truena

**¿Qué pasa si el usuario niega el permiso de ubicación?**
Sale un diálogo que te deja ir a Ajustes, cancelar o guardar sin ubicación. Si lo guardas así, el registro queda como Sin verificar. Con la cámara y el micrófono pasa algo parecido, te avisa y te da el botón de Ajustes

**¿Para qué usas FutureBuilder y por qué el Future va en initState?**
Leer de la base de datos es asíncrono. FutureBuilder muestra el CircularProgressIndicator mientras carga, el error si falla o la lista cuando ya hay datos. El Future lo creo en initState porque si lo creo en build se volvería a consultar la base cada vez que la pantalla se redibuja

**¿Cómo funciona la navegación?**
Uso rutas con nombre y onGenerateRoute, ahí también pongo la animación de transición. Del Drawer uso pushReplacementNamed para que la pila no crezca y el botón de atrás no te regrese infinitamente. Cerrar turno usa pushNamedAndRemoveUntil para limpiar todo y volver al login

**¿Dónde está el Hero?**
En la foto de la lista de la bitácora y de los pendientes hechos. Las dos pantallas usan el mismo tag, registro- más el id, entonces Flutter anima la foto de la lista al detalle

**¿Cómo funciona el dictado?**
Uso speech_to_text, que captura el audio del micrófono y lo manda al reconocedor de voz del celular. Busco el idioma es_MX y el texto se va escribiendo en el campo mientras hablas. Si ya habías escrito algo, lo dictado se agrega al final

**¿Cómo sabe la app si estás en la tienda?**
Primero guardas una vez la ubicación de Mid Market. Cada vez que guardas algo tomo el GPS y con Geolocator.distanceBetween calculo la distancia. Si es menos de 150 metros se marca En tienda

**¿Por qué copias la foto a otra carpeta?**
image_picker la deja en una carpeta temporal que el sistema puede borrar. Entonces la copio a la carpeta de documentos de la app y en la base guardo esa ruta. Si sales del formulario sin guardar, la borro para no dejar basura

**¿Cómo funciona el login con huella?**
Con local_auth. Primero reviso si el celular tiene huella o PIN. Si sí, pido autenticar y si sale bien entras. Si el celular no tiene bloqueo te aviso que no es seguro y te pregunto si quieres entrar. El MainActivity tiene que extender FlutterFragmentActivity porque si no, la huella no funciona

**¿Por qué flutter_map y no Google Maps?**
Porque Google Maps necesita API key y cuenta de facturación. flutter_map usa OpenStreetMap gratis y sigue siendo interactivo, puedes mover y hacer zoom. Y de todos modos tengo el botón que abre las coordenadas en Google Maps

**¿Qué le agregarías después?**
Sincronizar varios celulares con Firebase para que toda la barra vea lo mismo, y notificaciones cuando un insumo baje del mínimo para pedir requisición
