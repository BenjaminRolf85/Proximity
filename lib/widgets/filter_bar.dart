import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/group.dart';
import '../state/groups_provider.dart';
import '../state/filters_provider.dart';
import '../utils/proximity_utils.dart';

class FilterBar extends ConsumerStatefulWidget {
  const FilterBar({super.key});

  @override
  ConsumerState<FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends ConsumerState<FilterBar> {
  final ScrollController _groupScroll = ScrollController();

  @override
  void dispose() {
    _groupScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groups = ref.watch(groupsProvider);
    final filters = ref.watch(filtersProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 40,
                child: ListView.separated(
                  controller: _groupScroll,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  // include "All" + groups, repeated for pseudo-infinite scroll
                  itemCount: (groups.length + 1) * 1000,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final isAll = index % (groups.length + 1) == 0;
                    if (isAll) {
                      final selectedAll = filters.selectedGroupIds.isEmpty;
                      return FilterChip(
                        avatar: const Icon(Icons.all_inclusive, size: 18),
                        label: const SizedBox.shrink(),
                        selected: selectedAll,
                        showCheckmark: false,
                        onSelected: (_) => ref.read(filtersProvider.notifier).clearGroups(),
                      );
                    }
                    final g = groups[(index % (groups.length + 1)) - 1];
                    final selected = filters.selectedGroupIds.contains(g.id);
                    return FilterChip(
                      avatar: Icon(getGroupIcon(g.type), size: 18),
                      label: const SizedBox.shrink(),
                      selected: selected,
                      showCheckmark: false,
                      onSelected: (_) => ref.read(filtersProvider.notifier).toggleGroup(g.id),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Add group',
              onPressed: () async {
                final name = await showTextInputDialog(
                  context,
                  title: 'Create group',
                  hint: 'Group name',
                );
                if (name != null && name.trim().isNotEmpty) {
                  ref.read(groupsProvider.notifier).addCustomGroup(name.trim());
                }
              },
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        // Distance segmented control removed as requested
      ],
    );
  }
}


