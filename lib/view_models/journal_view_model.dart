import 'package:flutter/foundation.dart';
import '../models/journal_entry.dart';
import '../services/database_service.dart';

class JournalViewModel extends ChangeNotifier {
  List<JournalEntry> _entries = [];
  List<JournalEntry> get entries => _entries;

  final DatabaseService _databaseService = DatabaseService();

  Future<void> fetchEntries() async {
    _entries = await _databaseService.getJournalEntries();
    notifyListeners();
  }
}
