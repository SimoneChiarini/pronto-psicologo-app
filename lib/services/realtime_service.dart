import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'auth_service.dart';

/// Evento ricevuto dal server in tempo reale.
/// - `message:new`  → {conversationId, messageId}
/// - `case:message` → {caseId, messageId}
/// - `notification` → {type, title, body, conversationId?, groupId?, caseId?, supervisionId?}
class RealtimeEvent {
  final String name;
  final Map<String, dynamic> data;
  const RealtimeEvent(this.name, this.data);
}

/// Connessione Socket.IO condivisa da tutta l'app (una sola per sessione).
/// Gli eventi portano solo id: le schermate ricaricano i dati via API.
class RealtimeService {
  RealtimeService._();
  static final RealtimeService instance = RealtimeService._();

  io.Socket? _socket;
  String? _token;
  final _events = StreamController<RealtimeEvent>.broadcast();
  // Stanze a cui siamo iscritti, ripristinate dopo ogni riconnessione
  final Set<String> _rooms = {};

  Stream<RealtimeEvent> get events => _events.stream;
  Stream<Map<String, dynamic>> get notifications =>
      events.where((e) => e.name == 'notification').map((e) => e.data);

  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect() async {
    final token = await AuthService().getToken();
    if (token == null) return;
    if (_socket != null && _token == token) return; // già connesso con questa sessione
    disconnect(clearRooms: false);
    _token = token;

    final socket = io.io(
      AuthService.baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableReconnection()
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(10000)
          .disableAutoConnect()
          .build(),
    );
    socket.onConnect((_) {
      for (final room in _rooms) {
        final i = room.indexOf(':');
        socket.emit('subscribe', {'type': room.substring(0, i), 'id': room.substring(i + 1)});
      }
    });
    socket.on('auth_error', (_) => disconnect());
    for (final name in ['message:new', 'case:message', 'notification']) {
      socket.on(name, (data) {
        if (data is Map) _events.add(RealtimeEvent(name, Map<String, dynamic>.from(data)));
      });
    }
    _socket = socket;
    socket.connect();
  }

  void disconnect({bool clearRooms = true}) {
    _socket?.dispose();
    _socket = null;
    _token = null;
    if (clearRooms) _rooms.clear();
  }

  /// type: 'conversation' | 'case'
  void subscribe(String type, String id) {
    _rooms.add('$type:$id');
    if (isConnected) _socket!.emit('subscribe', {'type': type, 'id': id});
  }

  void unsubscribe(String type, String id) {
    _rooms.remove('$type:$id');
    if (isConnected) _socket!.emit('unsubscribe', {'type': type, 'id': id});
  }

  /// Ascolta gli eventi di una stanza (es. nuovi messaggi in una chat aperta).
  StreamSubscription<RealtimeEvent> listenRoom(String type, String id, void Function() onChange) {
    final event = type == 'conversation' ? 'message:new' : 'case:message';
    final key = type == 'conversation' ? 'conversationId' : 'caseId';
    return events.where((e) => e.name == event && e.data[key] == id).listen((_) => onChange());
  }
}
