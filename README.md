# Transfer — Prueba técnica Flutter

[![CI](https://github.com/anaarismendy/Transfer/actions/workflows/ci.yml/badge.svg)](https://github.com/anaarismendy/Transfer/actions/workflows/ci.yml)

Esta es mi solución a la prueba técnica de desarrollador Flutter. Es una app para transferir dinero entre usuarios, con todo guardado en el dispositivo.

### Visualización de la App
<img width="373" height="835" alt="image" src="https://github.com/user-attachments/assets/abc7009b-482c-483b-a6a8-9e23702b5668" />
<img width="373" height="831" alt="image" src="https://github.com/user-attachments/assets/877e0148-b911-4dc4-96b4-a712cdb786ea" 
<img width="372" height="833" alt="image" src="https://github.com/user-attachments/assets/16786b1c-25ce-47be-8c37-ce108f8d6af3" />
<img width="372" height="830" alt="image" src="https://github.com/user-attachments/assets/31e5a40b-55ca-4d29-bf4b-c3a7a408d453" />
<img width="370" height="832" alt="image" src="https://github.com/user-attachments/assets/85827240-1733-43f0-8e41-5bc7e60c8c38" />
<img width="376" height="833" alt="image" src="https://github.com/user-attachments/assets/d4327ab0-4768-421a-959b-73e1b5727ffd" />
<img width="371" height="832" alt="image" src="https://github.com/user-attachments/assets/5120d7de-00df-4982-9997-e937bb080a6f" />
<img width="372" height="829" alt="image" src="https://github.com/user-attachments/assets/dc4bd7dd-7e2c-4d7f-ba6e-d758db086b85" />
<img width="367" height="832" alt="image" src="https://github.com/user-attachments/assets/2be25c6f-23dd-4429-b2f1-b2ae8ea7a5d2" />


## Qué hace la app

La app tiene tres partes principales:

**Inicio de sesión.** Entras con correo y contraseña. La contraseña no se guarda en ningún lado: lo que se guarda es un hash de bcrypt, que no se puede revertir. Cuando entras, se hashea lo que escribiste y se comparan los dos hashes, nunca las contraseñas. Si cierras la app y la vuelves a abrir, no te vuelve a pedir el login, porque la sesión queda guardada.

**Contactos.** Puedes crear, ver, editar y eliminar usuarios. No te deja repetir un correo, ni eliminar a alguien que ya tenga transferencias hechas, ni eliminar al usuario que tiene la sesión abierta en ese momento.

**Transferencias.** El flujo es de tres pasos: eliges a quién le vas a transferir, cuánto (con un teclado numérico propio) y confirmas con una nota opcional. Al final te muestra un comprobante con todos los datos. Internamente, cada transferencia mueve la plata de las dos cuentas al mismo tiempo — si algo falla o no hay saldo suficiente, no se mueve nada, para no dejar la información a medias.

Sobre el saldo: cada cuenta nace con un cupo de $2.500.000 que pone la plataforma. De ahí en adelante los saldos solo se mueven con transferencias.

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

### Cómo manejo los errores

Nada lanza excepciones hacia arriba. Los métodos devuelven un `Result<T>`, que es `Ok` o `Err`, y en el `Err` viene un `Failure` con su mensaje. Los dos son clases selladas, así que cuando hago un `switch` el compilador me obliga a cubrir todos los casos: si mañana agrego un tipo de error nuevo, el código deja de compilar en cada lugar donde tocaba atenderlo.

La única capa que atrapa excepciones de SQLite es `data`, y su trabajo es traducirlas. Un correo repetido, por ejemplo, sube como `DuplicateEmailFailure`, y la pantalla sabe qué mostrar sin tener idea de que existe una base de datos debajo.

## Qué se puede hacer con la app

- Iniciar sesión y mantener la sesión activa aunque cierres la app.
- Crear, editar, eliminar y buscar contactos.
- Hacer transferencias entre contactos, con validación de saldo.
- Ver el historial de tus movimientos, con filtros de enviado y recibido.
- Ver un comprobante después de cada transferencia.
- Cerrar sesión desde el perfil.

## Pruebas

Escribí pruebas para casi todo: la lógica de negocio, la base de datos, los mappers, los repositorios y también pruebas de las pantallas (que el usuario pueda hacer login, crear un contacto, hacer una transferencia, etc.). En total quedaron 105 pruebas.

La carpeta `test/` tiene la misma estructura que `lib/`, así que cada cosa se prueba donde vive: `test/domain/usecases/login_test.dart` prueba `lib/domain/usecases/login.dart`, y así.


## Integración continua (CI)

Configuré un pipeline en GitHub Actions que corre en cada push a `main` y en cada pull request. Hace tres cosas: revisa el formato, corre `flutter analyze` y corre las 105 pruebas, siempre con la misma versión de Flutter para que el resultado sea reproducible.


## Cómo instalar y correr el proyecto

### Lo que necesitas tener instalado antes

1. **Flutter** (la última versión estable). Si no lo tienes, lo instalas siguiendo la guía oficial: https://docs.flutter.dev/get-started/install
2. Un editor de código, recomiendo **VS Code** o **Android Studio**.
3. Un emulador de Android configurado, o un celular físico conectado con la depuración USB activada. También corre en Windows y Linux como app de escritorio. 

Para confirmar que todo está bien instalado, corre en la terminal:

```bash
flutter doctor
```

Eso te dice si falta algo por configurar.

### Pasos para correr la app

1. Clona el repositorio:
```bash
git clone https://github.com/anaarismendy/Transfer.git
cd Transfer
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

5. Cuando te pida iniciar sesión, usa las credenciales de prueba que dejé más arriba (admin@test.com / Admin123). Si quieres crear otro usuario, se hace desde la pestaña de Contactos ya estando dentro.

### Cómo correr las pruebas

Si quieres correr todas las pruebas que escribí, es un solo comando:

```bash
flutter test
```


