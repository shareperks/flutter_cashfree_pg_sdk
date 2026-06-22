/// One [SessionId] per cold start of the app. Used to group events that
/// happened in the same launch (foreground -> background -> foreground is
/// still the same session unless you decide otherwise).
class SessionId {
  SessionId._();

  static final String value = DateTime.now().millisecondsSinceEpoch.toString();
}
