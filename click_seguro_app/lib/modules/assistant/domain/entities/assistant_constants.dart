abstract final class AssistantLimits {
  static const chatMessageMin = 5;
  static const chatMessageMax = 1000;
  static const contextTurnMax = 20;
  static const contextTextMin = 1;
  static const contextTextMax = 2000;
  static const analysisTextMin = 10;
  static const analysisTextMax = 5000;
  static const sourceMin = 1;
  static const sourceMax = 50;
  static const imageBytesMax = 5 * 1024 * 1024;
  static const historyPageMin = 1;
  static const historyPageSize = 20;
  static const historyLimitMax = 100;
}

abstract final class AssistantImageErrorCodes {
  static const invalidFormat = 'INVALID_IMAGE_FORMAT';
}

abstract final class AssistantAnalysisSources {
  static const whatsapp = 'WHATSAPP';
  static const sms = 'SMS';
  static const email = 'EMAIL';
  static const other = 'OTHER';
}

enum AssistantAnalysisMode { text, image }
