import '../repositories/expense_repository.dart';

/// Delete an expense
class DeleteExpenseUseCase {
  final ExpenseRepository _repository;

  DeleteExpenseUseCase(this._repository);

  Future<void> call(String expenseId) async {
    if (expenseId.isEmpty) {
      throw Exception('Expense ID cannot be empty');
    }

    return await _repository.deleteExpense(expenseId);
  }
}
