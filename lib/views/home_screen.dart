import 'package:flutter/material.dart';
import 'pos_screen.dart';
import 'product_list_screen.dart';
import 'journal_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('POS System'),
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildMenuCard(context, 'POS Terminal', Icons.point_of_sale, () {
             Navigator.push(context, MaterialPageRoute(builder: (_) => const POSScreen()));
          }),
          _buildMenuCard(context, 'Products', Icons.inventory, () {
             Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductListScreen()));
          }),
          _buildMenuCard(context, 'Inventory', Icons.warehouse, () {
             // Inventory is basically Product List for now, or a specific stock view
             Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductListScreen()));
          }),
          _buildMenuCard(context, 'Journals', Icons.book, () {
             Navigator.push(context, MaterialPageRoute(builder: (_) => const JournalScreen()));
          }),
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 4.0,
      margin: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48.0, color: Theme.of(context).primaryColor),
            const SizedBox(height: 16.0),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}
