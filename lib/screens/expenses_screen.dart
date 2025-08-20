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

  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month, now.day);
  }

  void _showExpenseDialog({ExpenseModel? expenseToEdit}) {
    final formKey = GlobalKey<FormState>();
    final descController =
        TextEditingController(text: expenseToEdit?.description ?? '');
    final amountController = TextEditingController(
        text: expenseToEdit != null
            ? expenseToEdit.amount.toStringAsFixed(2)
            : '');
    String selectedCategory = expenseToEdit?.category ?? 'Alimentación';
    DateTime selectedDate =
        expenseToEdit?.expenseDate.toDate() ?? DateTime.now();
    final bool isEditing = expenseToEdit != null;

    final List<String> expenseCategories = [
      'Alimentación',
      'Medicina',
      'Instalaciones',
      'Transporte',
      'Compra de Ejemplar',
      'Otro'
    ];

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
                        items: expenseCategories
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
                                  lastDate: DateTime.now());
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
                    child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      try {
                        // TODO: Implementar updateExpense en ExpenseService
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
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Error: ${e.toString()}'),
                              backgroundColor: Colors.red));
                      }
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _selectDate(BuildContext context,
      {required bool isStartDate}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (isStartDate ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
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
      appBar: AppBar(title: const Text('Registro de Gastos')),
      floatingActionButton: FloatingActionButton(
          onPressed: _showExpenseDialog,
          child: const Icon(Icons.add),
          tooltip: 'Registrar Gasto'),
      body: Column(
        children: [
          _buildDateFilter(),
          Expanded(
            child: StreamBuilder<List<ExpenseModel>>(
              stream: _expenseService.getExpensesStream(
                  galleraId: activeGalleraId,
                  startDate: _startDate,
                  endDate: _endDate),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) {
                  String errorMessage =
                      'Error al cargar gastos: ${snapshot.error}';
                  if (snapshot.error.toString().contains('requires an index')) {
                    errorMessage =
                        'La base de datos requiere un nuevo índice. Ejecuta la app en modo debug y sigue el enlace en la consola para crearlo.';
                  }
                  return Center(
                      child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child:
                              Text(errorMessage, textAlign: TextAlign.center)));
                }

                final expenses = snapshot.data ?? [];
                final double totalExpenses =
                    expenses.fold(0.0, (sum, item) => sum + item.amount);

                return Column(
                  children: [
                    _buildSummaryCard(totalExpenses),
                    if (expenses.isEmpty)
                      const Expanded(
                          child: Center(
                        child: Text('No hay gastos en el período seleccionado.',
                            style: TextStyle(fontSize: 16, color: Colors.grey)),
                      ))
                    else
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: expenses.length,
                          itemBuilder: (context, index) {
                            final expense = expenses[index];
                            return Dismissible(
                              key: Key(expense.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                  color: Colors.red.shade700,
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  child: const Icon(Icons.delete_forever,
                                      color: Colors.white)),
                              confirmDismiss: (direction) async {
                                final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                            title:
                                                const Text("Confirmar Borrado"),
                                            content: Text(
                                                "¿Seguro que quieres borrar este gasto: \"${expense.description}\"?"),
                                            actions: [
                                              TextButton(
                                                  child: const Text("Cancelar"),
                                                  onPressed: () =>
                                                      Navigator.of(context)
                                                          .pop(false)),
                                              TextButton(
                                                  child: const Text("Borrar"),
                                                  style: TextButton.styleFrom(
                                                      foregroundColor:
                                                          Colors.red),
                                                  onPressed: () =>
                                                      Navigator.of(context)
                                                          .pop(true)),
                                            ]));
                                return confirm ?? false;
                              },
                              onDismissed: (direction) {
                                _expenseService.deleteExpense(
                                    galleraId: activeGalleraId,
                                    expenseId: expense.id);
                              },
                              child: Card(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                child: ListTile(
                                  leading: CircleAvatar(
                                      child: Icon(_getIconForCategory(
                                          expense.category))),
                                  title: Text(expense.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis),
                                  subtitle: Text(expense.category),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                          NumberFormat.currency(
                                                  locale: 'es_MX', symbol: '\$')
                                              .format(expense.amount),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.redAccent)),
                                      Text(
                                          DateFormat('dd/MM/yy').format(
                                              expense.expenseDate.toDate()),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilter() {
    final dateFormat = DateFormat('dd/MM/yyyy');
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Row(
        children: [
          Expanded(
              child: InkWell(
            onTap: () => _selectDate(context, isStartDate: true),
            child: InputDecorator(
              decoration: const InputDecoration(
                  labelText: 'Desde', border: OutlineInputBorder()),
              child: Text(_startDate != null
                  ? dateFormat.format(_startDate!)
                  : 'Seleccionar'),
            ),
          )),
          const SizedBox(width: 8),
          Expanded(
              child: InkWell(
            onTap: () => _selectDate(context, isStartDate: false),
            child: InputDecorator(
              decoration: const InputDecoration(
                  labelText: 'Hasta', border: OutlineInputBorder()),
              child: Text(_endDate != null
                  ? dateFormat.format(_endDate!)
                  : 'Seleccionar'),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(double totalAmount) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Text(
            'TOTAL DE GASTOS (PERÍODO)',
            style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                letterSpacing: 1.2),
          ),
          const SizedBox(height: 8),
          Text(
            NumberFormat.currency(locale: 'es_MX', symbol: '\$')
                .format(totalAmount),
            style: theme.textTheme.displaySmall?.copyWith(
                color: Colors.redAccent, fontWeight: FontWeight.bold),
          ),
        ],
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
