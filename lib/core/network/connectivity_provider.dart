import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityStreamProvider =
    StreamProvider<ConnectivityResult>((ref) {
  final connectivity = Connectivity();
  return connectivity.onConnectivityChanged.map((list) => list.first);
});

final isOnlineProvider = Provider<bool>((ref) {
  final asyncResult = ref.watch(connectivityStreamProvider);
  return asyncResult.maybeWhen(
    data: (result) => result != ConnectivityResult.none,
    orElse: () => true,
  );
});
