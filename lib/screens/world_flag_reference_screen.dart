import 'package:flutter/material.dart';

import '../models/world_flag_entity.dart';
import '../widgets/world_flag_art.dart';

class WorldFlagReferenceScreen extends StatefulWidget {
  final WorldFlagReferenceCategory category;
  final List<WorldFlagEntity> entities;

  const WorldFlagReferenceScreen({
    super.key,
    required this.category,
    required this.entities,
  });

  @override
  State<WorldFlagReferenceScreen> createState() =>
      _WorldFlagReferenceScreenState();
}

class _WorldFlagReferenceScreenState extends State<WorldFlagReferenceScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<WorldFlagEntity> get _visibleEntities {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return widget.entities;
    return widget.entities
        .where(
          (entity) =>
              entity.displayNameEn.toLowerCase().contains(query) ||
              entity.aliases.any(
                (alias) => alias.toLowerCase().contains(query),
              ),
        )
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.category.label)),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: Text(
            widget.category.description,
            key: const Key('flag-reference-description'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: TextField(
            key: const Key('flag-reference-search'),
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              isDense: true,
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search flags',
              border: const OutlineInputBorder(),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      key: const Key('flag-reference-clear-search'),
                      tooltip: 'Clear search',
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                      icon: const Icon(Icons.clear),
                    ),
            ),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final entities = _visibleEntities;
              if (entities.isEmpty) {
                return const Center(child: Text('No flags found'));
              }
              final columns = constraints.maxWidth >= 900
                  ? 5
                  : constraints.maxWidth >= 650
                  ? 4
                  : constraints.maxWidth >= 430
                  ? 3
                  : 2;
              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: .92,
                ),
                itemCount: entities.length,
                itemBuilder: (context, index) {
                  final entity = entities[index];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          Expanded(
                            child: WorldFlagArt(
                              entity: entity,
                              semanticsLabel: '${entity.displayNameEn} flag',
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            entity.displayNameEn,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    ),
  );
}
