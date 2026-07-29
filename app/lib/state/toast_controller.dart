import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../widgets/fc_toast.dart';

/// The toast queue. Port of `src/context/ToastContext.jsx`, including its
/// 3.5 second auto-dismiss.
class ToastController extends Notifier<List<FcToastData>> {
  static const Duration visibleFor = Duration(milliseconds: 3500);

  final Map<String, Timer> _timers = <String, Timer>{};

  @override
  List<FcToastData> build() {
    ref.onDispose(() {
      for (final Timer timer in _timers.values) {
        timer.cancel();
      }
      _timers.clear();
    });
    return const <FcToastData>[];
  }

  String show(String message, {FcToastType type = FcToastType.info}) {
    final String id = const Uuid().v4();
    state = <FcToastData>[
      ...state,
      FcToastData(id: id, message: message, type: type),
    ];
    _timers[id] = Timer(visibleFor, () => dismiss(id));
    return id;
  }

  void dismiss(String id) {
    _timers.remove(id)?.cancel();
    state = state.where((FcToastData t) => t.id != id).toList();
  }
}

final NotifierProvider<ToastController, List<FcToastData>>
toastControllerProvider =
    NotifierProvider<ToastController, List<FcToastData>>(ToastController.new);
