import 'package:flutter/foundation.dart';
import '../client/media_client.dart';
import '../utils/app_logger.dart';

class MediaClientProvider extends ChangeNotifier {
  MediaClient? _client;

  MediaClient? get client => _client;

  void setClient(MediaClient client) {
    _client = client;
    appLogger.d('MediaClientProvider: Client set');
    notifyListeners();
  }

  void updateToken(String newToken) {
    if (_client != null) {
      _client!.updateToken(newToken);
      appLogger.d('MediaClientProvider: Token updated');
      notifyListeners();
    } else {
      appLogger.w('MediaClientProvider: Cannot update token - no client set');
    }
  }

  void clearClient() {
    _client = null;
    appLogger.d('MediaClientProvider: Client cleared');
    notifyListeners();
  }
}
