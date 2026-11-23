/// Situação de um módulo no painel (FR-004, CB-012). Derivada das lições; o
/// serviço não manda pronta (R2 de specs/015-painel-atividades). [retry]:
/// todas respondidas, mas com acertos abaixo da metade (specs/025).
enum ModuleStatus { notStarted, inProgress, completed, retry, unavailable }
