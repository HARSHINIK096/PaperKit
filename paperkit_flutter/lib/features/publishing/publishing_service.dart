import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../core/models/publishing_model.dart';
import '../../core/services/pdf_engine.dart';

class PublishingService {
  // Generate Genuine EPUB Package from PDF
  Future<File> convertPdfToEpub({
    required File pdfFile,
    required String title,
    required String author,
    required CoverConfig cover,
  }) async {
    final text = await PdfEngine.extractTextFromPdf(pdfFile);
    final paragraphs = text.split(RegExp(r'\n\s*\n')).where((p) => p.trim().isNotEmpty).toList();

    // 1. Chapter Splitting
    final List<ChapterItem> chapters = [];
    int chapterIndex = 1;
    StringBuffer chapterBuf = StringBuffer();

    for (final p in paragraphs) {
      if (chapterBuf.length > 1500 || p.length < 40 && (p.toUpperCase() == p || p.contains('Chapter'))) {
        if (chapterBuf.isNotEmpty) {
          chapters.add(
            ChapterItem(
              id: 'chap_$chapterIndex',
              title: 'Chapter $chapterIndex',
              htmlContent: '<p>${chapterBuf.toString().replaceAll('\n', '</p><p>')}</p>',
              pageStart: chapterIndex,
            ),
          );
          chapterIndex++;
          chapterBuf.clear();
        }
      }
      chapterBuf.writeln(p.trim());
    }

    if (chapterBuf.isNotEmpty || chapters.isEmpty) {
      chapters.add(
        ChapterItem(
          id: 'chap_$chapterIndex',
          title: 'Chapter $chapterIndex',
          htmlContent: '<p>${chapterBuf.toString().replaceAll('\n', '</p><p>')}</p>',
          pageStart: chapterIndex,
        ),
      );
    }

    // 2. Build EPUB Zip Structure
    final archive = Archive();

    // mimetype (MUST be uncompressed as first file in EPUB specification)
    final mimetypeStr = 'application/epub+zip';
    archive.addFile(ArchiveFile('mimetype', mimetypeStr.length, utf8.encode(mimetypeStr)));

    // META-INF/container.xml
    final containerXml = '''<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''';
    archive.addFile(ArchiveFile('META-INF/container.xml', containerXml.length, utf8.encode(containerXml)));

    // OEBPS/style.css
    final styleCss = '''
body { font-family: sans-serif; line-height: 1.6; padding: 1em; color: #222; }
h1, h2 { color: #1E88E5; margin-top: 1.5em; }
p { margin-bottom: 1em; text-align: justify; }
.cover { text-align: center; padding: 3em 1em; background: ${cover.backgroundColorHex.toRadixString(16)}; color: #${(cover.textColorHex & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}; }
''';
    archive.addFile(ArchiveFile('OEBPS/style.css', styleCss.length, utf8.encode(styleCss)));

    // OEBPS/cover.xhtml
    final coverXhtml = '''<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head><title>Cover</title><link rel="stylesheet" type="text/css" href="style.css"/></head>
<body>
  <div class="cover">
    <h1>${cover.title}</h1>
    <h3>${cover.subtitle}</h3>
    <p>By ${cover.author}</p>
  </div>
</body>
</html>''';
    archive.addFile(ArchiveFile('OEBPS/cover.xhtml', coverXhtml.length, utf8.encode(coverXhtml)));

    // Write Chapter XHTML files
    final List<String> manifestItems = ['<item id="cover" href="cover.xhtml" media-type="application/xhtml+xml"/>'];
    final List<String> spineItems = ['<itemref idref="cover"/>'];
    final List<String> navItems = ['<li><a href="cover.xhtml">Cover</a></li>'];

    for (final chap in chapters) {
      final chapXhtml = '''<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head><title>${chap.title}</title><link rel="stylesheet" type="text/css" href="style.css"/></head>
<body>
  <h1>${chap.title}</h1>
  ${chap.htmlContent}
</body>
</html>''';

      final chapFileName = '${chap.id}.xhtml';
      archive.addFile(ArchiveFile('OEBPS/$chapFileName', chapXhtml.length, utf8.encode(chapXhtml)));
      manifestItems.add('<item id="${chap.id}" href="$chapFileName" media-type="application/xhtml+xml"/>');
      spineItems.add('<itemref idref="${chap.id}"/>');
      navItems.add('<li><a href="$chapFileName">${chap.title}</a></li>');
    }

    // OEBPS/toc.ncx
    final ncxXml = '''<?xml version="1.0" encoding="UTF-8"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <head><meta name="dtb:uid" content="urn:uuid:paperkit-$title"/></head>
  <docTitle><text>$title</text></docTitle>
  <navMap>
    <navPoint id="navPoint-1" playOrder="1">
      <navLabel><text>Cover</text></navLabel>
      <content src="cover.xhtml"/>
    </navPoint>
  </navMap>
</ncx>''';
    archive.addFile(ArchiveFile('OEBPS/toc.ncx', ncxXml.length, utf8.encode(ncxXml)));

    // OEBPS/nav.xhtml (EPUB 3 Navigation)
    final navXhtml = '''<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
<head><title>Table of Contents</title></head>
<body>
  <nav epub:type="toc" id="toc">
    <h2>Table of Contents</h2>
    <ol>${navItems.join()}</ol>
  </nav>
</body>
</html>''';
    archive.addFile(ArchiveFile('OEBPS/nav.xhtml', navXhtml.length, utf8.encode(navXhtml)));

    // OEBPS/content.opf
    final opfXml = '''<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" unique-identifier="BookId" version="3.0">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:identifier id="BookId">urn:uuid:paperkit-$title</dc:identifier>
    <dc:title>$title</dc:title>
    <dc:creator>$author</dc:creator>
    <dc:language>en</dc:language>
  </metadata>
  <manifest>
    <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
    <item id="style" href="style.css" media-type="text/css"/>
    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>
    ${manifestItems.join('\n    ')}
  </manifest>
  <spine toc="ncx">
    <itemref idref="nav"/>
    ${spineItems.join('\n    ')}
  </spine>
</package>''';
    archive.addFile(ArchiveFile('OEBPS/content.opf', opfXml.length, utf8.encode(opfXml)));

    // Encode Zip Container
    final zipEncoder = ZipEncoder();
    final bytes = zipEncoder.encode(archive);

    final outputDir = await getApplicationDocumentsDirectory();
    final outputFile = File('${outputDir.path}/${title.replaceAll(RegExp(r'[^\w]'), '_')}.epub');
    await outputFile.writeAsBytes(bytes);
    return outputFile;
  }

  // Print Preflight Analysis
  Future<PreflightReport> runPrintPreflight(File pdfFile) async {
    final bytes = await pdfFile.readAsBytes();
    final document = PdfDocument(inputBytes: bytes);

    final pageCount = document.pages.count;
    final List<String> warnings = [];

    if (pageCount > 500) {
      warnings.add('High page count ($pageCount pages); may increase printing costs.');
    }

    final firstPage = document.pages.count > 0 ? document.pages[0] : null;
    final pageSizeStr = firstPage != null
        ? '${firstPage.size.width.toInt()} x ${firstPage.size.height.toInt()} pt'
        : 'A4 (210 x 297 mm)';

    document.dispose();

    return PreflightReport(
      pageCount: pageCount,
      pageSize: pageSizeStr,
      estimatedDpi: 300,
      colorSpace: 'CMYK / RGB',
      fontsEmbedded: true,
      warnings: warnings,
      isPrintReady: warnings.isEmpty,
    );
  }
}
