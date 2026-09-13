import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/qr_content_type.dart';

class QrContentForm extends StatefulWidget {
  final QrContentType selectedType;
  final ValueChanged<Map<String, String>> onChanged;

  const QrContentForm({
    super.key,
    required this.selectedType,
    required this.onChanged,
  });

  @override
  State<QrContentForm> createState() => _QrContentFormState();
}

class _QrContentFormState extends State<QrContentForm> {
  final Map<String, TextEditingController> _controllers = {};
  String _wifiSecurity = 'WPA';
  bool _wifiHidden = false;
  bool _obscureWifiPass = true;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  @override
  void didUpdateWidget(covariant QrContentForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedType != widget.selectedType) {
      _initControllers();
    }
  }

  void _initControllers() {
    // Clear and instantiate controllers appropriate for the selected type
    for (final c in _controllers.values) {
      c.dispose();
    }
    _controllers.clear();

    switch (widget.selectedType) {
      case QrContentType.text:
        _controllers['text'] = TextEditingController(text: 'Hello from PaperKit!');
        break;
      case QrContentType.url:
      case QrContentType.portfolio:
        _controllers['url'] = TextEditingController(text: 'https://paperkit.app');
        break;
      case QrContentType.email:
        _controllers['email'] = TextEditingController(text: 'hello@paperkit.app');
        _controllers['subject'] = TextEditingController(text: 'PaperKit Query');
        _controllers['body'] = TextEditingController();
        break;
      case QrContentType.phone:
        _controllers['phone'] = TextEditingController(text: '+1 (555) 019-2834');
        break;
      case QrContentType.sms:
        _controllers['phone'] = TextEditingController(text: '+1 (555) 019-2834');
        _controllers['message'] = TextEditingController(text: 'Hello, checking your status.');
        break;
      case QrContentType.wifi:
        _controllers['ssid'] = TextEditingController(text: 'Campus_Guest_5G');
        _controllers['password'] = TextEditingController(text: 'SuperSecretPass123');
        break;
      case QrContentType.vcard:
        _controllers['firstName'] = TextEditingController(text: 'Alex');
        _controllers['lastName'] = TextEditingController(text: 'Morgan');
        _controllers['organization'] = TextEditingController(text: 'PaperKit Labs');
        _controllers['title'] = TextEditingController(text: 'Lead Architect');
        _controllers['phone'] = TextEditingController(text: '+1 (555) 234-5678');
        _controllers['email'] = TextEditingController(text: 'alex@paperkit.app');
        _controllers['website'] = TextEditingController(text: 'https://paperkit.app');
        _controllers['note'] = TextEditingController();
        break;
      case QrContentType.geo:
        _controllers['lat'] = TextEditingController(text: '37.7749');
        _controllers['lng'] = TextEditingController(text: '-122.4194');
        _controllers['query'] = TextEditingController(text: 'San Francisco, CA');
        break;
      case QrContentType.calendar:
        _controllers['title'] = TextEditingController(text: 'PaperKit Architecture Review');
        _controllers['location'] = TextEditingController(text: 'Conference Room 4B');
        _controllers['description'] = TextEditingController(text: 'Sprint retrospective and tool review');
        _controllers['start'] = TextEditingController(text: '20261015T140000Z');
        _controllers['end'] = TextEditingController(text: '20261015T150000Z');
        break;
      case QrContentType.deepLink:
        _controllers['link'] = TextEditingController(text: 'paperkit://domain/12');
        break;
      case QrContentType.instagram:
      case QrContentType.x:
      case QrContentType.github:
      case QrContentType.pinterest:
      case QrContentType.snapchat:
      case QrContentType.tiktok:
      case QrContentType.reddit:
      case QrContentType.telegram:
        _controllers['username'] = TextEditingController(text: 'paperkit');
        break;
      case QrContentType.facebook:
      case QrContentType.linkedin:
      case QrContentType.youtube:
        _controllers['username'] = TextEditingController(text: 'paperkit');
        break;
      case QrContentType.whatsapp:
        _controllers['phone'] = TextEditingController(text: '+15550192834');
        _controllers['message'] = TextEditingController(text: 'Hi, I would like to connect.');
        break;
      case QrContentType.discord:
        _controllers['invite'] = TextEditingController(text: 'paperkit-community');
        break;
      case QrContentType.spotify:
        _controllers['url'] = TextEditingController(text: 'https://open.spotify.com/playlist/37i9dQZF1DXcBWIGoYBM5M');
        break;
      case QrContentType.googleMaps:
        _controllers['query'] = TextEditingController(text: 'Golden Gate Bridge, San Francisco');
        break;
    }

    _notifyParent();
  }

  void _notifyParent() {
    final values = <String, String>{};
    for (final entry in _controllers.entries) {
      values[entry.key] = entry.value.text;
    }
    if (widget.selectedType == QrContentType.wifi) {
      values['type'] = _wifiSecurity;
      values['hidden'] = _wifiHidden.toString();
    }
    widget.onChanged(values);
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.selectedType == QrContentType.text) ...[
          _buildTextField('text', 'Text Content', LucideIcons.fileText, maxLines: 3),
        ] else if (widget.selectedType == QrContentType.url || widget.selectedType == QrContentType.portfolio) ...[
          _buildTextField('url', 'Website URL', LucideIcons.globe, keyboardType: TextInputType.url),
        ] else if (widget.selectedType == QrContentType.email) ...[
          _buildTextField('email', 'Email Address', LucideIcons.mail, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 12),
          _buildTextField('subject', 'Subject Line', LucideIcons.heading),
          const SizedBox(height: 12),
          _buildTextField('body', 'Message Body (Optional)', LucideIcons.messageSquare, maxLines: 2),
        ] else if (widget.selectedType == QrContentType.phone) ...[
          _buildTextField('phone', 'Phone Number', LucideIcons.phone, keyboardType: TextInputType.phone),
        ] else if (widget.selectedType == QrContentType.sms) ...[
          _buildTextField('phone', 'Recipient Number', LucideIcons.phone, keyboardType: TextInputType.phone),
          const SizedBox(height: 12),
          _buildTextField('message', 'SMS Body', LucideIcons.messageSquare, maxLines: 2),
        ] else if (widget.selectedType == QrContentType.wifi) ...[
          _buildTextField('ssid', 'Network Name (SSID)', LucideIcons.wifi),
          const SizedBox(height: 12),
          TextField(
            controller: _controllers['password'],
            obscureText: _obscureWifiPass,
            onChanged: (_) => _notifyParent(),
            decoration: InputDecoration(
              labelText: 'Wi-Fi Password',
              prefixIcon: const Icon(LucideIcons.key, size: 18),
              suffixIcon: IconButton(
                icon: Icon(_obscureWifiPass ? LucideIcons.eye : LucideIcons.eyeOff, size: 18),
                onPressed: () => setState(() => _obscureWifiPass = !_obscureWifiPass),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _wifiSecurity,
                  decoration: InputDecoration(
                    labelText: 'Encryption',
                    prefixIcon: const Icon(LucideIcons.shieldCheck, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'WPA', child: Text('WPA / WPA2 / WPA3')),
                    DropdownMenuItem(value: 'WEP', child: Text('WEP')),
                    DropdownMenuItem(value: 'nopass', child: Text('No Password (Open)')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _wifiSecurity = val);
                      _notifyParent();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Row(
                children: [
                  Checkbox(
                    value: _wifiHidden,
                    onChanged: (val) {
                      setState(() => _wifiHidden = val ?? false);
                      _notifyParent();
                    },
                  ),
                  const Text('Hidden', style: TextStyle(fontSize: 13)),
                ],
              ),
            ],
          ),
        ] else if (widget.selectedType == QrContentType.vcard) ...[
          Row(
            children: [
              Expanded(child: _buildTextField('firstName', 'First Name', LucideIcons.user)),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField('lastName', 'Last Name', LucideIcons.user)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildTextField('organization', 'Company / Org', LucideIcons.building2)),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField('title', 'Job Title', LucideIcons.briefcase)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildTextField('phone', 'Phone Number', LucideIcons.phone, keyboardType: TextInputType.phone)),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField('email', 'Email Address', LucideIcons.mail, keyboardType: TextInputType.emailAddress)),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextField('website', 'Personal Website', LucideIcons.globe, keyboardType: TextInputType.url),
        ] else if (widget.selectedType == QrContentType.geo) ...[
          Row(
            children: [
              Expanded(child: _buildTextField('lat', 'Latitude', LucideIcons.mapPin, keyboardType: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField('lng', 'Longitude', LucideIcons.mapPin, keyboardType: TextInputType.number)),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextField('query', 'Address or Search Query', LucideIcons.search),
        ] else if (widget.selectedType == QrContentType.calendar) ...[
          _buildTextField('title', 'Event Title', LucideIcons.calendar),
          const SizedBox(height: 12),
          _buildTextField('location', 'Location / Meeting Link', LucideIcons.mapPin),
          const SizedBox(height: 12),
          _buildTextField('description', 'Description', LucideIcons.fileText, maxLines: 2),
        ] else if (widget.selectedType == QrContentType.whatsapp) ...[
          _buildTextField('phone', 'Phone Number (with country code)', LucideIcons.phone, keyboardType: TextInputType.phone),
          const SizedBox(height: 12),
          _buildTextField('message', 'Pre-filled Chat Message', LucideIcons.messageCircle),
        ] else if (widget.selectedType == QrContentType.discord) ...[
          _buildTextField('invite', 'Discord Server Invite Code or Link', LucideIcons.messagesSquare),
        ] else if (widget.selectedType == QrContentType.spotify) ...[
          _buildTextField('url', 'Spotify Track / Playlist / Album URL', LucideIcons.music, keyboardType: TextInputType.url),
        ] else if (widget.selectedType == QrContentType.googleMaps) ...[
          _buildTextField('query', 'Place Name, Landmark or Coordinates', LucideIcons.map),
        ] else if (widget.selectedType.category == QrCategory.social) ...[
          _buildTextField('username', '${widget.selectedType.label} Handle or Profile URL', widget.selectedType.icon),
        ] else ...[
          _buildTextField('text', 'Content', LucideIcons.qrCode),
        ],
      ],
    );
  }

  Widget _buildTextField(
    String key,
    String label,
    IconData icon, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: _controllers[key],
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: (_) => _notifyParent(),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}
