enum FormFieldType { text, checkbox, radio, dropdown, date, signature }

class CustomFormField {
  final String id;
  final String label;
  final FormFieldType type;
  final int pageIndex;
  final double xRatio; // Relative X coordinate (0.0 to 1.0)
  final double yRatio; // Relative Y coordinate (0.0 to 1.0)
  final double widthRatio;
  final double heightRatio;
  String value;
  final List<String> options;

  CustomFormField({
    required this.id,
    required this.label,
    required this.type,
    this.pageIndex = 0,
    this.xRatio = 0.1,
    this.yRatio = 0.1,
    this.widthRatio = 0.3,
    this.heightRatio = 0.05,
    this.value = '',
    this.options = const [],
  });

  factory CustomFormField.fromJson(Map<String, dynamic> json) => CustomFormField(
        id: json['id'] as String,
        label: json['label'] as String? ?? '',
        type: FormFieldType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => FormFieldType.text,
        ),
        pageIndex: json['pageIndex'] as int? ?? 0,
        xRatio: (json['xRatio'] as num? ?? 0.1).toDouble(),
        yRatio: (json['yRatio'] as num? ?? 0.1).toDouble(),
        widthRatio: (json['widthRatio'] as num? ?? 0.3).toDouble(),
        heightRatio: (json['heightRatio'] as num? ?? 0.05).toDouble(),
        value: json['value'] as String? ?? '',
        options: (json['options'] as List? ?? []).cast<String>(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'type': type.name,
        'pageIndex': pageIndex,
        'xRatio': xRatio,
        'yRatio': yRatio,
        'widthRatio': widthRatio,
        'heightRatio': heightRatio,
        'value': value,
        'options': options,
      };
}

class UserFormProfile {
  final String id;
  final String profileName;
  final String fullName;
  final String email;
  final String phone;
  final String address;
  final String institution;
  final String studentId;
  final Map<String, String> customFields;

  UserFormProfile({
    required this.id,
    required this.profileName,
    this.fullName = '',
    this.email = '',
    this.phone = '',
    this.address = '',
    this.institution = '',
    this.studentId = '',
    Map<String, String>? customFields,
  }) : customFields = customFields ?? {};

  factory UserFormProfile.fromJson(Map<String, dynamic> json) => UserFormProfile(
        id: json['id'] as String,
        profileName: json['profileName'] as String? ?? 'Default Profile',
        fullName: json['fullName'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        address: json['address'] as String? ?? '',
        institution: json['institution'] as String? ?? '',
        studentId: json['studentId'] as String? ?? '',
        customFields: Map<String, String>.from(json['customFields'] as Map? ?? {}),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'profileName': profileName,
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'address': address,
        'institution': institution,
        'studentId': studentId,
        'customFields': customFields,
      };
}
