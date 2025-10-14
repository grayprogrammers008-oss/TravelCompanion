import '../../../../shared/models/expense_model.dart';
import '../repositories/expense_repository.dart';

/// Create a new expense
class CreateExpenseUseCase {
  final ExpenseRepository _repository;

  CreateExpenseUseCase(this._repository);

  Future<ExpenseModel> call({
    String? tripId,
    required String title,
    String? description,
    required double amount,
    String? category,
    required String paidBy,
    required List<String> splitWith,
    String splitType = 'equal',
    DateTime? transactionDate,
  }) async {
    // Validation
    if (title.trim().isEmpty) {
      throw Exception('Title cannot be empty');
    }

    if (amount <= 0) {
      throw Exception('Amount must be greater than 0');
    }

    if (splitWith.isEmpty) {
      throw Exception('Must split with at least one person');
    }

    return await _repository.createExpense(
      tripId: tripId,
      title: title,
      description: description,
      amount: amount,
      category: category,
      paidBy: paidBy,
      splitWith: splitWith,
      splitType: splitType,
      transactionDate: transactionDate,
    );
  }
}
