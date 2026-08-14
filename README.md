# Transfer — Prueba técnica Flutter

[![CI](https://github.com/anaarismendy/prueba-tecnica-flutter/actions/workflows/ci.yml/badge.svg)](https://github.com/anaarismendy/prueba-tecnica-flutter/actions/workflows/ci.yml)

Esta es mi solución a la prueba técnica de desarrollador Flutter. Es una app para transferir dinero entre usuarios, con todo guardado en el dispositivo (no necesita internet ni un backend). La probé en Android y en Windows.

Le puse "Transfer" de nombre porque, pues, de eso se trata: transferencias entre contactos.

## Qué hace la app

La app tiene tres partes principales:

**Inicio de sesión.** Entras con correo y contraseña. La contraseña no se guarda en ningún lado: lo que se guarda es un hash de bcrypt, que no se puede revertir. Cuando entras, se hashea lo que escribiste y se comparan los dos hashes, nunca las contraseñas. Si cierras la app y la vuelves a abrir, no te vuelve a pedir el login, porque la sesión queda guardada.

Un detalle que me pareció importante: si el correo no existe o la contraseña está mala, el mensaje de error es el mismo. Si fueran distintos, cualquiera podría ir probando correos para averiguar quién está registrado.

**Contactos.** Puedes crear, ver, editar y eliminar usuarios. No te deja repetir un correo, ni eliminar a alguien que ya tenga transferencias hechas, ni eliminar al usuario que tiene la sesión abierta en ese momento (por obvias razones).

**Transferencias.** El flujo es de tres pasos: eliges a quién le vas a transferir, cuánto (con un teclado numérico propio) y confirmas con una nota opcional. Al final te muestra un comprobante con todos los datos. Internamente, cada transferencia mueve la plata de las dos cuentas al mismo tiempo — si algo falla o no hay saldo suficiente, no se mueve nada, para no dejar la información a medias.

Sobre el saldo: como no hay forma de consignar plata desde afuera, cada cuenta nace con un cupo de $2.500.000 que pone la plataforma. De ahí en adelante los saldos solo se mueven con transferencias.

### Recorrido rápido de la app

Cuando abres la app por primera vez, si no hay usuarios en la base, se crea automáticamente uno de prueba. Luego te manda al login. Si ya tenías sesión abierta, te lleva directo a la pantalla principal, que tiene 4 pestañas y un botón central para transferir:

- **Inicio:** tu saldo, accesos rápidos, contactos frecuentes y tus últimos 3 movimientos.
- **Contactos:** el CRUD de usuarios.
- **Historial:** los movimientos en los que apareces, con filtros de enviado y recibido.
- **Perfil:** tus datos y la opción de cerrar sesión.
- **Transferir:** el flujo de los tres pasos que expliqué arriba.

### Usuario de prueba

Para que puedas entrar a probar la app sin crear un usuario desde cero, dejé uno precargado:

| Correo | Contraseña |
|---|---|
| admin@test.com | Admin123 |

Este usuario solo se crea si la base de datos está vacía, así que si ya tienes usuarios creados no se va a duplicar ni nada raro.

## Cómo está armada por dentro

Usé **Clean Architecture**, que básicamente significa que separé el proyecto en capas que no se mezclan entre sí:

- **domain:** son las reglas del negocio puras — por ejemplo, "no puedes transferirte plata a ti mismo" o "el monto tiene que ser mayor a cero". Esta capa no sabe nada de Flutter ni de bases de datos, solo de reglas.
- **data:** es la que habla con la base de datos (SQLite) y traduce lo que pasa ahí a algo que la capa de dominio entiende.
- **presentation:** son las pantallas y todo lo visual, junto con Flutter Bloc que maneja el estado de cada una.
- **core:** cosas que usan las tres capas de arriba, como el manejo de errores, el formato de moneda y los colores del tema.

La idea de tener todo separado así es que si mañana en vez de guardar todo en el celular quisiera conectar la app a un servidor, solo tendría que cambiar la capa de `data` — el resto del código ni se entera.

Para el manejo de estado usé **Flutter Bloc**, y para inyectar las dependencias usé `get_it` con `injectable`, que arma automáticamente todas las conexiones entre las capas cuando arranca la app.

En carpetas se ve así:

```
lib/
├── core/            Result, Failure, formato de dinero y tema
├── domain/          entidades, contratos, validaciones y casos de uso
├── data/            SQLite, mappers, repositorios y bcrypt
└── presentation/    blocs, pantallas y componentes
```

La regla que traté de no romper es que `domain` no importa nada de `data` ni de `presentation`. Los contratos de los repositorios (las interfaces) viven en `domain` y las implementaciones en `data`, así que la dependencia apunta hacia las reglas y no al revés. Eso es lo que hace posible cambiar de base de datos sin tocar la lógica, y de hecho ya me pasó: empecé con Hive, me cambié a SQLite y `domain` no cambió ni una línea.

### Cómo manejo los errores

Nada lanza excepciones hacia arriba. Los métodos devuelven un `Result<T>`, que es `Ok` o `Err`, y en el `Err` viene un `Failure` con su mensaje. Los dos son clases selladas, así que cuando hago un `switch` el compilador me obliga a cubrir todos los casos: si mañana agrego un tipo de error nuevo, el código deja de compilar en cada lugar donde tocaba atenderlo.

La única capa que atrapa excepciones de SQLite es `data`, y su trabajo es traducirlas. Un correo repetido, por ejemplo, sube como `DuplicateEmailFailure`, y la pantalla sabe qué mostrar sin tener idea de que existe una base de datos debajo.

### La base de datos

Todo se guarda localmente con SQLite. Algunas decisiones que tomé ahí:

- El dinero se guarda en centavos y como número entero, nunca como decimal, para no tener problemas de redondeo (eso es una práctica estándar cuando se maneja plata en cualquier sistema).
- Los correos son únicos sin importar mayúsculas o minúsculas, para que `Ana@correo.com` y `ana@correo.com` cuenten como la misma persona.
- Cada transferencia queda protegida con una transacción: si algo sale mal a mitad de camino, todo se revierte y no queda ningún dato inconsistente.

Buena parte de esas reglas están puestas en el esquema y no solo en el código:

```sql
email            TEXT NOT NULL COLLATE NOCASE UNIQUE
balance_in_cents INTEGER NOT NULL DEFAULT 0
  CONSTRAINT balance_not_negative CHECK (balance_in_cents >= 0)
amount_in_cents  INTEGER NOT NULL CHECK (amount_in_cents > 0)
source_user_id   TEXT NOT NULL REFERENCES users(id)
CHECK (source_user_id <> destination_user_id)
```

Las valido igual en los casos de uso, pero por otro motivo: para dar un mensaje que sirva. El `CHECK` rechaza un monto en cero y devuelve un error genérico de base de datos; el caso de uso devuelve "El valor debe ser mayor a cero". O sea, el dominio da el buen mensaje y la base da la garantía de que nadie se la salta.

Al `CHECK` del saldo le puse nombre a propósito. SQLite incluye el nombre de la restricción en el mensaje de error, y así puedo distinguir un "no le alcanza el saldo" de cualquier otro problema de base sin ponerme a adivinar leyendo texto.

### Migraciones

La base va en la versión 2. Si alguien abre la app con una base de la versión anterior, `onUpgrade` agrega la columna del saldo y lo reconstruye a partir de las transferencias que ya estaban guardadas: el cupo, más lo que recibió, menos lo que envió. Si no lo hiciera, una base vieja quedaría con todos los usuarios en el mismo saldo y contradiciendo su propio historial.

Hay una prueba que crea una base con el esquema viejo, le mete usuarios y una transferencia, y la abre con la app de hoy. Es el único camino que corre sobre datos que ya existen, así que me pareció el que más valía la pena asegurar.

### Estilo visual

Le puse un estilo neumórfico (superficies con relieve, como si estuvieran talladas) en tonos lavanda y azul. Traté de que se viera pulido y consistente en toda la app, no solo en una pantalla suelta.

## Qué se puede hacer con la app (resumen funcional)

- Iniciar sesión y mantener la sesión activa aunque cierres la app.
- Crear, editar, eliminar y buscar contactos.
- Hacer transferencias entre contactos, con validación de saldo.
- Ver el historial de tus movimientos, con filtros de enviado y recibido.
- Ver un comprobante después de cada transferencia.
- Cerrar sesión desde el perfil.

## Qué pedía la prueba y dónde quedó

Para que no toque buscar, esto es lo que pedía el enunciado y dónde está cada cosa:

| Lo que pedían | Dónde quedó |
|---|---|
| Flutter última versión estable | 3.44.6, la misma que fija el CI |
| Flutter Bloc | `AuthBloc`, `UsersBloc` y `TransfersBloc` |
| Clean Architecture | las cuatro capas de arriba |
| Inyección de dependencias | `get_it` con `injectable` |
| Manejo adecuado de errores | `Result<T>` y `Failure` sellados |
| Almacenamiento local | SQLite con `sqflite` |
| Patrones de diseño | Repository, Use Case, Service Locator, Observer, Result y Adapter en los mappers |
| Login con validaciones | `LoginPage` y el caso de uso `Login` |
| CRUD de usuarios | pestaña de Contactos y los casos de uso de usuario |
| Transferencias con comprobante | el flujo de tres pasos y `ReceiptPage` |

## Pruebas

Escribí pruebas para casi todo: la lógica de negocio, la base de datos, los mappers, los repositorios y también pruebas de las pantallas (que el usuario pueda hacer login, crear un contacto, hacer una transferencia, etc.). En total quedaron 105 pruebas.

La carpeta `test/` tiene la misma estructura que `lib/`, así que cada cosa se prueba donde vive: `test/domain/usecases/login_test.dart` prueba `lib/domain/usecases/login.dart`, y así.

Decidí no usar mocks — es decir, no simular la base de datos — sino correr las pruebas contra una base SQLite real pero en memoria. Esto me daba más confianza de que las reglas realmente funcionaban, no solo que el código "llamaba a la función correcta".

## Integración continua (CI)

Configuré un pipeline en GitHub Actions que corre en cada push a `main` y en cada pull request. Hace tres cosas: revisa el formato, corre `flutter analyze` y corre las 105 pruebas, siempre con la misma versión de Flutter para que el resultado sea reproducible.

Las tres son barrera y no aviso: si alguna falla, el build queda rojo y el badge de arriba también. Así, si algo se rompe se nota de inmediato y no toca esperar a probarlo a mano.

## Cómo instalar y correr el proyecto

### Lo que necesitas tener instalado antes

1. **Flutter** (la última versión estable). Si no lo tienes, lo instalas siguiendo la guía oficial: https://docs.flutter.dev/get-started/install
2. Un editor de código, recomiendo **VS Code** o **Android Studio**.
3. Un emulador de Android configurado, o un celular físico conectado con la depuración USB activada. También corre en Windows y Linux como app de escritorio. (Para iOS necesitas una Mac.)

Para confirmar que todo está bien instalado, corre en la terminal:

```bash
flutter doctor
```

Eso te dice si falta algo por configurar.

### Pasos para correr la app

1. Clona el repositorio:
```bash
git clone https://github.com/anaarismendy/prueba-tecnica-flutter.git
cd prueba-tecnica-flutter
```

2. Instala las dependencias del proyecto:
```bash
flutter pub get
```

3. El proyecto usa generación de código para las entidades y para la inyección de dependencias, pero ese código ya está versionado, así que puedes saltarte este paso. Solo hace falta si modificas una entidad o algo de la inyección:
```bash
dart run build_runner build --delete-conflicting-outputs
```

4. Conecta un emulador o un celular, y corre la app:
```bash
flutter run
```

5. Cuando te pida iniciar sesión, usa las credenciales de prueba que dejé más arriba (admin@test.com / Admin123). Si quieres crear otro usuario, se hace desde la pestaña de Contactos ya estando dentro. El botón de "crear cuenta nueva" del login no hace nada todavía: lo dejé porque venía en el diseño, pero el registro abierto no estaba en el alcance de la prueba.

### Cómo correr las pruebas

Si quieres correr todas las pruebas que escribí, es un solo comando:

```bash
flutter test
```

## Cosas que sé que le faltan para ser un producto real

Como esto es una prueba técnica y no una app en producción, hay cosas que dejé pendientes a propósito porque se salían del alcance:

- No tiene backend — hoy todo vive únicamente en el celular. Está armada de tal forma que conectar un servidor después no debería requerir tocar la lógica de negocio.
- La base de datos no está encriptada en el dispositivo (aunque las contraseñas sí lo están).
- El historial trae todos los movimientos de una — con muchísimos movimientos habría que paginarlo.
- El saldo inicial de cada cuenta es un cupo fijo que pone la plataforma. Para que fuera un saldo de verdad tendría que existir el concepto de consignación, y ahí lo correcto sería derivar el saldo de una tabla de movimientos contables en vez de guardarlo en una columna.
- Del diseño original quedaron afuera el teléfono y el número de cuenta de cada contacto (muestro el correo en su lugar) y los seis colores que se podían elegir para el avatar. Los tres necesitan columnas nuevas; el color del avatar por ahora lo saco del id, así que al menos cada persona siempre se ve igual.
- Algunos detalles visuales del diseño original (como una tipografía específica) los dejé con la fuente por defecto del sistema.

## Nota final

Traté de que cada decisión técnica que tomé tuviera una razón detrás y no fuera solo "porque sí" — desde por qué separé las capas de esa forma, hasta por qué el dinero se guarda en centavos y no en decimales. Cualquier duda sobre alguna decisión específica, con gusto la explico a detalle.