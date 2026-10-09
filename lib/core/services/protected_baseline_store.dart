import '../router/exports.dart';

class ProtectedBaselineStore {
  ProtectedBaselineStore({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('tspm/protected_baseline');

  final MethodChannel _channel;

  Future<String?> read() => _channel.invokeMethod<String>('read');

  Future<void> replace({
    required String? expectedJson,
    required String nextJson,
  }) => _channel.invokeMethod<void>('replace', <String, Object?>{
    'expectedJson': expectedJson,
    'nextJson': nextJson,
  });
}
