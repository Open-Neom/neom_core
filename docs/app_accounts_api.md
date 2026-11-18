# Usuarios y perfiles mediante API

Los contratos `UserRepository` y `ProfileRepository` se conservan. Las nuevas
implementaciones son `AppUserApi` y `AppProfileApi`. `AccountRepository` agrega
las capacidades de alta atómica y carga estricta que necesita `UserController`;
`ProfileDirectoryRepository` agrega búsquedas independientes de Firestore.
Las implementaciones Firestore también implementan estas capacidades.

## Activación

Gigmeout e Itzli registran los repositorios antes de crear `UserController` en
`RootBinding`. `DataBackendPolicy` limita la activación a esas aplicaciones.
EMXI conserva Firestore. En `properties.json`:

```json
{"dataBackend":{"enabled":true,"baseUrl":"https://datos.example.test","usersEnabled":true,"profilesEnabled":true,"firebaseFallback":true,"syncEnabled":true,"timeoutMs":4000}}
```

**Gigmeout usa ahora `same-origin` exclusivamente en los orígenes autorizados**
`http://localhost:8787` y `http://127.0.0.1:8787`. El servidor local está en
`Gigmeout/server`; ver su README para instalación, alcance de red y limitaciones.
Itzli conserva la URL vacía. Firebase Hosting y clientes nativos sin URL explícita
continúan con Firestore. No hay publicación pública HTTPS todavía.
Los indicadores de usuarios y perfiles permiten activarlos por separado.
Firebase Authentication y los archivos de Storage no se migran con este cambio.

## Protocolo que debe implementar el servidor

Consultas: `POST /v1/apps/{app}/users/query` y
`POST /v1/apps/{app}/profiles/query`; `app` es el valor del enum (`g` o `i`).
El cuerpo contiene `operation`, `arguments`, `audience` y un `cursor` opcional.
Los nombres de operación y argumentos corresponden a los métodos del adaptador.
Se usa POST para evitar correos y filtros privados en las URLs.

Respuesta de carga de cuenta, como ejemplo de estructura:

```json
{"actorUid":"firebase-uid","items":[{"id":"LegacyCase","email":"owner@example.test","currentProfileId":"profile-id","profiles":[{"id":"profile-id","name":"Owner"}]}]}
```

Las respuestas privadas requieren `actorUid` correspondiente a la sesión.
El servidor debe verificar el ID token de Firebase, su proyecto, permisos y
propiedad de los datos; el UID enviado en el cuerpo no constituye autorización.
La cuenta conserva mayúsculas en sus identificadores y sus perfiles anidados.
Las listas paginadas devuelven `items` y `nextCursor`.

Un servidor sin datos importados devuelve `ready:false`, lo que permite acudir a
Firestore. Una cuenta vacía sólo representa una ausencia confirmada con
`items:[]` y `authoritative:true`. Ese indicador exige que el servidor haya
comprobado la ausencia real: no basta con que la base local esté vacía.
Esto evita iniciar un alta duplicada durante la migración.

Las respuestas públicas de perfiles requieren `visibility:public`,
`schemaVersion:1` y `directoryVisible:true`. El cliente aplica además la
proyección pública y la política de teléfono, incluyendo en el respaldo.
Los perfiles propios se obtienen mediante la ruta privada de cuenta.

Mutaciones: `POST /v1/apps/{app}/{users|profiles}/operations`.
Cada operación contiene `operationId`, `kind`, `resource`, `arguments` y `actor`;
el encabezado `Idempotency-Key` lleva el mismo identificador. El servidor debe
persistir la operación y su recibo de forma atómica, y responder
`acknowledgedOperationId` y el `value` esperado por el método. Repetir una clave
debe devolver el mismo resultado sin repetir el efecto. El alta con perfil es
una sola operación atómica; nunca dos escrituras independientes.

## Respaldo y sincronización

Una lectura usa Firestore ante indisponibilidad de transporte, timeout,
502/503/504 o `ready:false`, si el indicador lo permite. No se ocultan errores
de permisos, respuestas malformadas ni cambios de sesión mediante ese respaldo.
Los diagnósticos del cliente son `lastReadSource`, `serverReadCount`,
`firestoreReadCount` y `lastSyncError`.

Después de leer Firestore se encolan referencias `reconcileFirestore` con ID y
audiencia, sin copiar cuentas privadas completas en la cola de conciliación.
El servidor debe recuperar y conciliar esos documentos de manera autorizada.
Las operaciones de escritura se guardan en una cola Hive separada por app,
recurso y usuario. Ante resultado incierto se informa `AppDataWritePending`:
no se repite la escritura en Firebase, pues podría duplicar un efecto ya aplicado.
Se reintentan tras una lectura exitosa o mediante `flushPending()`. No hay
sincronizador permanente independiente de la aplicación. Las actualizaciones
de token Spotify no se persisten en esta cola.

## Límites de esta etapa

`ProfileRepository.handleSearch` aún retorna `QuerySnapshot`, un tipo específico
de Firestore; se mantiene como legado. La búsqueda portable utiliza
`ProfileDirectoryRepository.searchByName`. Las llamadas concretas que aún crean
`ProfileFirestore` o `UserFirestore` directamente fuera de los flujos migrados
siguen usando Firebase; esta etapa no elimina toda dependencia de la nube.

En web pública se necesita HTTPS y CORS para el origen real, incluyendo las
cabeceras Authorization, Content-Type e Idempotency-Key. `localhost` apunta a la
computadora del visitante, por lo que no sirve como URL pública del Mac servidor.
Los endpoints y la importación ya se implementaron en `Gigmeout/server`. Se
comprobó desde navegador local la lectura de catálogo/perfil y el respaldo real
a Firestore frente a HTTP 503. La comprobación de una cuenta privada con sesión
real requiere iniciar sesión en ese origen. Para activar acceso externo sigue
siendo necesario configurar y validar dominio, HTTPS y CORS.

## Verificación local de esta implementación

Se verificaron 127 casos únicos: adaptadores de cuentas y perfiles (26),
catálogo y regresiones de cuenta/identidad/roles (67), y modelo, privacidad y
localización de perfiles (34). Entre ellos hay una prueba con HTTP real en
loopback: primero carga desde el servidor, después se apaga el servidor y se
comprueba el respaldo Firestore y la referencia de conciliación pendiente.
Los respaldos de estas pruebas son dobles controlados; no se escriben datos
del proyecto Firebase. Estas pruebas no sustituyen la validación de endpoints
públicos de producción, que aún necesitan su acceso HTTPS externo.

La compilación web JavaScript de Gigmeout terminó correctamente con
`flutter build web --no-pub --no-tree-shake-icons --no-wasm-dry-run`.
Artefacto local: `/Users/serzen/GigmeoutServer/build-checks/accounts-api-web`.
No se publicó ni se completó la comprobación opcional WebAssembly. El analizador
no reportó observaciones en los adaptadores ni en RootBinding/main de Gigmeout;
Itzli conserva el aviso previo de dependencia no declarada de `uuid`.
