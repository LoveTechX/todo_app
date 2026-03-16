import 'package:flutter/material.dart';

import '../services/search_service.dart';

class GlobalSearchBar extends StatefulWidget {
  const GlobalSearchBar({super.key, required this.searchService});

  final SearchService searchService;

  @override
  State<GlobalSearchBar> createState() => _GlobalSearchBarState();
}

class _GlobalSearchBarState extends State<GlobalSearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.searchService.query);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.searchService,
      builder: (BuildContext context, _) {
        final String query = widget.searchService.query.trim();
        final List<GlobalSearchResult> results = widget.searchService.results;

        return Card(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Search tasks, focus sessions, analytics...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: query.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _controller.clear();
                              widget.searchService.onQueryChanged('');
                            },
                            icon: const Icon(Icons.close),
                            tooltip: 'Clear search',
                          ),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: widget.searchService.onQueryChanged,
                ),
                if (query.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 12),
                  if (widget.searchService.isSearching)
                    const LinearProgressIndicator(minHeight: 2),
                  if (!widget.searchService.isSearching) ...<Widget>[
                    Text(
                      '${results.length} result${results.length == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    if (results.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('No matches found.'),
                      )
                    else
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 240),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: results.length,
                          separatorBuilder: (BuildContext context, int index) =>
                              const Divider(height: 1),
                          itemBuilder: (BuildContext context, int index) {
                            final GlobalSearchResult result = results[index];
                            return ListTile(
                              dense: true,
                              leading: _buildTypeIcon(result.type),
                              title: Text(result.title),
                              subtitle: Text(result.subtitle),
                              trailing: result.trailing == null
                                  ? null
                                  : Text(result.trailing!),
                            );
                          },
                        ),
                      ),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypeIcon(GlobalSearchResultType type) {
    switch (type) {
      case GlobalSearchResultType.task:
        return const Icon(Icons.task_alt_outlined);
      case GlobalSearchResultType.focusSession:
        return const Icon(Icons.timer_outlined);
      case GlobalSearchResultType.analytics:
        return const Icon(Icons.insights_outlined);
    }
  }
}
