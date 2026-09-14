import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Supported QR Content Types & Presets
enum QrCategory {
  basic,
  social,
}

enum QrContentType {
  // Basic Types
  text(
    id: 'text',
    label: 'Plain Text',
    category: QrCategory.basic,
    icon: LucideIcons.fileText,
    hint: 'Enter any text or notes to encode',
  ),
  url(
    id: 'url',
    label: 'URL / Website',
    category: QrCategory.basic,
    icon: LucideIcons.globe,
    hint: 'https://example.com',
  ),
  email(
    id: 'email',
    label: 'Email',
    category: QrCategory.basic,
    icon: LucideIcons.mail,
    hint: 'name@example.com',
  ),
  phone(
    id: 'phone',
    label: 'Phone Number',
    category: QrCategory.basic,
    icon: LucideIcons.phone,
    hint: '+1 (555) 019-2834',
  ),
  sms(
    id: 'sms',
    label: 'SMS Message',
    category: QrCategory.basic,
    icon: LucideIcons.messageSquare,
    hint: 'Recipient phone number & message',
  ),
  wifi(
    id: 'wifi',
    label: 'Wi-Fi Network',
    category: QrCategory.basic,
    icon: LucideIcons.wifi,
    hint: 'Network SSID & password',
  ),
  vcard(
    id: 'vcard',
    label: 'Contact (vCard)',
    category: QrCategory.basic,
    icon: LucideIcons.contact,
    hint: 'Name, phone, email & organization',
  ),
  geo(
    id: 'geo',
    label: 'Location / Geo',
    category: QrCategory.basic,
    icon: LucideIcons.mapPin,
    hint: 'Latitude, longitude or query',
  ),
  calendar(
    id: 'calendar',
    label: 'Calendar Event',
    category: QrCategory.basic,
    icon: LucideIcons.calendar,
    hint: 'Event title, date, location',
  ),
  deepLink(
    id: 'deepLink',
    label: 'App / Deep Link',
    category: QrCategory.basic,
    icon: LucideIcons.link2,
    hint: 'myapp://action?id=123',
  ),

  // Social Presets
  instagram(
    id: 'instagram',
    label: 'Instagram',
    category: QrCategory.social,
    icon: LucideIcons.camera,
    hint: 'username (e.g. johndoe)',
  ),
  facebook(
    id: 'facebook',
    label: 'Facebook',
    category: QrCategory.social,
    icon: LucideIcons.users,
    hint: 'username or profile URL',
  ),
  x(
    id: 'x',
    label: 'X / Twitter',
    category: QrCategory.social,
    icon: LucideIcons.atSign,
    hint: 'username (e.g. elonmusk)',
  ),
  linkedin(
    id: 'linkedin',
    label: 'LinkedIn',
    category: QrCategory.social,
    icon: LucideIcons.briefcase,
    hint: 'in/username or company name',
  ),
  youtube(
    id: 'youtube',
    label: 'YouTube',
    category: QrCategory.social,
    icon: LucideIcons.play,
    hint: '@channel or video URL',
  ),
  whatsapp(
    id: 'whatsapp',
    label: 'WhatsApp',
    category: QrCategory.social,
    icon: LucideIcons.messageCircle,
    hint: 'Phone number with country code',
  ),
  telegram(
    id: 'telegram',
    label: 'Telegram',
    category: QrCategory.social,
    icon: LucideIcons.send,
    hint: 'username or t.me link',
  ),
  snapchat(
    id: 'snapchat',
    label: 'Snapchat',
    category: QrCategory.social,
    icon: LucideIcons.ghost,
    hint: 'username',
  ),
  tiktok(
    id: 'tiktok',
    label: 'TikTok',
    category: QrCategory.social,
    icon: LucideIcons.video,
    hint: '@username',
  ),
  discord(
    id: 'discord',
    label: 'Discord',
    category: QrCategory.social,
    icon: LucideIcons.messagesSquare,
    hint: 'Server invite code or link',
  ),
  reddit(
    id: 'reddit',
    label: 'Reddit',
    category: QrCategory.social,
    icon: LucideIcons.messageSquareQuote,
    hint: 'u/username or r/subreddit',
  ),
  github(
    id: 'github',
    label: 'GitHub',
    category: QrCategory.social,
    icon: LucideIcons.code,
    hint: 'username or repository',
  ),
  pinterest(
    id: 'pinterest',
    label: 'Pinterest',
    category: QrCategory.social,
    icon: LucideIcons.pin,
    hint: 'username or board URL',
  ),
  spotify(
    id: 'spotify',
    label: 'Spotify',
    category: QrCategory.social,
    icon: LucideIcons.music,
    hint: 'Artist, playlist, or track URL',
  ),
  googleMaps(
    id: 'googleMaps',
    label: 'Google Maps',
    category: QrCategory.social,
    icon: LucideIcons.map,
    hint: 'Search query or coordinates',
  ),
  portfolio(
    id: 'portfolio',
    label: 'Website / Portfolio',
    category: QrCategory.social,
    icon: LucideIcons.laptop,
    hint: 'https://myportfolio.dev',
  );

  final String id;
  final String label;
  final QrCategory category;
  final IconData icon;
  final String hint;

  const QrContentType({
    required this.id,
    required this.label,
    required this.category,
    required this.icon,
    required this.hint,
  });
}
