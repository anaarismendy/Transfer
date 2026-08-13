# TRANSFER — consola de transferencias

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
│   ├── format.dart              pesos y fechas, sin dependencias
│   ├── theme.dart               paleta y componentes
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
    └── widgets/                 componentes compartidos
```

La regla que sostiene todo: `domain` no importa nada de `data` ni de
`presentation`, y solo `data` sabe que SQLite existe.

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

78 pruebas en cuatro niveles:

- **Unitarias puras** — mappers, formato de dinero y fechas, hashing
- **Esquema SQL** — `UNIQUE`, ambos `CHECK`, llaves foráneas y orden del
  historial, contra SQLite real en memoria
- **Casos de uso** — las reglas de negocio contra la base real
- **Widget** — los tres flujos completos sobre las pantallas reales

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
- **Saldos.** El enunciado solo pide registrar el movimiento, así que no hay
  validación de fondos suficientes.
