/// Motivo pelo qual um campo foi recusado na validação local (RN-001).
enum FieldError {
  required,
  nameLength,
  emailInvalid,
  passwordRules,
  passwordMismatch,
  codeLength,
}
