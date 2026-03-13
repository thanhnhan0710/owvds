// lib/features/production/notifications/presentation/notification_cubit.dart

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/notification_service.dart';
import '../domain/notification_model.dart';

// ── State ─────────────────────────────────────────────────────────────────────
class NotificationState {
  final List<AppNotification> notifications;
  final int unreadCount;

  const NotificationState({
    required this.notifications,
    required this.unreadCount,
  });

  factory NotificationState.empty() =>
      const NotificationState(notifications: [], unreadCount: 0);

  NotificationState copyWith({
    List<AppNotification>? notifications,
    int? unreadCount,
  }) => NotificationState(
    notifications: notifications ?? this.notifications,
    unreadCount: unreadCount ?? this.unreadCount,
  );
}

// ── Cubit ─────────────────────────────────────────────────────────────────────
class NotificationCubit extends Cubit<NotificationState> {
  StreamSubscription<AppNotification>? _sub;
  static const int _maxKeep = 60;

  NotificationCubit() : super(NotificationState.empty()) {
    _sub = NotificationService.instance.stream.listen(_onNew);
  }

  void _onNew(AppNotification n) {
    final list = [n, ...state.notifications];
    if (list.length > _maxKeep) list.removeRange(_maxKeep, list.length);
    emit(
      state.copyWith(notifications: list, unreadCount: state.unreadCount + 1),
    );
  }

  void markAllRead() {
    for (final n in state.notifications) {
      n.isRead = true;
    }
    emit(
      state.copyWith(
        notifications: List.from(state.notifications),
        unreadCount: 0,
      ),
    );
  }

  void markRead(String id) {
    final list = state.notifications.map((n) {
      if (n.id == id) n.isRead = true;
      return n;
    }).toList();
    emit(
      state.copyWith(
        notifications: list,
        unreadCount: list.where((n) => !n.isRead).length,
      ),
    );
  }

  void remove(String id) {
    final list = state.notifications.where((n) => n.id != id).toList();
    emit(
      state.copyWith(
        notifications: list,
        unreadCount: list.where((n) => !n.isRead).length,
      ),
    );
  }

  void clearAll() => emit(NotificationState.empty());

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
