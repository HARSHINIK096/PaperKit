import '../models/qr_content_type.dart';

class QrPayloadFormatter {
  const QrPayloadFormatter._();

  static String format({
    required QrContentType type,
    required Map<String, String> values,
  }) {
    switch (type) {
      case QrContentType.text:
        return values['text']?.trim() ?? '';

      case QrContentType.url:
      case QrContentType.portfolio:
        String url = values['url']?.trim() ?? '';
        if (url.isEmpty) return '';
        if (!url.startsWith('http://') && !url.startsWith('https://')) {
          url = 'https://$url';
        }
        return url;

      case QrContentType.email:
        final email = values['email']?.trim() ?? '';
        final subject = values['subject']?.trim() ?? '';
        final body = values['body']?.trim() ?? '';
        if (email.isEmpty) return '';
        final queryParams = <String>[];
        if (subject.isNotEmpty) queryParams.add('subject=${Uri.encodeComponent(subject)}');
        if (body.isNotEmpty) queryParams.add('body=${Uri.encodeComponent(body)}');
        final query = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
        return 'mailto:$email$query';

      case QrContentType.phone:
        final phone = values['phone']?.trim() ?? '';
        return phone.isNotEmpty ? 'tel:$phone' : '';

      case QrContentType.sms:
        final phone = values['phone']?.trim() ?? '';
        final message = values['message']?.trim() ?? '';
        if (phone.isEmpty) return '';
        if (message.isNotEmpty) {
          return 'smsto:$phone:${message.replaceAll(':', ' ')}';
        }
        return 'sms:$phone';

      case QrContentType.wifi:
        final ssid = _escapeWifi(values['ssid']?.trim() ?? '');
        final password = _escapeWifi(values['password'] ?? '');
        final authType = values['type']?.toUpperCase() ?? 'WPA'; // WPA, WEP, nopass
        final hidden = values['hidden'] == 'true' ? 'true' : 'false';
        if (ssid.isEmpty) return '';
        return 'WIFI:T:$authType;S:$ssid;P:$password;H:$hidden;;';

      case QrContentType.vcard:
        final firstName = values['firstName']?.trim() ?? '';
        final lastName = values['lastName']?.trim() ?? '';
        final org = values['organization']?.trim() ?? '';
        final title = values['title']?.trim() ?? '';
        final phone = values['phone']?.trim() ?? '';
        final email = values['email']?.trim() ?? '';
        final website = values['website']?.trim() ?? '';
        final note = values['note']?.trim() ?? '';

        final buffer = StringBuffer();
        buffer.writeln('BEGIN:VCARD');
        buffer.writeln('VERSION:3.0');
        buffer.writeln('N:$lastName;$firstName;;;');
        buffer.writeln('FN:${'$firstName $lastName'.trim()}');
        if (org.isNotEmpty) buffer.writeln('ORG:$org');
        if (title.isNotEmpty) buffer.writeln('TITLE:$title');
        if (phone.isNotEmpty) buffer.writeln('TEL;TYPE=CELL:$phone');
        if (email.isNotEmpty) buffer.writeln('EMAIL:$email');
        if (website.isNotEmpty) buffer.writeln('URL:$website');
        if (note.isNotEmpty) buffer.writeln('NOTE:$note');
        buffer.writeln('END:VCARD');
        return buffer.toString().trim();

      case QrContentType.geo:
        final lat = values['lat']?.trim() ?? '';
        final lng = values['lng']?.trim() ?? '';
        final query = values['query']?.trim() ?? '';
        if (lat.isNotEmpty && lng.isNotEmpty) {
          return query.isNotEmpty ? 'geo:$lat,$lng?q=${Uri.encodeComponent(query)}' : 'geo:$lat,$lng';
        }
        if (query.isNotEmpty) {
          return 'https://maps.google.com/?q=${Uri.encodeComponent(query)}';
        }
        return '';

      case QrContentType.calendar:
        final title = values['title']?.trim() ?? 'Event';
        final description = values['description']?.trim() ?? '';
        final location = values['location']?.trim() ?? '';
        final startIso = values['start'] ?? '';
        final endIso = values['end'] ?? '';

        final buffer = StringBuffer();
        buffer.writeln('BEGIN:VEVENT');
        buffer.writeln('SUMMARY:$title');
        if (description.isNotEmpty) buffer.writeln('DESCRIPTION:$description');
        if (location.isNotEmpty) buffer.writeln('LOCATION:$location');
        if (startIso.isNotEmpty) buffer.writeln('DTSTART:$startIso');
        if (endIso.isNotEmpty) buffer.writeln('DTEND:$endIso');
        buffer.writeln('END:VEVENT');
        return buffer.toString().trim();

      case QrContentType.deepLink:
        return values['link']?.trim() ?? '';

      // Social Media Presets
      case QrContentType.instagram:
        final u = _cleanHandle(values['username'] ?? '');
        if (u.startsWith('http://') || u.startsWith('https://')) return u;
        return u.isNotEmpty ? 'https://instagram.com/$u' : '';

      case QrContentType.facebook:
        final u = values['username']?.trim() ?? '';
        if (u.startsWith('http://') || u.startsWith('https://')) return u;
        return u.isNotEmpty ? 'https://facebook.com/$u' : '';

      case QrContentType.x:
        final u = _cleanHandle(values['username'] ?? '');
        if (u.startsWith('http://') || u.startsWith('https://')) return u;
        return u.isNotEmpty ? 'https://x.com/$u' : '';

      case QrContentType.linkedin:
        final u = values['username']?.trim() ?? '';
        if (u.startsWith('http://') || u.startsWith('https://')) return u;
        if (u.startsWith('in/')) return 'https://linkedin.com/$u';
        return u.isNotEmpty ? 'https://linkedin.com/in/$u' : '';

      case QrContentType.youtube:
        final u = values['username']?.trim() ?? '';
        if (u.startsWith('http://') || u.startsWith('https://')) return u;
        if (u.startsWith('@')) return 'https://youtube.com/$u';
        return u.isNotEmpty ? 'https://youtube.com/@$u' : '';

      case QrContentType.whatsapp:
        final phone = values['phone']?.replaceAll(RegExp(r'[^\d]'), '') ?? '';
        final text = values['message']?.trim() ?? '';
        if (phone.isEmpty) return '';
        final textParam = text.isNotEmpty ? '?text=${Uri.encodeComponent(text)}' : '';
        return 'https://wa.me/$phone$textParam';

      case QrContentType.telegram:
        final u = _cleanHandle(values['username'] ?? '');
        if (u.startsWith('http://') || u.startsWith('https://')) return u;
        return u.isNotEmpty ? 'https://t.me/$u' : '';

      case QrContentType.snapchat:
        final u = _cleanHandle(values['username'] ?? '');
        if (u.startsWith('http://') || u.startsWith('https://')) return u;
        return u.isNotEmpty ? 'https://snapchat.com/add/$u' : '';

      case QrContentType.tiktok:
        final u = _cleanHandle(values['username'] ?? '');
        if (u.startsWith('http://') || u.startsWith('https://')) return u;
        return u.isNotEmpty ? 'https://tiktok.com/@$u' : '';

      case QrContentType.discord:
        final u = values['invite']?.trim() ?? '';
        if (u.startsWith('http://') || u.startsWith('https://')) return u;
        return u.isNotEmpty ? 'https://discord.gg/$u' : '';

      case QrContentType.reddit:
        final u = values['username']?.trim() ?? '';
        if (u.startsWith('http://') || u.startsWith('https://')) return u;
        if (u.startsWith('u/') || u.startsWith('r/')) return 'https://reddit.com/$u';
        return u.isNotEmpty ? 'https://reddit.com/u/$u' : '';

      case QrContentType.github:
        final u = _cleanHandle(values['username'] ?? '');
        if (u.startsWith('http://') || u.startsWith('https://')) return u;
        return u.isNotEmpty ? 'https://github.com/$u' : '';

      case QrContentType.pinterest:
        final u = _cleanHandle(values['username'] ?? '');
        if (u.startsWith('http://') || u.startsWith('https://')) return u;
        return u.isNotEmpty ? 'https://pinterest.com/$u' : '';

      case QrContentType.spotify:
        final u = values['url']?.trim() ?? '';
        if (u.startsWith('http://') || u.startsWith('https://')) return u;
        return u.isNotEmpty ? 'https://open.spotify.com/$u' : '';

      case QrContentType.googleMaps:
        final q = values['query']?.trim() ?? '';
        return q.isNotEmpty ? 'https://maps.google.com/?q=${Uri.encodeComponent(q)}' : '';
    }
  }

  static String _cleanHandle(String handle) {
    String clean = handle.trim();
    if (clean.startsWith('@')) clean = clean.substring(1);
    return clean;
  }

  static String _escapeWifi(String text) {
    return text.replaceAll('\\', '\\\\')
        .replaceAll(';', r'\;')
        .replaceAll(',', r'\,')
        .replaceAll(':', r'\:');
  }
}
