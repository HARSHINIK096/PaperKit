enum QrPayloadType {
  url,
  text,
  email,
  phone,
  sms,
  wifi,
  vcard,
  geo,
  calendar,
  unknown;

  String get displayName {
    switch (this) {
      case QrPayloadType.url:
        return 'Web URL';
      case QrPayloadType.text:
        return 'Plain Text';
      case QrPayloadType.email:
        return 'Email Message';
      case QrPayloadType.phone:
        return 'Telephone Number';
      case QrPayloadType.sms:
        return 'SMS Text';
      case QrPayloadType.wifi:
        return 'Wi-Fi Configuration';
      case QrPayloadType.vcard:
        return 'Contact (vCard)';
      case QrPayloadType.geo:
        return 'Geo Location';
      case QrPayloadType.calendar:
        return 'Calendar Event';
      case QrPayloadType.unknown:
        return 'Decoded Data';
    }
  }
}

class QrParsedPayload {
  final String rawData;
  final QrPayloadType type;
  final String title;
  final String? subtitle;
  final Map<String, dynamic> metadata;
  final bool isSuspiciousUrl;

  const QrParsedPayload({
    required this.rawData,
    required this.type,
    required this.title,
    this.subtitle,
    this.metadata = const {},
    this.isSuspiciousUrl = false,
  });

  String? get url => metadata['url'] as String?;
  String? get domain => metadata['domain'] as String?;
  String? get email => metadata['email'] as String?;
  String? get subject => metadata['subject'] as String?;
  String? get body => metadata['body'] as String?;
  String? get phone => metadata['phone'] as String?;
  String? get smsBody => metadata['smsBody'] as String?;
  String? get ssid => metadata['ssid'] as String?;
  String? get password => metadata['password'] as String?;
  String? get securityType => metadata['securityType'] as String?;
  bool get isHiddenNetwork => metadata['hidden'] == true;
  String? get contactName => metadata['name'] as String?;
  String? get organization => metadata['org'] as String?;
  double? get latitude => metadata['latitude'] as double?;
  double? get longitude => metadata['longitude'] as double?;
  String? get eventTitle => metadata['eventTitle'] as String?;
  DateTime? get eventStart => metadata['eventStart'] as DateTime?;
  DateTime? get eventEnd => metadata['eventEnd'] as DateTime?;
  String? get eventLocation => metadata['eventLocation'] as String?;
}
