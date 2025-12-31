import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/journal_view_model.dart';
import '../widgets/journal/journal_entry_card.dart';
import '../widgets/common/empty_state.dart';

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
      appBar: AppBar(title: const Text('Journal (Double Entry)')),
      body: Consumer<JournalViewModel>(
        builder: (context, vm, child) {
          if (vm.journalPages.isEmpty) {
            return const EmptyState(
              icon: Icons.receipt_long_outlined,
              message: 'No journal entries found',
            );
          }
          return ListView.builder(
            itemCount: vm.journalPages.length,
            itemBuilder: (context, index) {
              final page = vm.journalPages[index];
              final header = page['header'] as Map<String, dynamic>;
              final lines = page['lines'] as List<Map<String, dynamic>>;
              final date = DateTime.parse(header['date'] as String);
              final description = header['description'] as String;
              final referenceType = header['reference_type'] as String?;

              return JournalEntryCard(
                date: date,
                description: description,
                referenceType: referenceType,
                lines: lines,
              );
            },
          );
        },
      ),
    );
  }
}
