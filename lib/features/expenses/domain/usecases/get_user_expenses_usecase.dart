import '../../../../shared/models/expense_model.dart';
import '../repositories/expense_repository.dart';

/// Get all expenses for current user
class GetUserExpensesUseCase {
  final ExpenseRepository _repository;

  GetUserExpensesUseCase(this._repository);

  Future<List<ExpenseWithSplits>> call() async {
    return await _repository.getUserExpenses();
  }
}
