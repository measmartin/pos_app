import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../view_models/journal_view_model.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JournalViewModel>().fetchEntries();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Journal Entries')),
      body: Consumer<JournalViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.entries.isEmpty) {
            return const Center(child: Text('No journal entries yet.'));
          }
          return ListView.builder(
            itemCount: viewModel.entries.length,
            itemBuilder: (context, index) {
              final entry = viewModel.entries[index];
              final isDebit = entry.type == 'DEBIT';
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isDebit ? Colors.green[100] : Colors.red[100],
                    child: Text(entry.type[0], 
                      style: TextStyle(color: isDebit ? Colors.green : Colors.red)),
                  ),
                  title: Text(entry.description),
                  subtitle: Text(DateFormat('yyyy-MM-dd HH:mm').format(entry.date)),
                  trailing: Text(
                    '\$${entry.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDebit ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
