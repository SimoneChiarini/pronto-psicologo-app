// Motivi di segnalazione — tenere allineato con src/report/report.constants.ts (backend)
const Map<String, String> kReportReasons = {
  'OFFENSIVE_LANGUAGE': 'Linguaggio offensivo o inappropriato',
  'HARASSMENT': 'Molestie o minacce',
  'UNPROFESSIONAL': 'Comportamento non professionale',
  'SPAM': 'Spam o pubblicità',
  'FAKE_PROFILE': 'Profilo falso o identità non veritiera',
  'PRIVACY': 'Violazione della privacy',
  'OFF_PLATFORM_PAYMENT': 'Richiesta di pagamenti fuori piattaforma',
  'OTHER': 'Altro',
};

const Map<String, String> kReportStatuses = {
  'OPEN': 'Aperta',
  'IN_REVIEW': 'In verifica',
  'RESOLVED': 'Risolta',
  'DISMISSED': 'Archiviata',
};
