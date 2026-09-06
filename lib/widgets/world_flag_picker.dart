import 'package:flutter/material.dart';

import '../models/world_flag_entity.dart';
import '../services/world_flag_repository.dart';
import 'world_flag_art.dart';

Future<WorldFlagEntity?> showWorldFlagPicker({
  required BuildContext context,
  String initialWorldFlagId = '',
  WorldFlagRepository? repository,
}) => showDialog<WorldFlagEntity>(
  context: context,
  builder: (_) => WorldFlagPickerDialog(
    initialWorldFlagId: initialWorldFlagId,
    repository: repository,
  ),
);

class WorldFlagPickerDialog extends StatefulWidget {
  final String initialWorldFlagId;
  final WorldFlagRepository? repository;

  const WorldFlagPickerDialog({
    super.key,
    this.initialWorldFlagId = '',
    this.repository,
  });

  @override
  State<WorldFlagPickerDialog> createState() => _WorldFlagPickerDialogState();
}

class _WorldFlagPickerDialogState extends State<WorldFlagPickerDialog> {
  final TextEditingController _search = TextEditingController();
  late final WorldFlagRepository _repository;
  late final Future<List<WorldFlagEntity>> _entities;
  String _query = '';
  int _categoryIndex = 0;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? WorldFlagRepository();
    _entities = _repository.load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<WorldFlagEntity> _visible(List<WorldFlagEntity> all) {
    final category = _categoryIndex == 0
        ? null
        : WorldFlagReferenceCategory.values[_categoryIndex - 1];
    final scoped = category == null
        ? all
        : WorldFlagRepository.referenceFor(all, category);
    return WorldFlagRepository.search(scoped, _query);
  }

  String _codes(WorldFlagEntity entity) => <String?>[
    entity.isoAlpha2,
    entity.isoAlpha3,
    entity.subdivisionCode,
  ].whereType<String>().join(' · ');

  @override
  Widget build(BuildContext context) {
    final height = (MediaQuery.sizeOf(context).height * .72)
        .clamp(360.0, 680.0)
        .toDouble();
    return AlertDialog(
      title: const Text('Choose a World Flag'),
      content: SizedBox(
        width: 760,
        height: height,
        child: FutureBuilder<List<WorldFlagEntity>>(
          future: _entities,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(
                child: Text('World Flags could not be loaded.'),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final entities = _visible(snapshot.data!);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  key: const Key('world-flag-picker-search'),
                  controller: _search,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search by name, alias, ID or ISO code',
                    border: const OutlineInputBorder(),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            key: const Key('world-flag-picker-clear-search'),
                            tooltip: 'Clear search',
                            onPressed: () {
                              _search.clear();
                              setState(() => _query = '');
                            },
                            icon: const Icon(Icons.clear),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  key: const Key('world-flag-picker-category'),
                  initialValue: _categoryIndex,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Flag category',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem(value: 0, child: Text('All Flags')),
                    for (
                      var index = 0;
                      index < WorldFlagReferenceCategory.values.length;
                      index++
                    )
                      DropdownMenuItem(
                        value: index + 1,
                        child: Text(
                          WorldFlagReferenceCategory.values[index].label,
                        ),
                      ),
                  ],
                  onChanged: (value) =>
                      setState(() => _categoryIndex = value ?? 0),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: entities.isEmpty
                      ? const Center(child: Text('No flags found'))
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final columns = constraints.maxWidth >= 700
                                ? 5
                                : constraints.maxWidth >= 520
                                ? 4
                                : constraints.maxWidth >= 360
                                ? 3
                                : 2;
                            return GridView.builder(
                              key: const Key('world-flag-picker-grid'),
                              itemCount: entities.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: columns,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                    childAspectRatio: .82,
                                  ),
                              itemBuilder: (context, index) {
                                final entity = entities[index];
                                final selected =
                                    entity.id == widget.initialWorldFlagId;
                                final codes = _codes(entity);
                                return Card(
                                  key: ValueKey(
                                    'world-flag-option-${entity.id}',
                                  ),
                                  color: selected
                                      ? Theme.of(
                                          context,
                                        ).colorScheme.secondaryContainer
                                      : null,
                                  clipBehavior: Clip.antiAlias,
                                  child: InkWell(
                                    onTap: () => Navigator.pop(context, entity),
                                    child: Padding(
                                      padding: const EdgeInsets.all(7),
                                      child: Column(
                                        children: [
                                          Expanded(
                                            child: WorldFlagArt(
                                              entity: entity,
                                              semanticsLabel:
                                                  '${entity.displayNameEn} flag',
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            entity.displayNameEn,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          if (codes.isNotEmpty)
                                            Text(
                                              codes,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodySmall,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
