Map<String, dynamic> jsonMap(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

List<Map<String, dynamic>> jsonList(Object? value) => value is List
    ? value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList()
    : const [];

int jsonInt(Object? value) =>
    value is int ? value : int.tryParse('$value') ?? 0;

double jsonDouble(Object? value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
