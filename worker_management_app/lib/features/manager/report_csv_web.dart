// ignore: avoid_web_libraries_in_flutter
import 'package:web/web.dart' as web;

/// Triggers a CSV file download in the browser.
void downloadCsvOnWeb(String csvContent, String monthLabel) {
  final String encodedContent =
      'data:text/csv;charset=utf-8,\uFEFF${Uri.encodeComponent(csvContent)}';
  final web.HTMLAnchorElement downloadLink =
  web.document.createElement('a') as web.HTMLAnchorElement;
  downloadLink.href = encodedContent;
  downloadLink.download =
  'report_${monthLabel.replaceAll('/', '_')}.csv';
  downloadLink.click();
}