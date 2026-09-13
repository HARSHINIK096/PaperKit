import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/constants/tool_registry.dart';
import '../../core/models/tool_item.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/tool_card.dart';

class CategoryHubScreen extends StatefulWidget {
  final String categoryId;

  const CategoryHubScreen({super.key, required this.categoryId});

  @override
  State<CategoryHubScreen> createState() => _CategoryHubScreenState();
}

class _CategoryHubScreenState extends State<CategoryHubScreen> {
  String _searchQuery = '';
  late String _currentKey;

  @override
  void initState() {
    super.initState();
    _currentKey = widget.categoryId;
  }

  @override
  void didUpdateWidget(covariant CategoryHubScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoryId != widget.categoryId) {
      setState(() {
        _currentKey = widget.categoryId;
        _searchQuery = '';
      });
    }
  }

  DomainItem? get _domain => DomainRegistry.resolve(_currentKey);

  bool get _isUtilities =>
      _domain == null &&
      (_currentKey.toLowerCase() == 'utilities' ||
          _currentKey.toLowerCase() == 'utility' ||
          _currentKey.toLowerCase() == 'media');

  String get _title {
    if (_domain != null) {
      return 'Domain ${_domain!.number}: ${_domain!.name}';
    }
    if (_isUtilities) {
      return 'General Utilities & Media';
    }
    return 'PaperKit Domain Hub';
  }

  String get _subtitle {
    if (_domain != null) {
      return _domain!.description;
    }
    if (_isUtilities) {
      return 'Cross-domain general utilities, barcodes, QR tools, video processing and compression archives.';
    }
    return 'Select an authoritative domain to explore and run document intelligence tools.';
  }

  List<ToolItem> get _primaryTools {
    if (_domain != null) {
      return ToolRegistry.getByDomainNumber(_domain!.number);
    }
    if (_isUtilities) {
      return ToolRegistry.generalUtilities;
    }
    return ToolRegistry.getByDomainNumber(1);
  }

  List<ToolItem> get _crossDomainTools {
    if (_domain != null) {
      return ToolRegistry.getCrossDomainTools(_domain!.number);
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final domain = _domain;
    final primaryColor = domain?.color ?? AppColors.primary;
    final softColor = domain?.softColor ?? AppColors.primarySoft;

    final query = _searchQuery.toLowerCase().trim();
    final filteredPrimary = query.isEmpty
        ? _primaryTools
        : _primaryTools.where((t) {
            return t.label.toLowerCase().contains(query) ||
                t.description.toLowerCase().contains(query) ||
                t.tags.any((tag) => tag.toLowerCase().contains(query));
          }).toList();

    final filteredCross = query.isEmpty
        ? _crossDomainTools
        : _crossDomainTools.where((t) {
            return t.label.toLowerCase().contains(query) ||
                t.description.toLowerCase().contains(query) ||
                t.tags.any((tag) => tag.toLowerCase().contains(query));
          }).toList();

    return AppShell(
      title: domain != null ? 'Domain ${domain.number}' : 'Domain Hub',
      child: Column(
        children: [
          // ── Horizontal Domain Selector Strip ─────────────────────────
          Container(
            height: 48,
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: DomainRegistry.domains.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final d = DomainRegistry.domains[index];
                final isSelected = domain?.number == d.number;

                return ChoiceChip(
                  label: Text(
                    'D${d.number} • ${d.shortName}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: d.color,
                  backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected
                          ? d.color
                          : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                      width: 1.2,
                    ),
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _currentKey = '${d.number}';
                        _searchQuery = '';
                      });
                    }
                  },
                );
              },
            ),
          ),

          // ── Search Input ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: domain != null
                    ? 'Search Domain ${domain.number} (${domain.shortName})...'
                    : 'Search tools in this hub...',
                hintStyle: TextStyle(
                  fontSize: 13.5,
                  color: isDark ? AppColors.textMutedDark : const Color(0xFF94A3B8),
                ),
                prefixIcon: const Icon(LucideIcons.search, size: 18, color: Color(0xFF64748B)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                filled: true,
                fillColor: isDark ? AppColors.surfaceDark : Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: primaryColor, width: 1.5),
                ),
              ),
            ),
          ),

          // ── Scrollable Body ──────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                // Domain Header Banner
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: softColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: primaryColor.withValues(alpha: 0.25)),
                        ),
                        child: Icon(domain?.icon ?? LucideIcons.layers, size: 24, color: primaryColor),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (domain != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                margin: const EdgeInsets.only(bottom: 6),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'DOMAIN ${domain.number} OF 15',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                            Text(
                              _title,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                                color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _subtitle,
                              style: TextStyle(
                                fontSize: 12.5,
                                height: 1.4,
                                color: isDark ? AppColors.textMutedDark : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Primary Owned Tools Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Primary Domain Tools (${filteredPrimary.length})',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                      ),
                    ),
                    if (domain != null)
                      Text(
                        'Authoritative Owner',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                if (filteredPrimary.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 36),
                    alignment: Alignment.center,
                    child: Text(
                      'No tools match "$_searchQuery"',
                      style: TextStyle(
                        color: isDark ? AppColors.textMutedDark : const Color(0xFF94A3B8),
                      ),
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredPrimary.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      childAspectRatio: 0.76,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 12,
                    ),
                    itemBuilder: (context, index) {
                      return ToolCard(tool: filteredPrimary[index], compact: true);
                    },
                  ),

                // Cross-Domain Workflow Tools Section
                if (filteredCross.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Cross-Domain Workflow Tools (${filteredCross.length})',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceElevatedDark : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Linked Workflows',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredCross.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      childAspectRatio: 0.76,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 12,
                    ),
                    itemBuilder: (context, index) {
                      return ToolCard(tool: filteredCross[index], compact: true);
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
