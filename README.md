# TRANSFER — consola de transferencias

[![CI](https://github.com/anaarismendy/prueba-tecnica-flutter/actions/workflows/ci.yml/badge.svg)](https://github.com/anaarismendy/prueba-tecnica-flutter/actions/workflows/ci.yml)

Prueba técnica en Flutter: autenticación, gestión de usuarios y transferencias
con comprobante, sobre Clean Architecture con BLoC e inyección de dependencias.

## Cómo correrlo

```bash
flutter pub get
dart run build_runner build     # genera la DI y freezed
flutter run
```

### Credenciales de acceso

La base arranca vacía, así que en el primer inicio se siembra un usuario:

| Correo | Contraseña |
|---|---|
| `admin@test.com` | `Admin123` |

También aparecen en la propia pantalla de acceso para no tener que buscarlas.

### Plataformas

Probado en Windows escritorio y Android. En Windows y Linux SQLite entra por
`sqflite_common_ffi`; en Android, iOS y macOS usa el motor nativo. La selección
es automática en `AppDatabase.open()`.

## Integración continua

`.github/workflows/ci.yml` corre en cada push a `main` y en cada pull request:
formato, `flutter analyze` y las 104 pruebas, contra Flutter 3.44.6 en Ubuntu.

Las tres son barreras, no avisos: si alguna falla, el build queda rojo. El
código generado (`*.freezed.dart`, `*.config.dart`) está versionado, así que CI
no necesita correr `build_runner`.

## Requisitos cubiertos

| Requisito | Dónde |
|---|---|
| Inicio de sesión con validaciones | `LoginPage` + `Login` |
| CRUD de usuarios | `UsersPage`, `UserFormPage` + casos de uso |
| Transferencias con comprobante | `TransfersPage`, `TransferFormPage`, `ReceiptPage` |
| Flutter Bloc | `AuthBloc`, `UsersBloc`, `TransfersBloc` |
| Clean Architecture | `core` / `domain` / `data` / `presentation` |
| Inyección de dependencias | `get_it` + `injectable` |
| Manejo de errores | `Result<T>` + `Failure` sellados |
| Almacenamiento local | SQLite vía `sqflite` |

## Estructura

```
lib/
├── core/
│   ├── result.dart              Result<T> sellado: Ok / Err
│   ├── format.dart              pesos, fechas y teclado, sin dependencias
│   ├── theme.dart               paleta lavanda y tokens
│   ├── errors/failures.dart     Failure sellado
│   └── di/                      get_it + injectable
├── domain/
│   ├── entities/                User, Transfer (freezed)
│   ├── repositories/            contratos abstractos
│   ├── services/                PasswordHasher (contrato)
│   ├── usecases/                una clase por acción
│   └── validation.dart          reglas de nombre, correo y contraseña
├── data/
│   ├── models/                  mappers entidad ↔ fila
│   ├── datasources/             acceso crudo a SQLite; lanzan
│   ├── repositories/            traducen excepción → Failure
│   └── services/                BcryptPasswordHasher
└── presentation/
    ├── blocs/                   un bloc por módulo
    ├── pages/                   pantallas
    └── widgets/
        ├── soft.dart            kit neumórfico: relieve, campos, botones
        └── movement_row.dart    fila de movimiento, enviado o recibido
```

La regla que sostiene todo: `domain` no importa nada de `data` ni de
`presentation`, y solo `data` sabe que SQLite existe.

## El diseño

La interfaz replica un diseño neumórfico en lavanda y azul: tarjetas con
relieve, campos hundidos, degradado de marca en los acentos, barra inferior de
cinco ranuras con el botón de transferir elevado en el centro.

Las siete pantallas son acceso, inicio, contactos, formulario de contacto,
historial, perfil y el flujo de transferencia en tres pasos (a quién, cuánto con
teclado propio, y confirmar) que termina en el comprobante.

Tres cosas del diseño no existen en la base y se **derivan** en vez de guardarse:

| Dato | De dónde sale |
|---|---|
| Enviado / recibido | de si la sesión es el origen o el destino |
| Color del avatar | del hash del id, así el mismo usuario siempre se ve igual |
| Contactos frecuentes | de contar transferencias, no de una tabla aparte |

Falta, por no estar en el modelo: teléfono y número de cuenta del contacto (en
su lugar se muestra el correo), y los seis colores elegibles del formulario.

## El saldo

El saldo **sí se guarda**: `users.balance_in_cents`. Cada cuenta nace con un
cupo de apertura (`openingBalanceInCents`) porque no existe el concepto de
consignación; esa constante es la única simplificación que queda.

Una transferencia es **un solo hecho**, no tres:

```dart
_db.transaction((txn) async {
  UPDATE users SET balance_in_cents = balance_in_cents - ? WHERE id = origen
  UPDATE users SET balance_in_cents = balance_in_cents + ? WHERE id = destino
  INSERT INTO transfers ...
});
```

Si el débito deja el saldo en negativo, el `CHECK` con nombre
`balance_not_negative` lanza y **se deshace todo**, incluido el movimiento. Eso
está probado: la prueba verifica que tras un intento sin fondos no quedó ni el
registro ni un saldo movido a medias.

El caso de uso valida los fondos antes, por la misma razón de siempre: para
decir *"El saldo no alcanza"* en vez de un error genérico de base.

Dos detalles que salieron de escribirlo:

- **Editar un usuario no escribe el saldo.** Si lo hiciera, cambiar un nombre
  con una pantalla vieja abierta pisaría el saldo con el valor que esa pantalla
  traía en memoria.
- **El inicio no confía en el usuario de la sesión.** Ese objeto es una foto del
  momento del login; el saldo fresco sale de la lista que el bloc recarga
  después de cada movimiento.

### La migración a la versión 2

`onUpgrade` agrega la columna y **reconstruye los saldos desde el historial que
ya estaba guardado** (cupo, más lo recibido, menos lo enviado). Sin eso una base
vieja quedaría con todos en el mismo saldo, contradiciendo sus propios
movimientos.

Hay una prueba que crea una base con el esquema de la versión 1, le mete datos,
y la abre con la app de hoy. Es el único camino que corre sobre datos que ya
existen: si se rompe, se rompen los datos de alguien.

Un límite honesto: SQLite no sabe agregar un `CHECK` con `ALTER TABLE`, así que
en una base migrada la columna llega sin `balance_not_negative`. La regla se
sigue validando en el caso de uso. Igualarlos exige recrear la tabla y copiar.

## Decisiones que vale la pena explicar

**El dinero se guarda como entero en centavos**, nunca `double`. Los flotantes
pierden precisión al sumar y en transferencias eso es un error real.

**Las contraseñas usan bcrypt, no SHA-256.** SHA está diseñado para ser rápido,
lo que lo hace malo para contraseñas; bcrypt es lento a propósito y genera el
salt solo. La contraseña en claro nunca entra a una entidad: viaja como
parámetro y muere en el caso de uso.

**Credenciales inválidas devuelven el mismo error** exista o no el correo.
Distinguirlos permitiría averiguar qué correos están registrados.

**La base garantiza la integridad, no solo el código:**

```sql
email             TEXT NOT NULL COLLATE NOCASE UNIQUE
balance_in_cents  INTEGER NOT NULL DEFAULT 0
                  CONSTRAINT balance_not_negative CHECK (balance_in_cents >= 0)
amount_in_cents   INTEGER NOT NULL CHECK (amount_in_cents > 0)
CHECK (source_user_id <> destination_user_id)
source_user_id    TEXT NOT NULL REFERENCES users(id)
```

Las reglas se validan además en los casos de uso, pero por otra razón: dar un
mensaje útil. El `CHECK` rechaza un monto en cero, pero devuelve un error
genérico de base de datos; el caso de uso devuelve *"El valor debe ser mayor a
cero"*. El dominio da el buen mensaje, la base da la garantía.

**No se puede eliminar un usuario con transferencias.** La llave foránea lo
impide y se traduce a un `Failure` con mensaje claro. En un dominio financiero
dejar movimientos huérfanos es peor que negar el borrado.

**`Result<T>` propio en vez de `dartz`.** Las sealed classes de Dart 3 ya dan
exhaustividad en el `switch`, así que no hace falta la dependencia.

**Sin `hive_ce_generator`.** Exige `analyzer ^14` e `injectable_generator` está
en `^13`; no pueden coexistir. Se migró de Hive a SQLite, que además encaja
mejor con datos relacionales. `domain` no cambió ni una línea en esa migración.

## Patrones aplicados

| Patrón | Dónde |
|---|---|
| Repository | contratos en `domain`, implementaciones en `data` |
| Use Case | una clase por acción, con `call()` |
| Service Locator | `get_it` |
| Observer | BLoC |
| Result / Either | `Result<T>` en vez de excepciones que suben a la UI |
| Adapter | mappers entidad ↔ fila |

## Pruebas

```bash
flutter test
```

104 pruebas. `test/` espeja las carpetas de `lib/`, así que cada archivo se
prueba donde vive:

```
test/
├── support/harness.dart         base en memoria, repos, casos de uso y blocs
├── core/                        formato de dinero, fechas y teclado
├── data/
│   ├── datasources/             esquema en disco y migración v1 → v2
│   ├── models/                  mappers entidad ↔ fila
│   ├── repositories/            traducción de excepción a Failure, saldos
│   └── services/                hashing con bcrypt
├── domain/usecases/             una prueba por caso de uso
└── presentation/pages/          las pantallas reales
```

`support/harness.dart` no espeja nada de `lib`: es el andamio. Arma la base en
memoria, los repositorios, los casos de uso y los blocs, y se encarga de cerrar
todo. Sin él, veinte archivos repetirían el mismo cableado de quince líneas.

Los cuatro niveles siguen ahí, ahora ubicados por capa: unitarias puras en
`core` y `data/models`, esquema SQL en `data`, reglas de negocio en `domain`, y
pantallas reales en `presentation`.

Los tests de pantalla usan una ventana de 430x1240 en vez del lienzo de 800x600
que trae Flutter. No es cosmético: encontró cuatro desbordes reales que en un
teléfono se habrían visto rotos (los chips del historial, el título de sección,
el encabezado de página y la propia barra inferior).

Los tests de casos de uso y de widget no usan mocks: montan los repositorios
reales sobre SQLite en memoria. Sale menos código que escribir dobles y de paso
verifica que las reglas de dominio y las restricciones del esquema no se
contradigan.

> Nota sobre los tests de widget: no usan `pumpAndSettle` porque el indicador
> de carga anima sin fin y bcrypt corre en tiempo real, que el reloj falso de
> los tests no avanza. En su lugar esperan el estado concreto del bloc con
> `runAsync`.

## Qué falta si esto fuera a producción

- **Backend.** Hoy SQLite es la fuente de verdad. Con una API, entra un
  `RemoteDataSource` al lado del local y el repositorio decide entre los dos;
  `domain`, los casos de uso y los blocs no cambian.
- **Cifrado en reposo.** SQLCipher, o cifrar la base con la llave en
  `flutter_secure_storage`.
- **De dónde entra la plata.** Hoy cada cuenta nace con un cupo. Con
  consignaciones de verdad, el saldo se derivaría de una tabla de asientos y
  dejaría de tener un punto de partida inventado.
- **La tipografía.** El diseño usa Outfit; la app corre con la del sistema.
  Empaquetar el `.ttf` en `assets/` es el arreglo, sin agregar dependencias.
