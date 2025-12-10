import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/unit_definition.dart';
import '../view_models/unit_view_model.dart';

class GlobalUnitManagerScreen extends StatefulWidget {
  const GlobalUnitManagerScreen({super.key});

  @override
  State<GlobalUnitManagerScreen> createState() => _GlobalUnitManagerScreenState();
}

class _GlobalUnitManagerScreenState extends State<GlobalUnitManagerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UnitViewModel>().fetchUnitDefinitions();
      context.read<UnitViewModel>().fetchBaseUnits();
    });
  }

  void _showAddDialog() {
    final nameController = TextEditingController();
    final baseController = TextEditingController(); // e.g., "Can"
    final factorController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Define New Global Unit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Unit Name (e.g. Pack)'),
            ),
            const SizedBox(height: 16),
            
            Consumer<UnitViewModel>(
              builder: (context, vm, child) {
                return DropdownMenu<String>(
                  controller: baseController,
                  label: const Text('Base Unit Name'),
                  width: 230,
                  dropdownMenuEntries: vm.baseUnits.map((String unit) {
                    return DropdownMenuEntry<String>(
                      value: unit,
                      label: unit,
                    );
                  }).toList(),
                  enableSearch: true,
                  requestFocusOnTap: true,
                );
              }
            ),
            
            const SizedBox(height: 16),
            TextField(
              controller: factorController,
              decoration: const InputDecoration(labelText: 'Factor (e.g. 6)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && 
                  baseController.text.isNotEmpty && 
                  factorController.text.isNotEmpty) {
                
                final def = UnitDefinition(
                  name: nameController.text,
                  baseUnit: baseController.text,
                  factor: double.parse(factorController.text),
                );
                
                context.read<UnitViewModel>().addUnitDefinition(def);
                Navigator.pop(context);
              }
            }, 
            child: const Text('Save')
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Unit Management')),
      body: Consumer<UnitViewModel>(
        builder: (context, vm, child) {
          if (vm.unitDefinitions.isEmpty) {
            return const Center(child: Text('No units defined yet.'));
          }
          return ListView.builder(
            itemCount: vm.unitDefinitions.length,
            itemBuilder: (context, index) {
              final unit = vm.unitDefinitions[index];
              return ListTile(
                title: Text(unit.name),
                subtitle: Text('1 ${unit.name} = ${unit.factor} ${unit.baseUnit}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => vm.deleteUnitDefinition(unit.id!),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
