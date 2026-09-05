import 'package:flutter/material.dart';

import '../services/audit_code_registry.dart';

class AuditCodesScreen extends StatefulWidget {
  const AuditCodesScreen({super.key});

  @override
  State<AuditCodesScreen> createState() => _AuditCodesScreenState();
}

class _AuditCodesScreenState extends State<AuditCodesScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final definitions = AuditCodeRegistry.search(_searchController.text);
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
                  child: Text(
                    '${definitions.length} of '
                    '${AuditCodeRegistry.definitions.length} Audit codes',
                    key: const ValueKey('audit-code-result-count'),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: definitions.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Text(
                            'Errors block actions that require a valid Audit. '
                            'Warnings and Info provide review guidance. '
                            'Draft workflows retain their existing validation rules. '
                            'GENERAL is reserved for unexpected, unclassified '
                            'findings; use the severity and message shown with '
                            'that finding. Known rules below always use specific codes.',
                          ),
                        );
                      }
                      final definition = definitions[index - 1];
                      return Card(
                        key: ValueKey('audit-code-${definition.code}'),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SelectableText(
                                definition.code,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              _Detail('Severity', definition.severityLabel),
                              _Detail('Scope', definition.scope),
                              _Detail('Meaning', definition.meaning),
                              _Detail('Trigger condition', definition.trigger),
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
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
