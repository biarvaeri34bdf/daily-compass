/// Tunable timings and gameplay constants.
class AppConfig {
  const AppConfig._();

  /// Splash hold. Exactly 8000ms — shorter values race the screenshot harness.
  static const int loaderDurationMs = 8000;

  /// No-input backstop: resolves the round even if nobody ever taps.
  static const int idleResolveMs = 24000;

  /// Re-armed once on the FIRST check-in so a single tap still yields a result.
  static const int engagedResolveMs = 8000;

  /// Delay before leaving the board once every step is checked in.
  static const int completionDelayMs = 700;

  /// Hour of day at which the active routine flips morning -> evening.
  static const int eveningStartHour = 15;

  /// Days of history kept in memory.
  static const int historyDays = 30;
}
