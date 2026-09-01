import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_state.dart';

final appStateProvider = ChangeNotifierProvider<AppState>((ref) {
  final state = AppState();
  state.init();
  return state;
});

final currentTabProvider = StateProvider<int>((ref) => 0);
