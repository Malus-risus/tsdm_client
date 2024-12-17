part of 'auto_notification_cubit.dart';

/// Base class of state.
@MappableClass()
sealed class AutoNoticeState with AutoNoticeStateMappable {
  /// Constructor.
  const AutoNoticeState();
}

/// Initial state.
@MappableClass()
final class AutoNoticeStateStopped extends AutoNoticeState
    with AutoNoticeStateStoppedMappable {
  /// Constructor.
  const AutoNoticeStateStopped();
}

/// Ticking time to do refresh notice.
///
/// This state indicates a waiting for next fetch state, may be triggered
/// frequently.
@MappableClass()
final class AutoNoticeStateTicking extends AutoNoticeState
    with AutoNoticeStateTickingMappable {
  /// Constructor.
  const AutoNoticeStateTicking({
    required this.total,
    required this.remain,
  });

  /// Total scheduled time.
  final Duration total;

  /// Remaining time till next fetch.
  final Duration remain;
}

/// Pending latest notice state.
///
/// Fetching notice from server, checking for unread new notice, updating
/// notice state in cache, and more.
@MappableClass()
final class AutoNoticeStatePending extends AutoNoticeState
    with AutoNoticeStatePendingMappable {
  /// Constructor.
  const AutoNoticeStatePending();
}
