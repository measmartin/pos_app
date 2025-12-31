import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/unit_definition.dart';
import '../view_models/unit_view_model.dart';
import '../widgets/forms/custom_text_field.dart';
import '../widgets/dropdowns/base_unit_dropdown.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/common/spacing.dart';
import '../theme/app_spacing.dart';

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
    final factorController = TextEditingController();
    String? selectedBaseUnit;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final unitViewModel = context.watch<UnitViewModel>();
          
          return AlertDialog(
            title: const Text('Define New Global Unit'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomTextField(
                    controller: nameController,
                    labelText: 'Unit Name (e.g. Pack)',
                  ),
                  const VerticalSpace.lg(),
                  
                  BaseUnitDropdown(
                    selectedUnit: selectedBaseUnit,
                    availableUnits: unitViewModel.baseUnits,
                    onChanged: (unit) {
                      setDialogState(() {
                        selectedBaseUnit = unit;
                      });
                    },
                    labelText: 'Base Unit Name',
                    width: 230,
                  ),
                  
                  const VerticalSpace.lg(),
                  CustomTextField(
                    controller: factorController,
                    labelText: 'Factor (e.g. 6)',
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty && 
                      selectedBaseUnit != null && 
                      factorController.text.isNotEmpty) {
                    
                    final def = UnitDefinition(
                      name: nameController.text,
                      baseUnit: selectedBaseUnit!,
                      factor: double.parse(factorController.text),
                    );
                    
                    context.read<UnitViewModel>().addUnitDefinition(def);
                    Navigator.pop(context);
                  }
                }, 
                child: const Text('Save')
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Unit Management')),
      body: Consumer<UnitViewModel>(
        builder: (context, vm, child) {
          if (vm.unitDefinitions.isEmpty) {
            return EmptyState(
              icon: Icons.straighten,
              message: 'No units defined yet',
              actionLabel: 'Add Unit',
              onAction: _showAddDialog,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            itemCount: vm.unitDefinitions.length,
            itemBuilder: (context, index) {
              final unit = vm.unitDefinitions[index];
              return ListTile(
                leading: const Icon(Icons.straighten),
                title: Text(unit.name),
                subtitle: Text('1 ${unit.name} = ${unit.factor} ${unit.baseUnit}'),
                trailing: IconButton(
                  icon: Icon(
                    Icons.delete,
                    color: theme.colorScheme.error,
                  ),
                  onPressed: () => vm.deleteUnitDefinition(unit.id!),
                  tooltip: 'Delete unit definition',
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        tooltip: 'Add unit definition',
        child: const Icon(Icons.add),
      ),
    );
  }
}
