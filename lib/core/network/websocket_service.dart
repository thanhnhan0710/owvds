import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

// Import html chỉ khi chạy trên Web
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  bool _isConnected = false;
  Timer? _reconnectTimer;

  final List<Function(String)> _listeners = [];

  // HÀM TỰ ĐỘNG LẤY ĐỊA CHỈ WEBSOCKET (ĐÃ ĐƯỢC FIX CỔNG)
  String get _wsUrl {
    if (kIsWeb) {
      // 1. Lấy host/domain hiện tại của trình duyệt (VD: localhost, 192.168.0.x, mydomain.com)
      final host = html.window.location.hostname ?? '127.0.0.1';

      // 2. Xác định giao thức bảo mật
      final isSecure = html.window.location.protocol.contains('https');
      final protocol = isSecure ? 'wss' : 'ws';

      // 3. [QUAN TRỌNG NHẤT]: Ép cứng gọi về cổng 8000 của Backend và Endpoint /ws/updates
      // Bỏ qua html.window.location.port vì đó là cổng của Flutter Web
      return '$protocol://$host:8000/ws/updates';
    }

    // Nếu build ra Mobile/Desktop (APK, iOS, Windows):
    // Đổi 127.0.0.1 thành IP LAN (VD: 192.168.1.5) hoặc 10.0.2.2 (nếu dùng máy ảo Android)
    return 'ws://127.0.0.1:8000/ws/updates';
  }

  void connect() {
    if (_isConnected) return;

    final url = _wsUrl;

    try {
      debugPrint("⏳ [WebSocket] Đang thử kết nối tới: $url...");
      _channel = WebSocketChannel.connect(Uri.parse(url));

      _channel!.stream.listen(
        (message) {
          _isConnected = true;
          debugPrint("✅ [WebSocket] Nhận tín hiệu từ Server: $message");
          for (var listener in _listeners) {
            listener(message);
          }
        },
        onDone: () {
          debugPrint("⚠️ [WebSocket] Đã bị đóng kết nối bởi server.");
          _isConnected = false;
          _scheduleReconnect();
        },
        onError: (error) {
          debugPrint("❌ [WebSocket] Bị lỗi: $error");
          _isConnected = false;
          _scheduleReconnect();
        },
        cancelOnError: true,
      );

      _isConnected = true;
      _reconnectTimer?.cancel();
      debugPrint("🟢 [WebSocket] Đã thiết lập luồng kết nối thành công.");
    } catch (e) {
      debugPrint("❌ [WebSocket] Lỗi khi khởi tạo kết nối: $e");
      _isConnected = false;
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (!_isConnected) {
        debugPrint("🔄 [WebSocket] Đang thử kết nối lại...");
        connect();
      }
    });
  }

  void addListener(Function(String) listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }

  void removeListener(Function(String) listener) {
    _listeners.remove(listener);
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    debugPrint("🔴 [WebSocket] Đã ngắt kết nối thủ công.");
  }
}
