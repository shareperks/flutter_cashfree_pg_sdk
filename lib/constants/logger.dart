import 'package:logger/logger.dart';

final logger = Logger(
  printer: PrettyPrinter(
    printEmojis: false,
    colors: true,
    dateTimeFormat: (time) {
      return DateTime.now().toIso8601String();
    },
  ),
);
