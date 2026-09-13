import '../models/qr_parsed_payload.dart';

class QrPayloadParser {
  const QrPayloadParser._();

  static QrParsedPayload parse(String raw) {
    final trimmed = raw.trim();

    // 1. Wi-Fi
    if (trimmed.startsWith('WIFI:') || trimmed.startsWith('wifi:')) {
      return _parseWifi(trimmed);
    }

    // 2. vCard Contact
    if (trimmed.toUpperCase().contains('BEGIN:VCARD')) {
      return _parseVCard(trimmed);
    }

    // 3. Calendar Event
    if (trimmed.toUpperCase().contains('BEGIN:VEVENT')) {
      return _parseCalendar(trimmed);
    }

    // 4. Email
    if (trimmed.startsWith('mailto:') || trimmed.startsWith('MAILTO:') || trimmed.startsWith('MATMSG:')) {
      return _parseEmail(trimmed);
    }

    // 5. Telephone
    if (trimmed.startsWith('tel:') || trimmed.startsWith('TEL:')) {
      final phone = trimmed.substring(4).trim();
      return QrParsedPayload(
        rawData: raw,
        type: QrPayloadType.phone,
        title: phone,
        subtitle: 'Tap to call or copy',
        metadata: {'phone': phone},
      );
    }

    // 6. SMS
    if (trimmed.startsWith('smsto:') || trimmed.startsWith('SMSTO:') || trimmed.startsWith('sms:') || trimmed.startsWith('SMS:')) {
      return _parseSms(trimmed);
    }

    // 7. Geo Location
    if (trimmed.startsWith('geo:') || trimmed.startsWith('GEO:')) {
      return _parseGeo(trimmed);
    }

    // 8. URL (Web Link)
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://') || _isLikelyUrl(trimmed)) {
      return _parseUrl(trimmed);
    }

