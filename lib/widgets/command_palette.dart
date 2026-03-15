import 'package:flutter/material.dart';

import '../models/command.dart';

class CommandPalette extends StatefulWidget {
  const CommandPalette({super.key, required this.commands});

  final List<Command> commands;

  @override
  State<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<CommandPalette> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Command> filtered = widget.commands.where((Command command) {
      return command.title.toLowerCase().contains(_query.toLowerCase());
    }).toList();

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search commands',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (String value) {
                setState(() {
                  _query = value;
                });
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 280,
              child: filtered.isEmpty
                  ? const Center(child: Text('No matching commands'))
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (BuildContext context, int index) {
                        final Command command = filtered[index];
                        return ListTile(
                          title: Text(command.title),
                          onTap: () {
                            Navigator.of(context).pop();
                            command.action();
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
