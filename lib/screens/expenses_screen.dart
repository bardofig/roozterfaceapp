// lib/screens/expenses_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:roozterfaceapp/models/expense_model.dart';
import 'package:roozterfaceapp/providers/user_data_provider.dart';
import 'package:roozterfaceapp/services/expense_service.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final ExpenseService _expenseService = ExpenseService();

  final List<String> _expenseCategories = [
    'Alimentación',
    'Medicina',
    'Instalaciones',
    'Transporte',
    'Compra de Ejemplar',
    'Otro'
  ];

  void _showExpenseDialog({ExpenseModel? expenseToEdit}) {
    final formKey = GlobalKey<FormState>();
    final descController =
        TextEditingController(text: expenseToEdit?.description ?? '');
    final amountController = TextEditingController(
        text: expenseToEdit?.amount.toStringAsFixed(2) ?? '');
    String selectedCategory = expenseToEdit?.category ?? 'Alimentación';
    DateTime selectedDate =
        expenseToEdit?.expenseDate.toDate() ?? DateTime.now();
    final bool isEditing = expenseToEdit != null;

    showDialog(
      context: context,
      builder: (context) {
        final activeGalleraId =
            Provider.of<UserDataProvider>(context, listen: false)
                .userProfile!
                .activeGalleraId!;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'Editar Gasto' : 'Añadir Nuevo Gasto'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedCategory,
                        decoration:
                            const InputDecoration(labelText: 'Categoría'),
                        items: _expenseCategories
                            .map((cat) =>
                                DropdownMenuItem(value: cat, child: Text(cat)))
                            .toList(),
                        onChanged: (value) {
                          if (value != null)
                            setDialogState(() => selectedCategory = value);
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: descController,
                        decoration:
                            const InputDecoration(labelText: 'Descripción *'),
                        textCapitalization: TextCapitalization.sentences,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'La descripción es obligatoria'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: amountController,
                        decoration: const InputDecoration(
                            labelText: 'Monto *', prefixText: '\$ '),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty)
                            return 'El monto es obligatorio';
                          if (double.tryParse(v) == null ||
                              double.parse(v) <= 0)
                            return 'Introduce un monto válido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                              child: Text(
                                  'Fecha: ${DateFormat('dd/MM/yyyy').format(selectedDate)}')),
                          TextButton(
                            child: const Text('Cambiar'),
                            onPressed: () async {
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (pickedDate != null) {
                                setDialogState(() => selectedDate = pickedDate);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      try {
                        // El servicio para 'update' no existe aún, usaremos add por ahora.
                        // En una futura iteración se añadiría update a ExpenseService.
                        await _expenseService.addExpense(
                          galleraId: activeGalleraId,
                          date: selectedDate,
                          category: selectedCategory,
                          description: descController.text.trim(),
                          amount: double.parse(amountController.text),
                        );
                        if (mounted) Navigator.of(context).pop();
                      } catch (e) {
                        if (mounted)
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Error: ${e.toString()}'),
                                backgroundColor: Colors.red),
                          );
                      }
                    }
                  },
                  child: const Text('Guardar Gasto'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeGalleraId =
        Provider.of<UserDataProvider>(context).userProfile?.activeGalleraId;
    if (activeGalleraId == null) {
      return Scaffold(
          appBar: AppBar(title: const Text('Registro de Gastos')),
          body: const Center(child: Text('No hay gallera activa')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Gastos'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showExpenseDialog,
        child: const Icon(Icons.add),
        tooltip: 'Registrar Gasto',
      ),
      body: StreamBuilder<List<ExpenseModel>>(
        stream: _expenseService.getExpensesStream(activeGalleraId),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return Center(child: Text('Error: ${snapshot.error}'));

          final expenses = snapshot.data!;
          if (expenses.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                    'No has registrado ningún gasto.\nPresiona el botón "+" para empezar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.grey)),
              ),
            );
          }

          return ListView.builder(
            itemCount: expenses.length,
            itemBuilder: (context, index) {
              final expense = expenses[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(_getIconForCategory(expense.category)),
                  ),
                  title: Text(expense.description),
                  subtitle: Text(expense.category),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        NumberFormat.currency(locale: 'es_MX', symbol: '\$')
                            .format(expense.amount),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                      Text(
                        DateFormat('dd/MM/yy')
                            .format(expense.expenseDate.toDate()),
                        style: Theme.of(context).textTheme.bodySmall,
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

  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'Alimentación':
        return Icons.food_bank_outlined;
      case 'Medicina':
        return Icons.medical_services_outlined;
      case 'Instalaciones':
        return Icons.construction_outlined;
      case 'Transporte':
        return Icons.local_shipping_outlined;
      case 'Compra de Ejemplar':
        return Icons.shopping_cart_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }
}
