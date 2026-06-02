import 'dart:convert';

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_data.dart';
import '../persistence/shared_preferences_provider.dart';
import '../../features/smart_coins/domain/coin_transaction.dart';
import 'user_notifier.dart';

enum CoinLevel { bronze, prata, ouro }

CoinLevel coinLevelOf(int balance) {
  if (balance >= 1500) return CoinLevel.ouro;
  if (balance >= 500) return CoinLevel.prata;
  return CoinLevel.bronze;
}

double coinLevelProgress(int balance) {
  if (balance >= 1500) return 1.0;
  if (balance >= 500) return ((balance - 500) / 1000.0).clamp(0.0, 1.0);
  return (balance / 500.0).clamp(0.0, 1.0);
}

@immutable
class CoinState {
  const CoinState({required this.balance, required this.transactions});

  final int balance;
  final List<CoinTransaction> transactions;

  CoinState copyWith({int? balance, List<CoinTransaction>? transactions}) =>
      CoinState(
        balance: balance ?? this.balance,
        transactions: transactions ?? this.transactions,
      );
}

class CoinNotifier extends Notifier<CoinState> {
  static const _balanceKey = 'lista_smart_coins_balance';
  static const _txKey = 'lista_smart_coins_tx';

  @override
  CoinState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final user = ref.watch(userNotifierProvider);

    final balance = prefs.getInt(_balanceKey) ?? user?.coinBalance ?? 0;

    final rawTx = prefs.getString(_txKey);
    List<CoinTransaction> transactions;
    if (rawTx != null) {
      try {
        final list = jsonDecode(rawTx) as List<dynamic>;
        transactions = list
            .map((e) => CoinTransaction.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        transactions = MockData.initialTransactions;
      }
    } else {
      transactions = MockData.initialTransactions;
    }

    return CoinState(balance: balance, transactions: transactions);
  }

  void addCoins(int amount, String description) {
    final tx = CoinTransaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      description: description,
      amount: amount,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(
      balance: state.balance + amount,
      transactions: [tx, ...state.transactions],
    );
    _persist();
  }

  void spendCoins(int amount, String description) {
    if (amount <= 0) return;
    if (state.balance < amount) return;
    final tx = CoinTransaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      description: description,
      amount: -amount,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(
      balance: state.balance - amount,
      transactions: [tx, ...state.transactions],
    );
    _persist();
  }

  void _persist() {
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setInt(_balanceKey, state.balance);
    prefs.setString(
      _txKey,
      jsonEncode(state.transactions.map((t) => t.toJson()).toList()),
    );
  }
}

final coinProvider = NotifierProvider<CoinNotifier, CoinState>(CoinNotifier.new);
