class Filter {
  final String filter;
  final String filterType;
  final String key;
  final String title;
  final String type;

  Filter({
    required this.filter,
    required this.filterType,
    required this.key,
    required this.title,
    required this.type,
  });

  factory Filter.fromJson(Map<String, dynamic> json) {
    return Filter(
      filter: json['filter'] ?? '',
      filterType: json['filterType'] ?? 'string',
      key: json['key'] ?? '',
      title: json['title'] ?? '',
      type: json['type'] ?? 'filter',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'filter': filter,
      'filterType': filterType,
      'key': key,
      'title': title,
      'type': type,
    };
  }
}

class FilterValue {
  final String key;
  final String title;
  final String? type;

  FilterValue({required this.key, required this.title, this.type});

  factory FilterValue.fromJson(Map<String, dynamic> json) {
    return FilterValue(
      key: json['key'] ?? '',
      title: json['title'] ?? '',
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'key': key, 'title': title, if (type != null) 'type': type};
  }
}
