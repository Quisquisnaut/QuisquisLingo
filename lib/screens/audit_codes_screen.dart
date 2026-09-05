import 'package:flutter/material.dart';

import '../services/audit_code_registry.dart';

class AuditCodesScreen extends StatefulWidget {
  const AuditCodesScreen({super.key});

  @override
  State<AuditCodesScreen> createState() => _AuditCodesScreenState();
}

class _AuditCodesScreenState extends State<AuditCodesScreen> {
  final _searchController = TextEditingController();
  final _selectedSeverities = AuditSeverity.values.toSet();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matches = AuditCodeRegistry.search(_searchController.text);
    final definitions = [
      for (final severity in AuditSeverity.values)
        ...matches.where(
          (definition) =>
              definition.severity == severity &&
              _selectedSeverities.contains(severity),
        ),
    ];
    final groups = [
      for (final severity in AuditSeverity.values)
        if (_selectedSeverities.contains(severity))
          (
            severity: severity,
            definitions: definitions
                .where((definition) => definition.severity == severity)
                .toList(growable: false),
          ),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Audit Codes')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Search codes and guidance',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              onPressed: () =>
                                  setState(_searchController.clear),
                              icon: const Icon(Icons.clear),
                            ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final severity in AuditSeverity.values)
                        FilterChip(
                          key: ValueKey('audit-code-filter-${severity.name}'),
                          label: Text(_severityHeading(severity)),
                          selected: _selectedSeverities.contains(severity),
                          onSelected: (selected) => setState(() {
                            if (selected) {
                              _selectedSeverities.add(severity);
                            } else {
                              _selectedSeverities.remove(severity);
                            }
                          }),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '${definitions.length} of '
                    '${AuditCodeRegistry.definitions.length} Audit codes',
                    key: const ValueKey('audit-code-result-count'),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      for (final group in groups)
                        if (group.definitions.isNotEmpty) ...[
                          Padding(
                            key: ValueKey(
                              'audit-code-heading-${group.severity.name}',
                            ),
                            padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
                            child: Text(
                              _severityHeading(group.severity),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          for (final definition in group.definitions)
                            Card(
                              key: ValueKey('audit-code-${definition.code}'),
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SelectableText(
                                      definition.code,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    _Detail(
                                      'Severity',
                                      definition.severityLabel,
                                    ),
                                    _Detail('Scope', definition.scope),
                                    _Detail('Meaning', definition.meaning),
                                    _Detail(
                                      'Trigger condition',
                                      definition.trigger,
                                    ),
                                    _Detail(
                                      'What to check or do',
                                      definition.creatorAction,
                                    ),
                                    _Detail(
                                      'Blocking',
                                      definition.blocking ? 'Yes' : 'No',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _severityHeading(AuditSeverity severity) => switch (severity) {
    AuditSeverity.error => 'Errors',
    AuditSeverity.warning => 'Warnings',
    AuditSeverity.info => 'Info',
  };
}

class _Detail extends StatelessWidget {
  const _Detail(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          TextSpan(text: value),
        ],
      ),
    ),
  );
}
