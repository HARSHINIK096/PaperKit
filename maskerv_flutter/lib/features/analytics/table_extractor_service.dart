import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/models/table_extractor_model.dart';
import '../../core/services/pdf_engine.dart';

class TableExtractorService {
  // Extract Structured Tables from PDF
  Future<List<ExtractedTableData>> extractTablesFromPdf(File file) async {
    final text = await PdfEngine.extractTextFromPdf(file);
    final lines = text.split(RegExp(r'\r?\n')).where((l) => l.trim().isNotEmpty).toList();

    final List<ExtractedTableData> tables = [];
    final List<String> currentHeaders = [];
    final List<List<String>> currentRows = [];

    for (final line in lines) {
      final parts = line.split(RegExp(r'\t|\s{2,}|,'));
      if (parts.length >= 3) {
        if (currentHeaders.isEmpty) {
          currentHeaders.addAll(parts.map((p) => p.trim()));
        } else {
          currentRows.add(parts.map((p) => p.trim()).toList());
        }
      }
    }

    if (currentHeaders.isNotEmpty && currentRows.isNotEmpty) {
      tables.add(
        ExtractedTableData(
          title: 'Table 1 (${file.uri.pathSegments.last})',
          pageNumber: 1,
          headers: currentHeaders,
          rows: currentRows,
        ),
      );
    }

    return tables;
  }

  // Export Table as CSV
  Future<File> exportToCsv(ExtractedTableData table, {String delimiter = ','}) async {
    final StringBuffer buf = StringBuffer();
    buf.writeln(table.headers.map((h) => '"${h.replaceAll('"', '""')}"').join(delimiter));

    for (final row in table.rows) {
      buf.writeln(row.map((c) => '"${c.replaceAll('"', '""')}"').join(delimiter));
    }

    final outputDir = await getApplicationDocumentsDirectory();
    final outputFile = File('${outputDir.path}/${table.title.replaceAll(RegExp(r'[^\w]'), '_')}.csv');
    await outputFile.writeAsString(buf.toString());
    return outputFile;
  }

  // Export Table as XLSX Spreadsheet (Zip OpenXML format)
  Future<File> exportToXlsx(ExtractedTableData table) async {
    final archive = Archive();

    // 1. [Content_Types].xml
    final contentTypes = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
  <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
</Types>''';
    archive.addFile(ArchiveFile('[Content_Types].xml', contentTypes.length, utf8.encode(contentTypes)));

    // 2. _rels/.rels
    final rels = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
</Relationships>''';
    archive.addFile(ArchiveFile('_rels/.rels', rels.length, utf8.encode(rels)));

    // 3. xl/workbook.xml
    final workbook = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <sheets>
    <sheet name="Sheet1" sheetId="1" r:id="rId1"/>
  </sheets>
</workbook>''';
    archive.addFile(ArchiveFile('xl/workbook.xml', workbook.length, utf8.encode(workbook)));

    // 4. xl/_rels/workbook.xml.rels
    final wbRels = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
</Relationships>''';
    archive.addFile(ArchiveFile('xl/_rels/workbook.xml.rels', wbRels.length, utf8.encode(wbRels)));

    // 5. xl/worksheets/sheet1.xml
    final sheetBuf = StringBuffer();
    sheetBuf.writeln('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
    sheetBuf.writeln('<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><sheetData>');

    // Row 1: Headers
    sheetBuf.writeln('<row r="1">');
    for (int col = 0; col < table.headers.length; col++) {
      final colLetter = String.fromCharCode(65 + col);
      sheetBuf.writeln('<c r="${colLetter}1" t="inlineStr"><is><t>${table.headers[col]}</t></is></c>');
    }
    sheetBuf.writeln('</row>');

    // Rows
    for (int r = 0; r < table.rows.length; r++) {
      final rowNum = r + 2;
      sheetBuf.writeln('<row r="$rowNum">');
      for (int c = 0; c < table.rows[r].length; c++) {
        final colLetter = String.fromCharCode(65 + c);
        sheetBuf.writeln('<c r="$colLetter$rowNum" t="inlineStr"><is><t>${table.rows[r][c]}</t></is></c>');
      }
      sheetBuf.writeln('</row>');
    }
    sheetBuf.writeln('</sheetData></worksheet>');

    final sheetXml = sheetBuf.toString();
    archive.addFile(ArchiveFile('xl/worksheets/sheet1.xml', sheetXml.length, utf8.encode(sheetXml)));

    final zipEncoder = ZipEncoder();
    final encoded = zipEncoder.encode(archive);

    final outputDir = await getApplicationDocumentsDirectory();
    final outputFile = File('${outputDir.path}/${table.title.replaceAll(RegExp(r'[^\w]'), '_')}.xlsx');
    await outputFile.writeAsBytes(encoded);
    return outputFile;
  }
}
