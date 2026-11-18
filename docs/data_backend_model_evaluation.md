# Evaluación de modelos para migración local

Evaluación del código disponible, 22 de octubre de 2026. La prioridad responde
al objetivo de arrancar Gigmeout y permitir posteriormente Itzli sin alterar EMXI.
Los adaptadores pertenecen a los repositorios; los modelos no deben decidir el
destino de cada petición. La política por aplicación y recurso toma esa decisión.

| Prioridad | Modelos o datos | Implementación y condición |
| --- | --- | --- |
| P0 | AppUser | AppUserApi agregado. Mantener Firebase Auth como identidad; carga privada estricta y alta atómica con perfil. Roles, compras, verificación y suscripciones requieren autorización del servidor. |
| P0 | AppProfile | AppProfileApi agregado. Separar perfil público de cuenta privada, respetar directorio y privacidad, conservar slugs e IDs existentes. |
| P0 | AppReleaseItem | Adaptador API existente en esta migración. Es el catálogo inicial de Gigmeout; verificar visibilidad, derechos y paginación en el servidor. |
| P1 | AppMediaItem y archivos de audio, imagen, video | Migrar metadatos mediante repositorio; servir los bytes por un servicio de archivos con soporte de rangos y autorización. No almacenar MP3 dentro de documentos o de la cola de sincronización. |
| P1 | Itemlist y playlists | Adaptador propio para listas y pertenencia ordenada. Hay rutas heredadas de hidratación que todavía consultan Firestore; migrarlas para que el catálogo pueda operar sin nube. |
| P2 | Posts, comentarios, eventos, favoritos y relaciones sociales | Operaciones idempotentes de agregar/quitar, versiones y borrado con tombstones; evitar sustituir listas completas desde réplicas desactualizadas. |
| P2 | Documentos y metadatos de EMXI | Misma separación entre documentos y archivos. Mantener desactivado el backend local hasta validar permisos, búsqueda y copias; EMXI sigue en Firebase ahora. |
| P3 | Inbox e InboxMessage | Requieren streams, orden y reanudación de mensajes. Añadir WebSocket o equivalente con cursor y cierre al terminar sesión; el patrón fetch/post por sí solo no reemplaza el tiempo real. |
| P3 | Pedidos, transacciones, wallet y facturas | Una autoridad de escritura y transacciones verificadas en servidor. No aplicar conmutación automática de escrituras financieras entre dos bases independientes. |
| P3 | Memorias y corpus de Itzli | Persistencia de hechos/documentos con ámbito app/usuario y adaptadores propios para índice vectorial. La inferencia puede vivir en la Mac Mini sin mezclarla con la API de datos. |
| Posterior | Cámaras, presets, frecuencias y sesiones VR | Metadatos compatibles con repositorios; señales EEG y posiciones por fotograma necesitan transporte de estado o lotes, no una escritura documental por muestra. |

## Hallazgos concretos

- `AppUser.toJSON` no incorpora ID ni currentProfileId y `fromJSON` no reconstruye
  los perfiles anidados. El adaptador los trata explícitamente; reutilizar sólo
  esos serializadores perdería información al cargar desde HTTP.
- La posición en AppProfile tiene un formato legado codificado como texto JSON.
  El codec API acepta también un objeto JSON sin cambiar el formato existente de
  Firestore. No se debe cambiar globalmente el modelo durante esta migración.
- El contrato de búsqueda de perfiles expone `QuerySnapshot`. Se conserva la
  compatibilidad y se agregan búsquedas portables mediante una capacidad aparte.
- Existen escrituras directas a Firestore en módulos de perfil/autenticación y
  otras rutas heredadas. Registrar un repositorio en RootBinding no intercepta
  esas instancias concretas: deberán migrarse por flujo con verificación propia.
- `neom_memory` usa actualmente una caja Hive `neom_memoria` y claves de resumen
  globales. Antes de llevarlo a un servicio compartido debe dividirse por app y
  usuario. Esta evaluación no modifica esa persistencia.

## Reglas para los siguientes adaptadores

Conservar los contratos, identificadores y subcolecciones lógicas; añadir DTOs
HTTP explícitos cuando el JSON legado sea incompleto. Separar política de lectura,
autenticación y cola. El servidor debe aplicar versiones, permisos y resolución
de conflictos; una cola de referencias no realiza por sí sola una réplica completa.
Definir para cada recurso autoridad, versión, deletedAt y estrategia de conflicto
antes de permitir escrituras desde más de un origen.

Para arrancar Gigmeout, completar primero cuenta/perfil, catálogo, playlists y
servicio de archivos. Validar desde web pública lectura del servidor, caída hacia
Firestore, recuperación de la cola y sesión de otro usuario. Después activar
gradualmente por recurso. Hasta disponer de endpoints compatibles y una URL
configurada, las aplicaciones continúan leyendo Firestore.
