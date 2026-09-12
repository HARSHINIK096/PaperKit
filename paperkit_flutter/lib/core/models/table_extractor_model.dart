class ExtractedTableCell {
  final String value;
  final int rowIndex;
  final int columnIndex;
  final bool isHeader;

  ExtractedTableCell({
    required this.value,
    required this.rowIndex,
    required this.columnIndex,
    this.isHeader = false,
  });

  factory ExtractedTableCell.fromJson(Map<String, dynamic> json) => ExtractedTableCell(
        value: json['value'] as String? ?? '',
        rowIndex: json['rowIndex'] as int? ?? 0,
        columnIndex: json['columnIndex'] as int? ?? 0,
        isHeader: json['isHeader'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'value': value,
        'rowIndex': rowIndex,
        'columnIndex': columnIndex,
        'isHeader': isHeader,
      };
}

class ExtractedTableData {
  final String title;
  final int pageNumber;
  final List<String> headers;
  final List<List<String>> rows;
  final double confidenceScore;

  ExtractedTableData({
    required this.title,
    required this.pageNumber,
    required this.headers,
    required this.rows,
    this.confidenceScore = 1.0,
  });

  factory ExtractedTableData.fromJson(Map<String, dynamic> json) => ExtractedTableData(
        title: json['title'] as String? ?? 'Extracted Table',
        pageNumber: json['pageNumber'] as int? ?? 1,
        headers: (json['headers'] as List? ?? []).cast<String>(),
        rows: (json['rows'] as List? ?? [])
            .map((r) => (r as List).cast<String>())
            .toList(),
        confidenceScore: (json['confidenceScore'] as num? ?? 1.0).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'pageNumber': pageNumber,
        'headers': headers,
        'rows': rows,
        'confidenceScore': confidenceScore,
      };
}

class ChartEstimate {
  final String chartTitle;
  final String chartType; // bar, pie, line
  final Map<String, double> estimatedData;
  final String disclaimer;

  ChartEstimate({
    required this.chartTitle,
    required this.chartType,
    required this.estimatedData,
    this.disclaimer = 'Values are estimated from visual axis analysis.',
  });

  factory ChartEstimate.fromJson(Map<String, dynamic> json) => ChartEstimate(
        chartTitle: json['chartTitle'] as String? ?? 'Extracted Chart',
        chartType: json['chartType'] as String? ?? 'bar',
        estimatedData: Map<String, double>.from(
          (json['estimatedData'] as Map? ?? {}).map(
            (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
          ),
        ),
        disclaimer: json['disclaimer'] as String? ??
            'Values are estimated from visual axis analysis.',
      );

  Map<String, dynamic> toJson() => {
        'chartTitle': chartTitle,
        'chartType': chartType,
        'estimatedData': estimatedData,
        'disclaimer': disclaimer,
      };
}
