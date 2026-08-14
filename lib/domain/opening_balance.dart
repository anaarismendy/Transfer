/// Cupo con el que nace una cuenta.
///
/// Simplificacion consciente: no existe el concepto de consignacion, asi que la
/// plata inicial la pone la plataforma. Si algun dia entra dinero de verdad,
/// esta constante se reemplaza por un movimiento de ingreso y el saldo deja de
/// tener un punto de partida inventado.
const openingBalanceInCents = 250000000;
