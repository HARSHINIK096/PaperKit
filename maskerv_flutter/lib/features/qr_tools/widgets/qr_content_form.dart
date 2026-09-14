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
        _controllers['text'] = TextEditingController();
        break;
      case QrContentType.url:
      case QrContentType.portfolio:
        _controllers['url'] = TextEditingController();
        break;
      case QrContentType.email:
        _controllers['email'] = TextEditingController();
        _controllers['subject'] = TextEditingController();
        _controllers['body'] = TextEditingController();
        break;
      case QrContentType.phone:
        _controllers['phone'] = TextEditingController();
        break;
      case QrContentType.sms:
        _controllers['phone'] = TextEditingController();
        _controllers['message'] = TextEditingController();
        break;
      case QrContentType.wifi:
        _controllers['ssid'] = TextEditingController();
        _controllers['password'] = TextEditingController();
        break;
      case QrContentType.vcard:
        _controllers['firstName'] = TextEditingController();
        _controllers['lastName'] = TextEditingController();
        _controllers['organization'] = TextEditingController();
        _controllers['title'] = TextEditingController();
        _controllers['phone'] = TextEditingController();
        _controllers['email'] = TextEditingController();
        _controllers['website'] = TextEditingController();
        _controllers['note'] = TextEditingController();
        break;
      case QrContentType.geo:
        _controllers['lat'] = TextEditingController();
        _controllers['lng'] = TextEditingController();
        _controllers['query'] = TextEditingController();
        break;
      case QrContentType.calendar:
        _controllers['title'] = TextEditingController();
        _controllers['location'] = TextEditingController();
        _controllers['description'] = TextEditingController();
        _controllers['start'] = TextEditingController();
        _controllers['end'] = TextEditingController();
        break;
      case QrContentType.deepLink:
        _controllers['link'] = TextEditingController();
        break;
      case QrContentType.instagram:
      case QrContentType.x:
      case QrContentType.github:
      case QrContentType.pinterest:
      case QrContentType.snapchat:
      case QrContentType.tiktok:
      case QrContentType.reddit:
      case QrContentType.telegram:
      case QrContentType.facebook:
      case QrContentType.linkedin:
      case QrContentType.youtube:
        _controllers['username'] = TextEditingController();
        break;
      case QrContentType.whatsapp:
        _controllers['phone'] = TextEditingController();
        _controllers['message'] = TextEditingController();
        break;
      case QrContentType.discord:
        _controllers['invite'] = TextEditingController();
        break;
      case QrContentType.spotify:
        _controllers['url'] = TextEditingController();
        break;
      case QrContentType.googleMaps:
        _controllers['query'] = TextEditingController();
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
          _buildTextField('text', 'Text Content', LucideIcons.fileText, hintText: 'Enter text or notes to encode...', maxLines: 3),
        ] else if (widget.selectedType == QrContentType.url || widget.selectedType == QrContentType.portfolio) ...[
          _buildTextField('url', 'Website URL', LucideIcons.globe, hintText: 'https://...', keyboardType: TextInputType.url),
        ] else if (widget.selectedType == QrContentType.email) ...[
          _buildTextField('email', 'Email Address', LucideIcons.mail, hintText: 'name@domain.com', keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 12),
          _buildTextField('subject', 'Subject Line', LucideIcons.heading, hintText: 'Enter email subject'),
          const SizedBox(height: 12),
          _buildTextField('body', 'Message Body (Optional)', LucideIcons.messageSquare, hintText: 'Enter email body...', maxLines: 2),
        ] else if (widget.selectedType == QrContentType.phone) ...[
          _buildTextField('phone', 'Phone Number', LucideIcons.phone, hintText: '+1...', keyboardType: TextInputType.phone),
        ] else if (widget.selectedType == QrContentType.sms) ...[
          _buildTextField('phone', 'Recipient Number', LucideIcons.phone, hintText: '+1...', keyboardType: TextInputType.phone),
          const SizedBox(height: 12),
          _buildTextField('message', 'SMS Body', LucideIcons.messageSquare, hintText: 'Enter SMS text...', maxLines: 2),
        ] else if (widget.selectedType == QrContentType.wifi) ...[
          _buildTextField('ssid', 'Network Name (SSID)', LucideIcons.wifi, hintText: 'Enter Wi-Fi network name'),
          const SizedBox(height: 12),
          TextField(
            controller: _controllers['password'],
            obscureText: _obscureWifiPass,
            onChanged: (_) => _notifyParent(),
            decoration: InputDecoration(
              labelText: 'Wi-Fi Password',
              hintText: 'Enter Wi-Fi password',
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
              Expanded(child: _buildTextField('firstName', 'First Name', LucideIcons.user, hintText: 'Enter first name')),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField('lastName', 'Last Name', LucideIcons.user, hintText: 'Enter last name')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildTextField('organization', 'Company / Org', LucideIcons.building2, hintText: 'Enter company or organization')),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField('title', 'Job Title', LucideIcons.briefcase, hintText: 'Enter job title')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildTextField('phone', 'Phone Number', LucideIcons.phone, hintText: 'Enter contact phone', keyboardType: TextInputType.phone)),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField('email', 'Email Address', LucideIcons.mail, hintText: 'name@domain.com', keyboardType: TextInputType.emailAddress)),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextField('website', 'Personal Website', LucideIcons.globe, hintText: 'https://...', keyboardType: TextInputType.url),
        ] else if (widget.selectedType == QrContentType.geo) ...[
          Row(
            children: [
              Expanded(child: _buildTextField('lat', 'Latitude', LucideIcons.mapPin, hintText: 'Latitude coordinate', keyboardType: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField('lng', 'Longitude', LucideIcons.mapPin, hintText: 'Longitude coordinate', keyboardType: TextInputType.number)),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextField('query', 'Address or Search Query', LucideIcons.search, hintText: 'Enter address or query'),
        ] else if (widget.selectedType == QrContentType.calendar) ...[
          _buildTextField('title', 'Event Title', LucideIcons.calendar, hintText: 'Enter event title'),
          const SizedBox(height: 12),
          _buildTextField('location', 'Location / Meeting Link', LucideIcons.mapPin, hintText: 'Enter location or link'),
          const SizedBox(height: 12),
          _buildTextField('description', 'Description', LucideIcons.fileText, hintText: 'Enter event description...', maxLines: 2),
        ] else if (widget.selectedType == QrContentType.whatsapp) ...[
          _buildTextField('phone', 'Phone Number (with country code)', LucideIcons.phone, hintText: '+1...', keyboardType: TextInputType.phone),
          const SizedBox(height: 12),
          _buildTextField('message', 'Pre-filled Chat Message', LucideIcons.messageCircle, hintText: 'Enter initial chat message'),
        ] else if (widget.selectedType == QrContentType.discord) ...[
          _buildTextField('invite', 'Discord Server Invite Code or Link', LucideIcons.messagesSquare, hintText: 'Enter Discord invite code or URL'),
        ] else if (widget.selectedType == QrContentType.spotify) ...[
          _buildTextField('url', 'Spotify Track / Playlist / Album URL', LucideIcons.music, hintText: 'https://open.spotify.com/...', keyboardType: TextInputType.url),
        ] else if (widget.selectedType == QrContentType.googleMaps) ...[
          _buildTextField('query', 'Place Name, Landmark or Coordinates', LucideIcons.map, hintText: 'Enter place name, landmark or coordinates'),
        ] else if (widget.selectedType.category == QrCategory.social) ...[
          _buildTextField('username', '${widget.selectedType.label} Handle or Profile URL', widget.selectedType.icon, hintText: 'Enter username or profile URL'),
        ] else ...[
          _buildTextField('text', 'Content', LucideIcons.qrCode, hintText: 'Enter text here...'),
        ],
      ],
    );
  }

  Widget _buildTextField(
    String key,
    String label,
    IconData icon, {
    String? hintText,
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
        hintText: hintText,
        prefixIcon: Icon(icon, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}
