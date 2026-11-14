import 'package:cloud_functions/cloud_functions.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

class CheckoutSession {
  const CheckoutSession({
    required this.orderId,
    required this.gatewayOrderId,
    required this.amount,
    required this.keyId,
  });

  factory CheckoutSession.fromMap(Map data) => CheckoutSession(
    orderId: data['orderId'] as String,
    gatewayOrderId: data['razorpayOrderId'] as String,
    amount: (data['amountPaise'] as num).toInt(),
    keyId: data['keyId'] as String,
  );

  final String orderId;
  final String gatewayOrderId;
  final int amount;
  final String keyId;
}

class CheckoutRepository {
  CheckoutRepository(this._functions, this._storage);
  final FirebaseFunctions _functions;
  final Box _storage;

  String? pendingOrder(String uid) =>
      _storage.get('checkout_order_$uid') as String?;

  bool cartMatches(String uid, String fingerprint) =>
      _storage.get('checkout_cart_$uid') == fingerprint;

  Future<CheckoutSession> start(
    String uid,
    Map<String, dynamic> order,
    String cartFingerprint,
  ) async {
    final key = 'checkout_request_$uid';
    final requestId = _storage.get(key) as String? ?? const Uuid().v4();
    await _storage.put(key, requestId);
    late final Map data;
    try {
      data = await _call('createRazorpayOrder', {
        'requestId': requestId,
        'order': order,
      });
    } on FirebaseFunctionsException catch (error) {
      if (pendingOrder(uid) == null &&
          ['failed-precondition', 'invalid-argument'].contains(error.code)) {
        await _storage.delete(key);
      }
      rethrow;
    }
    final session = CheckoutSession.fromMap(data);
    await _storage.putAll({
      'checkout_order_$uid': session.orderId,
      'checkout_cart_$uid': cartFingerprint,
    });
    return session;
  }

  Future<String> verify(
    String orderId,
    String? paymentId,
    String? gatewayOrderId,
    String? signature,
  ) async {
    if (paymentId == null || gatewayOrderId == null || signature == null) {
      return status(orderId);
    }
    final result = await _call('verifyAndConfirmOrder', {
      'orderId': orderId,
      'razorpayPaymentId': paymentId,
      'razorpayOrderId': gatewayOrderId,
      'razorpaySignature': signature,
    });
    return result['status'] as String;
  }

  Future<String> status(String orderId) async =>
      (await _call('getCheckoutStatus', {'orderId': orderId}))['status']
          as String;

  Future<String> detach(String orderId) async =>
      (await _call('detachCheckout', {'orderId': orderId}))['status'] as String;

  Future<String> placeDirectOrder(
    String uid,
    Map<String, dynamic> order,
  ) async {
    final key = 'direct_order_request_$uid';
    final id = _storage.get(key) as String? ?? const Uuid().v4();
    await _storage.put(key, id);
    late final Map result;
    try {
      result = await _call('createOrder', {'order': order, 'requestId': id});
    } on FirebaseFunctionsException catch (error) {
      if (['failed-precondition', 'invalid-argument'].contains(error.code)) {
        await _storage.delete(key);
      }
      rethrow;
    }
    final orderId = result['orderId'] as String;
    await _storage.delete(key);
    return orderId;
  }

  Future<void> finish(String uid) => _storage.deleteAll([
    'checkout_order_$uid',
    'checkout_request_$uid',
    'checkout_cart_$uid',
  ]);

  Future<Map> _call(String name, Map<String, dynamic> payload) async =>
      (await _functions.httpsCallable(name).call(payload)).data as Map;
}
