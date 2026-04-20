# Pronto Psicologo Flutter Frontend

Questo è un progetto starter Flutter per testare le API di `ProntoPsicologo`.

## Struttura

- `lib/main.dart` - entry point
- `lib/pages/login_page.dart` - pagina di login
- `lib/pages/register_page.dart` - pagina di registrazione
- `lib/pages/home_page.dart` - pagina profilo
- `lib/services/auth_service.dart` - chiamate HTTP e token storage

## Installazione

1. Installa Flutter sul tuo sistema.
2. Apri una shell nella cartella `flutter_app`.
3. Esegui `flutter pub get`.
4. Avvia l'app con `flutter run`.

## Note

- L'URL di default per le API è `http://10.0.2.2:3000`.
- Se usi un dispositivo reale o un emulator diverso, aggiorna `baseUrl` in `lib/services/auth_service.dart`.
