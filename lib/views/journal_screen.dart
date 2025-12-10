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
      appBar: AppBar(title: const Text('Journal (Double Entry)')),
      body: Consumer<JournalViewModel>(
        builder: (context, vm, child) {
          if (vm.journalPages.isEmpty) {
            return const Center(child: Text('No journal entries found.'));
          }
          return ListView.builder(
            itemCount: vm.journalPages.length,
            itemBuilder: (context, index) {
              final page = vm.journalPages[index];
              final header = page['header'];
              final lines = page['lines'] as List<Map<String, dynamic>>;
              final date = DateTime.parse(header['date']);

              return Card(
                margin: const EdgeInsets.all(8.0),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('MMM dd, yyyy - hh:mm a').format(date),
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          Chip(
                            label: Text(header['reference_type'] ?? 'JOURNAL'),
                            visualDensity: VisualDensity.compact,
                          )
                        ],
                      ),
                      Text(
                        header['description'],
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Divider(),
                      // Lines
                      Table(
                        columnWidths: const {
                          0: FlexColumnWidth(2), // Account Name
                          1: FlexColumnWidth(1), // Debit
                          2: FlexColumnWidth(1), // Credit
                        },
                        children: [
                          const TableRow(
                            children: [
                              Text('Account', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('Debit', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right),
                              Text('Credit', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right),
                            ],
                          ),
                          ...lines.map((line) => TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Text(line['account_name']),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Text(
                                  line['debit'] > 0 ? NumberFormat.currency(symbol: '\$').format(line['debit']) : '',
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Text(
                                  line['credit'] > 0 ? NumberFormat.currency(symbol: '\$').format(line['credit']) : '',
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          )),
                        ],
                      ),
                    ],
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
