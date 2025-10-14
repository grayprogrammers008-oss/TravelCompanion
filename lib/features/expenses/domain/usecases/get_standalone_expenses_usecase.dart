import '../../../../shared/models/expense_model.dart';
import '../repositories/expense_repository.dart';

/// Get standalone expenses (no trip)
class GetStandaloneExpensesUseCase {
  final ExpenseRepository _repository;

  GetStandaloneExpensesUseCase(this._repository);

  Future<List<ExpenseWithSplits>> call() async {
    return await _repository.getStandaloneExpenses();
  }
}
