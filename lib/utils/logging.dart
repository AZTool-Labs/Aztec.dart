import 'dart:developer' as developer;

/// Log level for the logger
enum LogLevel {
  /// Debug level for detailed information
  debug,

  /// Info level for general information
  info,

  /// Warning level for potential issues
  warn,

  /// Error level for errors
  error,

  /// Fatal level for critical errors
  fatal,
}

/// Logger class for logging messages
class Logger {
  /// Tag for the logger
  final String tag;

  /// Minimum log level to display
  static LogLevel _minLevel = LogLevel.info;

  /// Constructor for Logger
  Logger(this.tag);

  /// Set the minimum log level
  static void setMinLevel(LogLevel level) {
    _minLevel = level;
  }

  /// Log a debug message
  void debug(String message) {
    _log(LogLevel.debug, message);
  }

  /// Log an info message
  void info(String message) {
    _log(LogLevel.info, message);
  }

  /// Log a warning message
  void warn(String message) {
    _log(LogLevel.warn, message);
  }

  /// Log an error message
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.error, message, error, stackTrace);
  }

  /// Log a fatal message
  void fatal(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.fatal, message, error, stackTrace);
  }

  /// Log a message with a specific level
  void _log(LogLevel level, String message,
      [Object? error, StackTrace? stackTrace]) {
    if (level.index < _minLevel.index) {
      return;
    }

    final levelStr = level.toString().split('.').last.toUpperCase();
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] $levelStr [$tag] $message';

    if (error != null) {
      developer.log(
        logMessage,
        name: tag,
        error: error,
        stackTrace: stackTrace,
      );
    } else {
      developer.log(
        logMessage,
        name: tag,
      );
    }
  }
}
