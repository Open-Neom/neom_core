enum ValidationError {
  /// No hay error, la validación fue exitosa.
  none,

  /// Errores de Email
  pleaseEnterEmail,
  invalidEmailFormat,

  /// Errores de Nombre Completo
  pleaseEnterFullName,
  invalidName,
  // Para los siguientes, usamos nombres más genéricos que puedes reutilizar
  nameTooShort,
  nameTooLong,

  /// Errores de Nombre de Usuario
  pleaseEnterUsername,
  invalidUsername,
  usernameTooShort,
  usernameTooLong,

  /// Errores de Contraseña
  pleaseEnterPassword,
  passwordTooShort,
  passwordTooLong,
  passwordsNotMatch,
}