    // 9. Plain Text / Raw
    final preview = trimmed.length > 50 ? '${trimmed.substring(0, 50)}...' : trimmed;
    return QrParsedPayload(
      rawData: raw,
      type: QrPayloadType.text,
      title: preview,
      subtitle: '${trimmed.length} characters',
      metadata: {'text': trimmed},
    );
  }

  static QrParsedPayload _parseUrl(String rawUrl) {
    String url = rawUrl;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    final uri = Uri.tryParse(url);
    final domain = uri?.host ?? '';
    final isHttp = url.startsWith('http://');
    final isIpAddress = RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$').hasMatch(domain);
    final isSuspicious = isHttp || isIpAddress || domain.endsWith('.xyz') || domain.endsWith('.top');

    return QrParsedPayload(
      rawData: rawUrl,
      type: QrPayloadType.url,
      title: domain.isNotEmpty ? domain : url,
      subtitle: url,
      metadata: {
        'url': url,
        'domain': domain,
      },
      isSuspiciousUrl: isSuspicious,
    );
  }

  static bool _isLikelyUrl(String text) {
    final pattern = RegExp(
      r'^(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );
    return pattern.hasMatch(text);
  }

  static QrParsedPayload _parseWifi(String raw) {
    // Format: WIFI:T:WPA;S:MySSID;P:MyPassword;H:false;;
    String ssid = '';
    String password = '';
    String securityType = 'WPA';
    bool hidden = false;

    final content = raw.substring(raw.indexOf(':') + 1);
    final tokens = _splitWifiTokens(content);

    for (final token in tokens) {
      if (token.startsWith('S:') || token.startsWith('s:')) {
        ssid = token.substring(2);
      } else if (token.startsWith('P:') || token.startsWith('p:')) {
        password = token.substring(2);
      } else if (token.startsWith('T:') || token.startsWith('t:')) {
        securityType = token.substring(2).toUpperCase();
      } else if (token.startsWith('H:') || token.startsWith('h:')) {
        hidden = token.substring(2).toLowerCase() == 'true';
      }
    }

    return QrParsedPayload(
      rawData: raw,
      type: QrPayloadType.wifi,
      title: ssid.isNotEmpty ? ssid : 'Wi-Fi Network',
      subtitle: 'Security: $securityType${hidden ? ' (Hidden)' : ''}',
      metadata: {
        'ssid': ssid,
        'password': password,
        'securityType': securityType,
        'hidden': hidden,
      },
    );
  }

  static List<String> _splitWifiTokens(String content) {
    final tokens = <String>[];
    final current = StringBuffer();
    bool escaped = false;

    for (int i = 0; i < content.length; i++) {
      final char = content[i];
      if (escaped) {
        current.write(char);
        escaped = false;
      } else if (char == '\\') {
        escaped = true;
      } else if (char == ';') {
        final token = current.toString().trim();
        if (token.isNotEmpty) tokens.add(token);
        current.clear();
      } else {
        current.write(char);
      }
    }
    if (current.isNotEmpty) {
      tokens.add(current.toString().trim());
    }
    return tokens;
  }

  static QrParsedPayload _parseVCard(String raw) {
    String name = '';
    String phone = '';
    String email = '';
    String org = '';

    final lines = raw.split(RegExp(r'\r?\n'));
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('FN:') || trimmed.startsWith('fn:')) {
        name = trimmed.substring(3).trim();
      } else if ((trimmed.startsWith('TEL') || trimmed.startsWith('tel')) && trimmed.contains(':')) {
        phone = trimmed.substring(trimmed.indexOf(':') + 1).trim();
      } else if ((trimmed.startsWith('EMAIL') || trimmed.startsWith('email')) && trimmed.contains(':')) {
        email = trimmed.substring(trimmed.indexOf(':') + 1).trim();
      } else if ((trimmed.startsWith('ORG') || trimmed.startsWith('org')) && trimmed.contains(':')) {
        org = trimmed.substring(trimmed.indexOf(':') + 1).trim();
      }
    }

    return QrParsedPayload(
      rawData: raw,
      type: QrPayloadType.vcard,
      title: name.isNotEmpty ? name : (org.isNotEmpty ? org : 'Contact Card'),
      subtitle: phone.isNotEmpty ? phone : email,
      metadata: {
        'name': name,
        'phone': phone,
        'email': email,
        'org': org,
      },
    );
  }

  static QrParsedPayload _parseCalendar(String raw) {
    String title = 'Calendar Event';
    String location = '';

    final lines = raw.split(RegExp(r'\r?\n'));
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('SUMMARY:')) {
        title = trimmed.substring(8).trim();
      } else if (trimmed.startsWith('LOCATION:')) {
        location = trimmed.substring(9).trim();
      }
    }

    return QrParsedPayload(
      rawData: raw,
      type: QrPayloadType.calendar,
      title: title,
      subtitle: location.isNotEmpty ? location : 'Event Details',
      metadata: {
        'eventTitle': title,
        'eventLocation': location,
      },
    );
  }

  static QrParsedPayload _parseEmail(String raw) {
    String email = '';
    String subject = '';
    String body = '';

    if (raw.startsWith('mailto:') || raw.startsWith('MAILTO:')) {
      final uri = Uri.tryParse(raw);
      if (uri != null) {
        email = uri.path;
        subject = uri.queryParameters['subject'] ?? '';
        body = uri.queryParameters['body'] ?? '';
      }
    } else if (raw.startsWith('MATMSG:')) {
      // MATMSG:TO:user@example.com;SUB:Subject;BODY:Hello;;
      final parts = raw.substring(7).split(';');
      for (final part in parts) {
        if (part.startsWith('TO:')) email = part.substring(3);
        if (part.startsWith('SUB:')) subject = part.substring(4);
        if (part.startsWith('BODY:')) body = part.substring(5);
      }
    }

    return QrParsedPayload(
      rawData: raw,
      type: QrPayloadType.email,
      title: email.isNotEmpty ? email : 'Email',
      subtitle: subject.isNotEmpty ? subject : body,
      metadata: {
        'email': email,
        'subject': subject,
        'body': body,
      },
    );
  }

  static QrParsedPayload _parseSms(String raw) {
    String phone = '';
    String message = '';

    if (raw.startsWith('smsto:') || raw.startsWith('SMSTO:')) {
      final parts = raw.substring(6).split(':');
      if (parts.isNotEmpty) phone = parts[0];
      if (parts.length > 1) message = parts.sublist(1).join(':');
    } else if (raw.startsWith('sms:') || raw.startsWith('SMS:')) {
      final uri = Uri.tryParse(raw);
      phone = uri?.path ?? '';
      message = uri?.queryParameters['body'] ?? '';
    }

    return QrParsedPayload(
      rawData: raw,
      type: QrPayloadType.sms,
      title: phone.isNotEmpty ? phone : 'SMS Message',
      subtitle: message.isNotEmpty ? message : 'Send text message',
      metadata: {
        'phone': phone,
        'smsBody': message,
      },
    );
  }

  static QrParsedPayload _parseGeo(String raw) {
    // geo:37.7749,-122.4194?q=San+Francisco
    double? lat;
    double? lng;
    String locationText = raw.substring(4);

    final qIndex = locationText.indexOf('?');
    String coords = qIndex >= 0 ? locationText.substring(0, qIndex) : locationText;
    final split = coords.split(',');
    if (split.length >= 2) {
      lat = double.tryParse(split[0].trim());
      lng = double.tryParse(split[1].trim());
    }

    return QrParsedPayload(
      rawData: raw,
      type: QrPayloadType.geo,
      title: lat != null && lng != null ? '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}' : 'Location',
      subtitle: 'Coordinates: $coords',
      metadata: {
        'latitude': lat,
        'longitude': lng,
      },
    );
  }
}
