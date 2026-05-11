import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../widgets/app_widgets.dart';
import '../widgets/cat_room_scene.dart';
import 'profile_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.user,
    required this.cat,
    required this.finance,
    required this.onFinanceChanged,
    required this.onUserChanged,
    required this.onCatChanged,
    required this.onCatAndFinanceChanged,
    required this.onFriendSearch,
    required this.incomingFriendRequests,
    required this.onFriendRequested,
    required this.onFriendRequestAccepted,
    required this.onFriendRequestDeclined,
    required this.onSignOut,
  });

  final GXUser user;
  final CatProfile cat;
  final FinanceState finance;
  final ValueChanged<FinanceState> onFinanceChanged;
  final ValueChanged<GXUser> onUserChanged;
  final ValueChanged<CatProfile> onCatChanged;
  final Future<void> Function(CatProfile cat, FinanceState finance) onCatAndFinanceChanged;
  final Future<CatFriend?> Function(String query) onFriendSearch;
  final Stream<List<FriendRequest>> incomingFriendRequests;
  final Future<void> Function(CatFriend friend) onFriendRequested;
  final Future<void> Function(FriendRequest request) onFriendRequestAccepted;
  final Future<void> Function(FriendRequest request) onFriendRequestDeclined;
  final VoidCallback onSignOut;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with TickerProviderStateMixin {
  late final AnimationController _catController;
  late final AnimationController _heartController;
  late final TextEditingController _friendSearchController;
  Timer? _activityTimer;
  bool _showHearts = false;
  bool _friendLoading = false;
  CatFriend? _friendPreview;
  CatProfile? _localCat;
  FinanceState? _localFinance;
  CatActivity _activity = CatActivity.idle;
  int _selectedTab = 0;
  final math.Random _activityRandom = math.Random();

  @override
  void initState() {
    super.initState();
    _catController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
    _heartController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _friendSearchController = TextEditingController();
    _activityTimer = Timer.periodic(const Duration(seconds: 6), (_) => _rotateActivity());
  }

  @override
  void dispose() {
    _activityTimer?.cancel();
    _catController.dispose();
    _heartController.dispose();
    _friendSearchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant HomeShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_localCat != null && _sameCat(widget.cat, _localCat!)) {
      _localCat = null;
    }
    if (_localFinance != null &&
        widget.finance.meowPoints == _localFinance!.meowPoints &&
        widget.finance.transactions.length == _localFinance!.transactions.length &&
        widget.finance.levelXp == _localFinance!.levelXp) {
      _localFinance = null;
    }
  }

  CatProfile get _cat => _localCat ?? widget.cat;
  FinanceState get _finance => _localFinance ?? widget.finance;

  bool _sameCat(CatProfile first, CatProfile second) {
    if (first.name != second.name ||
        first.breed != second.breed ||
        first.breedIndex != second.breedIndex ||
        first.accessory != second.accessory ||
        first.ownedItems.length != second.ownedItems.length) {
      return false;
    }
    for (var i = 0; i < first.ownedItems.length; i++) {
      if (first.ownedItems[i] != second.ownedItems[i]) return false;
    }
    return true;
  }

  void _saveCatPreview(CatProfile cat) {
    setState(() => _localCat = cat);
    widget.onCatChanged(cat);
  }

  void _saveCatAndFinancePreview(CatProfile cat, FinanceState finance) {
    setState(() {
      _localCat = cat;
      _localFinance = finance;
    });
    unawaited(
      widget.onCatAndFinanceChanged(cat, finance).catchError((error) {
        if (!mounted) return;
        _showSnack('Could not save purchase: $error');
      }),
    );
  }

  void _setFinance(FinanceState next) {
    final oldLevel = _finance.level;
    setState(() => _localFinance = next);
    widget.onFinanceChanged(next);
    if (next.level > oldLevel) {
      final unlocked = [
        for (var level = oldLevel + 1; level <= next.level; level++) FinanceState.rewardForLevel(level),
      ].where((item) => item != 'No item yet').toList();
      if (unlocked.isNotEmpty) {
        _showSnack('Level ${next.level} unlocked: ${unlocked.last}.');
      } else {
        _showSnack('Level ${next.level} unlocked.');
      }
    }
  }

  void _rotateActivity() {
    const activities = [
      CatActivity.idle,
      CatActivity.play,
      CatActivity.sleep,
      CatActivity.eat,
      CatActivity.idle,
    ];
    final choices = activities.where((activity) => activity != _activity).toList();
    final next = choices[_activityRandom.nextInt(choices.length)];
    if (mounted) setState(() => _activity = next);
  }

  void _recordSaving(String label, double amount, IconData icon) {
    final tx = List<GXTransaction>.of(_finance.transactions)
      ..insert(0, GXTransaction(label, amount, icon, true));
    _setFinance(
      _finance.copyWith(
        savedThisWeek: _finance.savedThisWeek + amount,
        meowPoints: _finance.meowPoints + (amount * 2).round(),
        levelXp: _finance.levelXp + amount.round(),
        streak: _finance.streak + 1,
        resilienceDays: _finance.resilienceDays + 1,
        emergencyFundPercent: math.min(100, _finance.emergencyFundPercent + math.max(1, (amount / 20).round())),
        overrideMood: CatMood.neutral,
        transactions: tx,
      ),
    );
    setState(() => _activity = CatActivity.eat);
    _showTreatAnimation();
  }

  void _recordSpending(String label, double amount, IconData icon, {bool bnpl = false}) {
    final tx = List<GXTransaction>.of(_finance.transactions)
      ..insert(0, GXTransaction(label, amount, icon, false));
    _setFinance(
      _finance.copyWith(
        spentThisWeek: _finance.spentThisWeek + amount,
        levelXp: math.max(0, _finance.levelXp - (bnpl ? amount / 2 : amount / 10).round()),
        streak: bnpl ? math.max(0, _finance.streak - 2) : _finance.streak,
        overrideMood: bnpl ? CatMood.hissing : _finance.overrideMood,
        transactions: tx,
      ),
    );
    setState(() => _activity = bnpl ? CatActivity.idle : CatActivity.play);
    if (bnpl) _showSnack('BNPL Hiss activated: ${_cat.name} spotted a debt trap.');
  }

  FinanceState _financeWithoutTransaction(
    GXTransaction transaction, {
    required FinanceState base,
    required List<GXTransaction> transactions,
  }) {
    if (transaction.positive) {
      return base.copyWith(
        savedThisWeek: math.max(0, base.savedThisWeek - transaction.amount),
        meowPoints: math.max(0, base.meowPoints - (transaction.amount * 2).round()),
        levelXp: math.max(0, base.levelXp - transaction.amount.round()),
        emergencyFundPercent: math.max(0, base.emergencyFundPercent - math.max(1, (transaction.amount / 20).round())),
        transactions: transactions,
      );
    }
    return base.copyWith(
      spentThisWeek: math.max(0, base.spentThisWeek - transaction.amount),
      levelXp: base.levelXp + (transaction.amount / 10).round(),
      transactions: transactions,
    );
  }

  FinanceState _financeWithTransaction(GXTransaction transaction, {required FinanceState base, required List<GXTransaction> transactions}) {
    if (transaction.positive) {
      return base.copyWith(
        savedThisWeek: base.savedThisWeek + transaction.amount,
        meowPoints: base.meowPoints + (transaction.amount * 2).round(),
        levelXp: base.levelXp + transaction.amount.round(),
        emergencyFundPercent: math.min(100, base.emergencyFundPercent + math.max(1, (transaction.amount / 20).round())),
        transactions: transactions,
      );
    }
    return base.copyWith(
      spentThisWeek: base.spentThisWeek + transaction.amount,
      levelXp: math.max(0, base.levelXp - (transaction.amount / 10).round()),
      transactions: transactions,
    );
  }

  void _deleteTransaction(int index) {
    final transactions = List<GXTransaction>.of(_finance.transactions);
    if (index < 0 || index >= transactions.length) return;
    final removed = transactions.removeAt(index);
    _setFinance(_financeWithoutTransaction(removed, base: _finance, transactions: transactions));
    _showSnack('Transaction deleted.');
  }

  Future<void> _editTransaction(int index) async {
    final transactions = List<GXTransaction>.of(_finance.transactions);
    if (index < 0 || index >= transactions.length) return;
    final original = transactions[index];
    final titleController = TextEditingController(text: original.title);
    final amountController = TextEditingController(text: original.amount.toStringAsFixed(0));
    var positive = original.positive;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(18, 6, 18, MediaQuery.viewInsetsOf(context).bottom + 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Edit Transaction', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 14),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: true, label: Text('Saving'), icon: Icon(Icons.savings_rounded)),
                      ButtonSegment(value: false, label: Text('Spending'), icon: Icon(Icons.shopping_bag_rounded)),
                    ],
                    selected: {positive},
                    onSelectionChanged: (value) => setSheetState(() => positive = value.first),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title', prefixIcon: Icon(Icons.edit_rounded)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(prefixText: 'RM ', labelText: 'Amount'),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: () {
                      final amount = double.tryParse(amountController.text.trim()) ?? original.amount;
                      final title = titleController.text.trim().isEmpty ? original.title : titleController.text.trim();
                      final updated = GXTransaction(
                        title,
                        amount.clamp(0, 99999).toDouble(),
                        positive ? Icons.savings_rounded : Icons.shopping_bag_rounded,
                        positive,
                      );
                      final withoutOriginal = List<GXTransaction>.of(transactions)..removeAt(index);
                      final base = _financeWithoutTransaction(original, base: _finance, transactions: withoutOriginal);
                      final withUpdated = List<GXTransaction>.of(withoutOriginal)..insert(index, updated);
                      _setFinance(_financeWithTransaction(updated, base: base, transactions: withUpdated));
                      Navigator.pop(context);
                      _showSnack('Transaction updated.');
                    },
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Save changes'),
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openSavingSheet() async {
    await _showAmountSheet(
      title: 'Saving',
      icon: Icons.savings_rounded,
      color: const Color(0xFF18A999),
      initialAmount: 20,
      choices: const [
        _MoneyChoice('Round-up feed', Icons.restaurant_rounded, 5),
        _MoneyChoice('GX Pocket treat', Icons.account_balance_wallet_rounded, 20),
        _MoneyChoice('Emergency fund', Icons.shield_rounded, 50),
        _MoneyChoice('Catnip interest', Icons.auto_awesome_rounded, 8),
      ],
      onSubmit: (choice, amount) => _recordSaving(choice.label, amount, choice.icon),
    );
  }

  Future<void> _openSpendingSheet() async {
    await _showAmountSheet(
      title: 'Spending',
      icon: Icons.shopping_bag_rounded,
      color: const Color(0xFFE63946),
      initialAmount: 15,
      choices: const [
        _MoneyChoice('Boba gulp', Icons.local_drink_rounded, 15),
        _MoneyChoice('Food run', Icons.ramen_dining_rounded, 18),
        _MoneyChoice('Transport', Icons.directions_bus_rounded, 12),
        _MoneyChoice('BNPL fashion checkout', Icons.warning_rounded, 200, bnpl: true),
      ],
      onSubmit: (choice, amount) => _recordSpending(choice.label, amount, choice.icon, bnpl: choice.bnpl),
    );
  }

  Future<void> _showAmountSheet({
    required String title,
    required IconData icon,
    required Color color,
    required double initialAmount,
    required List<_MoneyChoice> choices,
    required void Function(_MoneyChoice choice, double amount) onSubmit,
  }) {
    var selected = choices.first;
    var amount = initialAmount;
    final controller = TextEditingController(text: initialAmount.toStringAsFixed(0));

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void setAmount(double value) {
              setSheetState(() {
                amount = value;
                controller.text = value.toStringAsFixed(0);
              });
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(18, 6, 18, MediaQuery.viewInsetsOf(context).bottom + 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(backgroundColor: color, foregroundColor: Colors.white, child: Icon(icon)),
                      const SizedBox(width: 12),
                      Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final choice in choices)
                        ChoiceChip(
                          avatar: Icon(choice.icon, size: 18),
                          label: Text(choice.label),
                          selected: selected == choice,
                          onSelected: (_) {
                            setSheetState(() => selected = choice);
                            setAmount(choice.amount);
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(prefixText: 'RM ', labelText: 'Amount'),
                    onChanged: (value) => amount = double.tryParse(value) ?? amount,
                  ),
                  Slider(
                    value: amount.clamp(1, 500),
                    min: 1,
                    max: 500,
                    divisions: 499,
                    label: 'RM${amount.round()}',
                    onChanged: setAmount,
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onSubmit(selected, amount);
                    },
                    icon: const Icon(Icons.check_rounded),
                    label: Text('Confirm RM${amount.toStringAsFixed(2)}'),
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  int get _currentWeeklyReportKey {
    final now = DateTime.now();
    final firstDayOfYear = DateTime(now.year);
    final dayOfYear = now.difference(firstDayOfYear).inDays + 1;
    final week = ((dayOfYear + firstDayOfYear.weekday - 2) / 7).floor() + 1;
    return now.year * 100 + week;
  }

  bool get _weeklyReportCompleted => _finance.lastWeeklyReportKey == _currentWeeklyReportKey;

  int _weeklyReportReward(int score) {
    if (score >= 90) return 55;
    if (score >= 80) return 45;
    if (score >= 70) return 35;
    if (score >= 55) return 25;
    return 15;
  }

  void _claimWeeklyReport({required int score}) {
    if (_finance.lastWeeklyReportKey == _currentWeeklyReportKey) {
      _showSnack('Weekly checkup already completed this week.');
      return;
    }
    final reward = _weeklyReportReward(score);
    final tx = List<GXTransaction>.of(_finance.transactions)
      ..insert(0, GXTransaction('Weekly checkup reviewed', 0, Icons.fact_check, true));
    _setFinance(
      _finance.copyWith(
        reportsReviewed: _finance.reportsReviewed + 1,
        lastWeeklyReportKey: _currentWeeklyReportKey,
        meowPoints: _finance.meowPoints + reward,
        overrideMood: CatMood.neutral,
        transactions: tx,
      ),
    );
    _showSnack('Weekly checkup complete. Reward earned based on performance.');
  }

  void _openWeeklyReport() {
    final alreadyCompleted = _finance.lastWeeklyReportKey == _currentWeeklyReportKey;
    final savingMet = _finance.savedThisWeek >= _finance.weeklyGoal;
    final budgetMet = _finance.spentThisWeek <= _finance.weeklyBudget;
    final hasRisk = _finance.mood == CatMood.hissing || _finance.spentThisWeek > _finance.weeklyBudget;
    final score = [
      if (savingMet) 38 else (_finance.savingsProgress * 38).round(),
      if (budgetMet) 34 else math.max(0, (34 * (1 - ((_finance.spentThisWeek - _finance.weeklyBudget) / _finance.weeklyBudget).clamp(0, 1))).round()),
      if (!hasRisk) 18 else 6,
      math.min(10, _finance.streak),
    ].fold<int>(0, (total, value) => total + value);
    final grade = score >= 85
        ? 'A'
        : score >= 70
            ? 'B'
            : score >= 55
                ? 'C'
                : 'D';
    final reaction = savingMet && budgetMet
        ? '${_cat.name} is proud and purring.'
        : savingMet
            ? '${_cat.name} likes the saving, but spotted budget scratches.'
            : budgetMet
                ? '${_cat.name} stayed calm, but wants more saving treats.'
                : '${_cat.name} found debt fleas to clean up.';
    final nextAction = !savingMet
        ? 'Save RM${(_finance.weeklyGoal - _finance.savedThisWeek).clamp(0, 999).toStringAsFixed(0)} more before week end.'
        : !budgetMet
            ? 'Move small spending to GX Pocket and pause one non-essential buy.'
            : _finance.emergencyFundPercent < 100
                ? 'Put extra money into emergency fund.'
                : 'Keep the streak alive next week.';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(18, 6, 18, MediaQuery.viewInsetsOf(context).bottom + 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFFEAF8F5),
                    foregroundColor: const Color(0xFF087E6F),
                    child: Text(grade, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Weekly Checkup', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 2),
                        Text(reaction, style: const TextStyle(color: Colors.black54)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _ReportMetric(
                    icon: Icons.savings_rounded,
                    label: 'Savings',
                    value: 'RM${_finance.savedThisWeek.toStringAsFixed(0)} / RM${_finance.weeklyGoal.toStringAsFixed(0)}',
                    good: savingMet,
                  ),
                  _ReportMetric(
                    icon: Icons.shopping_bag_rounded,
                    label: 'Spending',
                    value: 'RM${_finance.spentThisWeek.toStringAsFixed(0)} / RM${_finance.weeklyBudget.toStringAsFixed(0)}',
                    good: budgetMet,
                  ),
                  _ReportMetric(
                    icon: Icons.warning_rounded,
                    label: 'Risk',
                    value: hasRisk ? 'Needs care' : 'Clean',
                    good: !hasRisk,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7E6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE8E1D8)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.flag_rounded, color: Color(0xFF7C3AED)),
                      const SizedBox(width: 10),
                      Expanded(child: Text(nextAction, style: const TextStyle(fontWeight: FontWeight.w800))),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: alreadyCompleted
                    ? null
                    : () {
                        Navigator.pop(context);
                        _claimWeeklyReport(score: score);
                      },
                icon: Icon(alreadyCompleted ? Icons.lock_rounded : Icons.redeem_rounded),
                label: Text(alreadyCompleted ? 'Completed this week' : 'Complete checkup'),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _buyAccessory(String accessory, int cost) {
    final cat = _cat;
    final shopItem = _shopItemFor(accessory);
    if (shopItem != null && _finance.level < shopItem.minLevel) {
      _showSnack('${shopItem.name} unlocks at level ${shopItem.minLevel}.');
      return;
    }
    final owned = cat.ownedItems.contains(accessory);
    if (!owned && _finance.meowPoints < cost) {
      _showSnack('Not enough Meow-Points yet.');
      return;
    }
    final equipped = _equippedItems(cat.accessory);
    final alreadyEquipped = equipped.contains(accessory);
    final shouldEquip = !alreadyEquipped && equipped.length < 2;
    final nextEquipped = shouldEquip ? [...equipped, accessory] : equipped;
    final nextCat = cat.copyWith(
      accessory: _accessoryLabel(nextEquipped),
      ownedItems: owned ? cat.ownedItems : [...cat.ownedItems, accessory],
    );
    final nextFinance = owned ? _finance : _finance.copyWith(meowPoints: _finance.meowPoints - cost);
    _saveCatAndFinancePreview(nextCat, nextFinance);
    if (!owned && !shouldEquip) {
      _showSnack('$accessory bought. Unequip one item before wearing it.');
    } else if (alreadyEquipped) {
      _showSnack('$accessory is already equipped.');
    } else if (!shouldEquip) {
      _showSnack('Only two items can be equipped at the same time.');
    } else {
      _showSnack(owned ? '$accessory equipped.' : '$accessory bought and equipped.');
    }
  }

  void _openInventoryBag() {
    var sheetEquipped = _equippedItems(_cat.accessory);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final ownedItems = _inventoryItems(_cat.ownedItems);

            void toggleItem(String item) {
              if (sheetEquipped.contains(item)) {
                sheetEquipped = sheetEquipped.where((equippedItem) => equippedItem != item).toList();
                _saveCatPreview(_cat.copyWith(accessory: _accessoryLabel(sheetEquipped)));
                _showSnack('$item unequipped.');
              } else if (sheetEquipped.length >= 2) {
                _showSnack('Only two items can be equipped at the same time.');
              } else {
                sheetEquipped = [...sheetEquipped, item];
                _saveCatPreview(_cat.copyWith(accessory: _accessoryLabel(sheetEquipped)));
                _showSnack('$item equipped.');
              }
              setSheetState(() {});
            }

            return Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Color(0xFFEAF8F5),
                        foregroundColor: Color(0xFF087E6F),
                        child: Icon(Icons.shopping_bag_rounded),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Inventory Bag', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                            const SizedBox(height: 2),
                            Text(
                              sheetEquipped.isEmpty ? 'Equip up to 2 bought items' : 'Equipped: ${sheetEquipped.join(', ')}',
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Unequip all',
                        onPressed: sheetEquipped.isEmpty
                            ? null
                            : () {
                                sheetEquipped = [];
                                _saveCatPreview(_cat.copyWith(accessory: 'No item'));
                                _showSnack('All items unequipped.');
                                setSheetState(() {});
                              },
                        icon: const Icon(Icons.remove_circle_outline_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (ownedItems.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Text('Your bag is empty. Buy items from the Meow-Points Shop first.'),
                    )
                  else
                    SizedBox(
                      height: math.min(330, MediaQuery.sizeOf(context).height * .48),
                      child: GridView.builder(
                        shrinkWrap: true,
                        itemCount: ownedItems.length,
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 150,
                          mainAxisExtent: 142,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemBuilder: (context, index) {
                          final item = ownedItems[index];
                          return _InventoryItemTile(
                            item: item,
                            equipped: sheetEquipped.contains(item),
                            disabled: sheetEquipped.length >= 2 && !sheetEquipped.contains(item),
                            onTap: () => toggleItem(item),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _sendNudge(int index) {
    final friends = List<CatFriend>.of(_finance.friends);
    friends[index] = friends[index].copyWith(score: math.min(100, friends[index].score + 8));
    _setFinance(_finance.copyWith(friends: friends, meowPoints: _finance.meowPoints + 8));
    _showSnack('Savings nudge sent.');
  }

  Future<void> _findFriend() async {
    final query = _friendSearchController.text.trim();
    if (query.isEmpty) {
      _showSnack('Enter a friend name or user ID.');
      return;
    }
    setState(() {
      _friendLoading = true;
      _friendPreview = null;
    });
    try {
      final friend = await widget.onFriendSearch(query);
      if (friend == null) {
        _showSnack('No cafe profile found for "$query".');
        return;
      }
      setState(() => _friendPreview = friend);
    } catch (error) {
      _showSnack('Could not search friend: $error');
    } finally {
      if (mounted) setState(() => _friendLoading = false);
    }
  }

  Future<void> _requestFriend(CatFriend friend) async {
    setState(() => _friendLoading = true);
    try {
      await widget.onFriendRequested(friend);
      _friendSearchController.clear();
      setState(() => _friendPreview = null);
      _showSnack('Friend request sent to ${friend.owner}.');
    } catch (error) {
      _showSnack('Could not send request: $error');
    } finally {
      if (mounted) setState(() => _friendLoading = false);
    }
  }

  Future<void> _handleRequest(FriendRequest request, {required bool accept}) async {
    try {
      if (accept) {
        await widget.onFriendRequestAccepted(request);
        _showSnack('${request.fromFriend.owner} joined your cafe.');
      } else {
        await widget.onFriendRequestDeclined(request);
        _showSnack('Friend request declined.');
      }
    } catch (error) {
      _showSnack('Could not update request: $error');
    }
  }

  void _showTreatAnimation() {
    setState(() => _showHearts = true);
    _heartController.forward(from: 0).whenComplete(() {
      if (mounted) setState(() => _showHearts = false);
    });
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _dashboard(),
      _insights(),
      _catCafe(),
      ProfileScreen(
        user: widget.user,
        cat: _cat,
        finance: _finance,
        onUserChanged: widget.onUserChanged,
        onCatChanged: _saveCatPreview,
        onFinanceChanged: _setFinance,
        onSignOut: widget.onSignOut,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            return Row(
              children: [
                if (wide) _Rail(selectedTab: _selectedTab, onChanged: (value) => setState(() => _selectedTab = value)),
                Expanded(child: pages[_selectedTab]),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: MediaQuery.sizeOf(context).width < 900
          ? NavigationBar(
              selectedIndex: _selectedTab,
              onDestinationSelected: (value) => setState(() => _selectedTab = value),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
                NavigationDestination(icon: Icon(Icons.insights), label: 'Insights'),
                NavigationDestination(icon: Icon(Icons.groups_rounded), label: 'Cafe'),
                NavigationDestination(icon: Icon(Icons.person_rounded), label: 'Profile'),
              ],
            )
          : null,
    );
  }

  Widget _dashboard() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        PageHeader(
          title: 'GX Financial Cat',
          subtitle: '${_cat.name} is guarding your financial resilience',
          points: _finance.meowPoints,
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 820;
            return wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: _catPanel()),
                      const SizedBox(width: 16),
                      Expanded(flex: 4, child: _actionPanel()),
                    ],
                  )
                : Column(children: [_catPanel(), const SizedBox(height: 14), _actionPanel()]);
          },
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 820;
            return wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _pocketPanel()),
                      const SizedBox(width: 16),
                      Expanded(child: _transactionPanel()),
                    ],
                  )
                : Column(children: [_pocketPanel(), const SizedBox(height: 14), _transactionPanel()]);
          },
        ),
      ],
    );
  }

  Widget _catPanel() {
    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Meet ${_cat.name}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(
                      '${_cat.breed} • ${_finance.stage.label} • ${_finance.mood.label} • ${_activity.label}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'Open inventory bag',
                onPressed: _openInventoryBag,
                icon: Badge.count(
                  count: _inventoryItems(_cat.ownedItems).length,
                  isLabelVisible: _inventoryItems(_cat.ownedItems).isNotEmpty,
                  child: const Icon(Icons.shopping_bag_rounded),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          AnimatedBuilder(
            animation: Listenable.merge([_catController, _heartController]),
            builder: (context, _) {
              return CatRoomScene(
                mood: _finance.mood,
                stage: _finance.stage,
                accessory: _accessoryLabel(_equippedItems(_cat.accessory)),
                bounce: _catController.value,
                breedIndex: _cat.breedIndex,
                level: _finance.level,
                activity: _activity,
                showHearts: _showHearts,
                heartProgress: _heartController.value,
              );
            },
          ),
          const SizedBox(height: 12),
          ProgressLine(
            label: 'Level ${_finance.level} • ${_finance.levelReward}',
            value: _finance.level >= 20 ? 'Max' : '${_finance.levelXp}/${_finance.nextLevelXp} XP',
            progress: _finance.levelProgress,
            color: const Color(0xFF7C3AED),
          ),
          MetricGrid(
            items: [
              MetricItem('Resilience', '${_finance.resilienceScore}%', Icons.shield_rounded),
              MetricItem('Streak', '${_finance.streak} days', Icons.local_fire_department_rounded),
              MetricItem('Goal', 'RM${_finance.weeklyGoal.round()}', Icons.flag_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionPanel() {
    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nudge Engine', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          _ActionButton(
            icon: Icons.savings_rounded,
            title: 'Saving',
            subtitle: 'Choose a saving action, enter amount, or slide the bar',
            color: const Color(0xFF18A999),
            onTap: _openSavingSheet,
          ),
          _ActionButton(
            icon: Icons.shopping_bag_rounded,
            title: 'Spending',
            subtitle: 'Log boba, food, transport, or BNPL risk',
            color: const Color(0xFFE63946),
            onTap: _openSpendingSheet,
          ),
          _ActionButton(
            icon: Icons.toys_rounded,
            title: 'Play with cat',
            subtitle: 'Force a playful animation for a moment',
            color: const Color(0xFF7C3AED),
            onTap: () => setState(() => _activity = CatActivity.play),
          ),
          _ActionButton(
            icon: Icons.bedtime_rounded,
            title: 'Let cat nap',
            subtitle: 'The cat will curl up and sleep',
            color: const Color(0xFF4361EE),
            onTap: () => setState(() => _activity = CatActivity.sleep),
          ),
        ],
      ),
    );
  }

  Widget _pocketPanel() {
    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PanelTitle(title: "Cat's Home", action: 'GX Pocket', icon: Icons.home_work_rounded),
          const SizedBox(height: 14),
          ProgressLine(label: 'Weekly savings', value: 'RM${_finance.savedThisWeek.toStringAsFixed(2)} / RM${_finance.weeklyGoal.round()}', progress: _finance.savingsProgress, color: const Color(0xFF18A999)),
          ProgressLine(label: 'Weekly spending', value: 'RM${_finance.spentThisWeek.toStringAsFixed(2)} / RM${_finance.weeklyBudget.round()}', progress: _finance.budgetProgress, color: _finance.spentThisWeek > _finance.weeklyBudget ? const Color(0xFFE63946) : const Color(0xFF4361EE)),
          ProgressLine(label: 'Emergency fund', value: '${_finance.emergencyFundPercent}%', progress: _finance.emergencyFundPercent / 100, color: const Color(0xFFFFB703)),
          FilledButton.icon(
            onPressed: _weeklyReportCompleted ? null : _openWeeklyReport,
            icon: Icon(_weeklyReportCompleted ? Icons.lock_rounded : Icons.fact_check_rounded),
            label: Text(_weeklyReportCompleted ? 'Checkup completed' : 'Weekly checkup'),
          ),
        ],
      ),
    );
  }

  Widget _transactionPanel() {
    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PanelTitle(title: 'Recent Signals', action: 'Live demo', icon: Icons.receipt_long_rounded),
          const SizedBox(height: 10),
          for (var index = 0; index < _finance.transactions.take(5).length; index++)
            _TransactionTile(
              transaction: _finance.transactions[index],
              onEdit: () => _editTransaction(index),
              onDelete: () => _deleteTransaction(index),
            ),
        ],
      ),
    );
  }

  Widget _insights() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        PageHeader(title: 'Financial Grooming', subtitle: 'Review behavior, remove debt fleas, and unlock style', points: _finance.meowPoints),
        const SizedBox(height: 14),
        AppSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PanelTitle(title: 'Weekly Report', action: 'Grooming', icon: Icons.fact_check_rounded),
              const SizedBox(height: 12),
              _InsightTile(icon: Icons.savings_rounded, title: 'Savings health', body: _finance.savedThisWeek >= _finance.weeklyGoal ? 'Goal met. ${_cat.name} keeps the Chonk status.' : 'RM${(_finance.weeklyGoal - _finance.savedThisWeek).clamp(0, 999).toStringAsFixed(2)} left to feed the weekly goal.'),
              _InsightTile(icon: Icons.credit_card_off_rounded, title: 'BNPL risk', body: _finance.mood == CatMood.hissing || _finance.spentThisWeek > _finance.weeklyBudget ? 'Debt fleas detected. Transfer to GX Pocket to start recovery.' : 'No debt fleas spotted in the current demo week.'),
              _InsightTile(icon: Icons.school_rounded, title: 'GIGih mission', body: 'Complete one financial literacy session to earn 80 Meow-Points.'),
              FilledButton.icon(
                onPressed: _weeklyReportCompleted ? null : _openWeeklyReport,
                icon: Icon(_weeklyReportCompleted ? Icons.lock_rounded : Icons.fact_check_rounded),
                label: Text(_weeklyReportCompleted ? 'Completed this week' : 'Weekly checkup (${_finance.reportsReviewed} completed)'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AppSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PanelTitle(title: 'Meow-Points Shop', action: 'Catalog', icon: Icons.storefront_rounded),
              const SizedBox(height: 12),
              _ShopSection(
                title: 'Starter Style',
                items: _shopItems.where((item) => item.cost <= 140).toList(),
                ownedItems: _inventoryItems(_cat.ownedItems),
                equippedItems: _equippedItems(_cat.accessory),
                level: _finance.level,
                meowPoints: _finance.meowPoints,
                onBuy: _buyAccessory,
              ),
              const SizedBox(height: 12),
              _ShopSection(
                title: 'Cozy Gear',
                items: _shopItems.where((item) => item.cost > 140 && item.cost <= 280).toList(),
                ownedItems: _inventoryItems(_cat.ownedItems),
                equippedItems: _equippedItems(_cat.accessory),
                level: _finance.level,
                meowPoints: _finance.meowPoints,
                onBuy: _buyAccessory,
              ),
              const SizedBox(height: 12),
              _ShopSection(
                title: 'Rare Flex',
                items: _shopItems.where((item) => item.cost > 280).toList(),
                ownedItems: _inventoryItems(_cat.ownedItems),
                equippedItems: _equippedItems(_cat.accessory),
                level: _finance.level,
                meowPoints: _finance.meowPoints,
                onBuy: _buyAccessory,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _catCafe() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        PageHeader(title: 'Cat Cafe', subtitle: "Friends' cats show who may need a savings nudge", points: _finance.meowPoints),
        const SizedBox(height: 14),
        StreamBuilder<List<FriendRequest>>(
          stream: widget.incomingFriendRequests,
          builder: (context, snapshot) {
            final requests = snapshot.data ?? const <FriendRequest>[];
            if (requests.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: AppSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const PanelTitle(title: 'Friend Requests', action: 'Pending', icon: Icons.mark_email_unread_rounded),
                    const SizedBox(height: 10),
                    for (final request in requests)
                      _FriendRequestTile(
                        request: request,
                        onAccept: () => _handleRequest(request, accept: true),
                        onDecline: () => _handleRequest(request, accept: false),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        AppSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PanelTitle(title: 'Add Friend', action: 'Name or ID', icon: Icons.person_add_rounded),
              const SizedBox(height: 12),
              TextField(
                controller: _friendSearchController,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  labelText: 'Friend name or user ID',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
                onSubmitted: (_) {
                  if (!_friendLoading) _findFriend();
                },
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: _friendLoading ? null : _findFriend,
                icon: _friendLoading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.group_add_rounded),
                label: Text(_friendLoading ? 'Searching...' : 'Find friend'),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              ),
              if (_friendPreview != null) ...[
                const SizedBox(height: 12),
                _FriendPreviewCard(
                  friend: _friendPreview!,
                  actionLabel: 'Send request',
                  onAction: _friendLoading ? null : () => _requestFriend(_friendPreview!),
                  onOpen: () => _openFriendDetail(_friendPreview!),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (_finance.friends.isEmpty)
          AppSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(Icons.groups_rounded, color: Color(0xFF18A999), size: 36),
                SizedBox(height: 10),
                Text('No cafe friends yet', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                SizedBox(height: 4),
                Text('Search by User ID or name, then send a request. Accepted friends will appear here.'),
              ],
            ),
          )
        else
          for (var i = 0; i < _finance.friends.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppSurface(
                child: _FriendRow(
                  friend: _finance.friends[i],
                  onOpen: () => _openFriendDetail(_finance.friends[i]),
                  onNudge: () => _sendNudge(i),
                ),
              ),
            ),
      ],
    );
  }

  void _openFriendDetail(CatFriend friend) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${friend.catName} with ${friend.owner}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              SizedBox(
                height: 220,
                child: CatRoomScene(
                  mood: friend.mood,
                  stage: friend.stage,
                  accessory: friend.accessory,
                  bounce: .5,
                  breedIndex: friend.breedIndex,
                  level: friend.level,
                  activity: CatActivity.idle,
                  showHearts: false,
                  heartProgress: 0,
                ),
              ),
              const SizedBox(height: 12),
              _ReadoutLine(label: 'User ID', value: friend.ownerUserId),
              _ReadoutLine(label: 'Level', value: '${friend.level}'),
              _ReadoutLine(label: 'Item', value: friend.item),
              _ReadoutLine(label: 'Accessory', value: friend.accessory),
              _ReadoutLine(label: 'Mood', value: friend.mood.label),
              _ReadoutLine(label: 'Resilience', value: '${friend.score}%'),
            ],
          ),
        );
      },
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({required this.selectedTab, required this.onChanged});

  final int selectedTab;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: selectedTab,
      onDestinationSelected: onChanged,
      labelType: NavigationRailLabelType.all,
      leading: const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Icon(Icons.pets_rounded, size: 32),
      ),
      destinations: const [
        NavigationRailDestination(icon: Icon(Icons.home_rounded), label: Text('Home')),
        NavigationRailDestination(icon: Icon(Icons.insights), label: Text('Insights')),
        NavigationRailDestination(icon: Icon(Icons.groups_rounded), label: Text('Cafe')),
        NavigationRailDestination(icon: Icon(Icons.person_rounded), label: Text('Profile')),
      ],
    );
  }
}

class _FriendRequestTile extends StatelessWidget {
  const _FriendRequestTile({
    required this.request,
    required this.onAccept,
    required this.onDecline,
  });

  final FriendRequest request;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(child: Text(request.fromFriend.owner.isEmpty ? '?' : request.fromFriend.owner.substring(0, 1).toUpperCase())),
      title: Text('${request.fromFriend.owner} wants to connect'),
      subtitle: Text('${request.fromFriend.catName} • Level ${request.fromFriend.level} • ${request.fromFriend.item}'),
      trailing: Wrap(
        spacing: 6,
        children: [
          IconButton.filledTonal(tooltip: 'Accept', onPressed: onAccept, icon: const Icon(Icons.check_rounded)),
          IconButton(tooltip: 'Decline', onPressed: onDecline, icon: const Icon(Icons.close_rounded)),
        ],
      ),
    );
  }
}

class _FriendPreviewCard extends StatelessWidget {
  const _FriendPreviewCard({
    required this.friend,
    required this.actionLabel,
    required this.onAction,
    required this.onOpen,
  });

  final CatFriend friend;
  final String actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFEAF8F5),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _FriendCatThumb(friend: friend),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${friend.catName} with ${friend.owner}', style: const TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text('Level ${friend.level} • ${friend.item} • ${friend.accessory}', style: const TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
              FilledButton(onPressed: onAction, child: Text(actionLabel)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FriendRow extends StatelessWidget {
  const _FriendRow({
    required this.friend,
    required this.onOpen,
    required this.onNudge,
  });

  final CatFriend friend;
  final VoidCallback onOpen;
  final VoidCallback onNudge;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onOpen,
      child: Row(
        children: [
          _FriendCatThumb(friend: friend),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${friend.catName} with ${friend.owner}', style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(
                  'ID ${friend.ownerUserId} • Level ${friend.level} • ${friend.item} • ${friend.accessory}',
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(minHeight: 8, borderRadius: BorderRadius.circular(99), value: friend.score / 100),
              ],
            ),
          ),
          IconButton.filledTonal(tooltip: 'Send nudge', onPressed: onNudge, icon: const Icon(Icons.volunteer_activism_rounded)),
        ],
      ),
    );
  }
}

class _FriendCatThumb extends StatelessWidget {
  const _FriendCatThumb({required this.friend});

  final CatFriend friend;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 82,
        height: 68,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: RoomPainter(
                  mood: friend.mood,
                  bounce: .5,
                  level: friend.level,
                  activity: CatActivity.idle,
                  bankProgress: friend.score / 100,
                ),
              ),
            ),
            Positioned(
              left: 13,
              right: 13,
              bottom: 4,
              child: CustomPaint(
                size: const Size(56, 45),
                painter: CatPainter(
                  mood: friend.mood,
                  stage: friend.stage,
                  accessory: friend.accessory,
                  bounce: .5,
                  breedIndex: friend.breedIndex,
                  activity: CatActivity.idle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadoutLine extends StatelessWidget {
  const _ReadoutLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: Colors.black54))),
          Flexible(child: SelectableText(value, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w900))),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.transaction,
    required this.onEdit,
    required this.onDelete,
  });

  final GXTransaction transaction;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = transaction.positive ? const Color(0xFF087E6F) : const Color(0xFFE63946);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: transaction.positive ? const Color(0xFFE7F8F4) : const Color(0xFFFFECEC),
        foregroundColor: color,
        child: Icon(transaction.icon),
      ),
      title: Text(transaction.title),
      subtitle: Text(transaction.positive ? 'Saving behavior' : 'Spending behavior'),
      trailing: Wrap(
        spacing: 2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            transaction.amount == 0 ? 'Done' : '${transaction.positive ? '+' : '-'}RM${transaction.amount.toStringAsFixed(2)}',
            style: TextStyle(fontWeight: FontWeight.w800, color: color),
          ),
          PopupMenuButton<String>(
            tooltip: 'Transaction actions',
            onSelected: (value) {
              if (value == 'edit') onEdit();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_rounded), title: Text('Edit'))),
              PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_outline_rounded), title: Text('Delete'))),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(backgroundColor: color, foregroundColor: Colors.white, child: Icon(icon)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InsightTile extends StatelessWidget {
  const _InsightTile({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(backgroundColor: const Color(0xFFEAF8F5), foregroundColor: const Color(0xFF087E6F), child: Icon(icon)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: Text(body),
    );
  }
}

class _ReportMetric extends StatelessWidget {
  const _ReportMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.good,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool good;

  @override
  Widget build(BuildContext context) {
    final color = good ? const Color(0xFF087E6F) : const Color(0xFFE63946);
    return SizedBox(
      width: 145,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: good ? const Color(0xFFEAF8F5) : const Color(0xFFFFECEC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: .25)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
              const SizedBox(height: 2),
              Text(value, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      ),
    );
  }
}

class _InventoryItemTile extends StatelessWidget {
  const _InventoryItemTile({
    required this.item,
    required this.equipped,
    required this.disabled,
    required this.onTap,
  });

  final String item;
  final bool equipped;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: disabled ? const Color(0xFFF3F4F6) : equipped ? const Color(0xFFEAF8F5) : Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: disabled ? null : onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: equipped ? const Color(0xFF18A999) : const Color(0xFFE5E7EB), width: equipped ? 2 : 1),
          ),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: CustomPaint(
                    size: const Size(74, 58),
                    painter: ItemShapePainter(item, muted: disabled),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: disabled ? Colors.black38 : Colors.black87,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Icon(
                equipped ? Icons.check_circle_rounded : disabled ? Icons.lock_outline_rounded : Icons.add_circle_outline_rounded,
                color: equipped ? const Color(0xFF18A999) : disabled ? Colors.black38 : const Color(0xFF7C3AED),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ItemShapePainter extends CustomPainter {
  ItemShapePainter(this.item, {required this.muted});

  final String item;
  final bool muted;

  @override
  void paint(Canvas canvas, Size size) {
    final normalized = item.toLowerCase();
    final center = Offset(size.width / 2, size.height / 2);
    final fade = muted ? .35 : 1.0;
    Color color(Color value) => value.withValues(alpha: fade);

    final line = Paint()
      ..color = color(const Color(0xFF2B2B2B))
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    if (normalized.contains('crown')) {
      canvas.drawPath(
        Path()
          ..moveTo(12, 42)
          ..lineTo(18, 16)
          ..lineTo(32, 35)
          ..lineTo(42, 12)
          ..lineTo(52, 35)
          ..lineTo(66, 16)
          ..lineTo(62, 42)
          ..close(),
        Paint()..color = color(const Color(0xFFFFB703)),
      );
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(12, 40, 50, 10), const Radius.circular(5)), Paint()..color = color(const Color(0xFFD97706)));
      return;
    }
    if (normalized.contains('bowtie')) {
      final paint = Paint()..color = color(const Color(0xFF4361EE));
      canvas.drawPath(Path()..moveTo(center.dx, center.dy)..lineTo(8, 16)..lineTo(8, 44)..close(), paint);
      canvas.drawPath(Path()..moveTo(center.dx, center.dy)..lineTo(66, 16)..lineTo(66, 44)..close(), paint);
      canvas.drawCircle(center, 8, Paint()..color = color(const Color(0xFFFFB703)));
      return;
    }
    if (normalized.contains('cape') || normalized.contains('cloak')) {
      canvas.drawPath(
        Path()
          ..moveTo(18, 8)
          ..quadraticBezierTo(2, 36, 14, 54)
          ..quadraticBezierTo(37, 64, 60, 54)
          ..quadraticBezierTo(72, 36, 56, 8)
          ..close(),
        Paint()..color = color(const Color(0xFF7C3AED)),
      );
      canvas.drawLine(const Offset(20, 10), const Offset(54, 10), line..color = color(const Color(0xFFFFD166)));
      return;
    }
    if (normalized.contains('glasses')) {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(8, 20, 24, 18), const Radius.circular(7)), line);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(42, 20, 24, 18), const Radius.circular(7)), line);
      canvas.drawLine(const Offset(32, 29), const Offset(42, 29), line);
      return;
    }
    if (normalized.contains('backpack') || normalized.contains('hoodie')) {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(20, 8, 34, 44), const Radius.circular(10)), Paint()..color = color(const Color(0xFF5A3825)));
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(27, 22, 20, 15), const Radius.circular(5)), Paint()..color = color(const Color(0xFFFFD166)));
      return;
    }
    if (normalized.contains('medal') || normalized.contains('moon') || normalized.contains('bell') || normalized.contains('charm')) {
      canvas.drawLine(const Offset(37, 8), const Offset(37, 28), line);
      canvas.drawCircle(const Offset(37, 38), 15, Paint()..color = color(normalized.contains('moon') ? const Color(0xFF18A999) : const Color(0xFFFFB703)));
      canvas.drawCircle(const Offset(43, 33), 8, Paint()..color = color(Colors.white.withValues(alpha: .45)));
      return;
    }
    if (normalized.contains('ribbon') || normalized.contains('bandana') || normalized.contains('scarf')) {
      final paint = Paint()..color = color(normalized.contains('scarf') ? const Color(0xFF18A999) : const Color(0xFFE63946));
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(9, 20, 56, 12), const Radius.circular(99)), paint);
      canvas.drawPath(Path()..moveTo(38, 30)..lineTo(62, 48)..lineTo(47, 52)..close(), paint);
      return;
    }

    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(10, 22, 54, 14), const Radius.circular(99)), Paint()..color = color(const Color(0xFFD4AF37)));
    canvas.drawCircle(const Offset(37, 42), 9, Paint()..color = color(const Color(0xFFFFB703)));
  }

  @override
  bool shouldRepaint(covariant ItemShapePainter oldDelegate) => oldDelegate.item != item || oldDelegate.muted != muted;
}

class _ShopSection extends StatelessWidget {
  const _ShopSection({
    required this.title,
    required this.items,
    required this.ownedItems,
    required this.equippedItems,
    required this.level,
    required this.meowPoints,
    required this.onBuy,
  });

  final String title;
  final List<_ShopItem> items;
  final List<String> ownedItems;
  final List<String> equippedItems;
  final int level;
  final int meowPoints;
  final void Function(String accessory, int cost) onBuy;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final item in items)
              _ShopChip(
                item: item,
                owned: ownedItems.contains(item.name),
                equipped: equippedItems.contains(item.name),
                level: level,
                meowPoints: meowPoints,
                onBuy: onBuy,
              ),
          ],
        ),
      ],
    );
  }
}

class _ShopChip extends StatelessWidget {
  const _ShopChip({
    required this.item,
    required this.owned,
    required this.equipped,
    required this.level,
    required this.meowPoints,
    required this.onBuy,
  });

  final _ShopItem item;
  final bool owned;
  final bool equipped;
  final int level;
  final int meowPoints;
  final void Function(String accessory, int cost) onBuy;

  @override
  Widget build(BuildContext context) {
    final levelLocked = !owned && level < item.minLevel;
    final pointLocked = !owned && meowPoints < item.cost;
    final locked = levelLocked || pointLocked;
    final label = equipped
        ? '${item.name} • Equipped'
        : owned
            ? '${item.name} • Equip'
            : levelLocked
                ? '${item.name} • Lv ${item.minLevel}'
                : pointLocked
                    ? '${item.name} • Need ${item.cost} MP'
                    : '${item.name} • ${item.cost} MP';
    return ActionChip(
      avatar: Icon(locked ? Icons.lock_rounded : item.icon, size: 18),
      label: Text(label),
      backgroundColor: locked ? const Color(0xFFF3F4F6) : null,
      onPressed: locked ? null : () => onBuy(item.name, item.cost),
    );
  }
}

class _ShopItem {
  const _ShopItem(this.name, this.cost, this.icon, {this.minLevel = 1});

  final String name;
  final int cost;
  final IconData icon;
  final int minLevel;
}

const _shopItems = [
  _ShopItem('Golden collar', 80, Icons.workspace_premium_rounded),
  _ShopItem('GIGih bowtie', 120, Icons.school_rounded),
  _ShopItem('Round-up ribbon', 90, Icons.savings_rounded),
  _ShopItem('Budget bandana', 110, Icons.account_balance_wallet_rounded),
  _ShopItem('Catnip cape', 180, Icons.auto_awesome_rounded, minLevel: 3),
  _ShopItem('Cozy scarf', 160, Icons.ac_unit_rounded, minLevel: 3),
  _ShopItem('Tiny backpack', 220, Icons.backpack_rounded, minLevel: 5),
  _ShopItem('Savings glasses', 240, Icons.visibility_rounded, minLevel: 5),
  _ShopItem('Moon charm', 260, Icons.dark_mode_rounded, minLevel: 7),
  _ShopItem('Guardian crown', 320, Icons.castle_rounded, minLevel: 10),
  _ShopItem('Emergency fund medal', 360, Icons.shield_rounded, minLevel: 12),
  _ShopItem('Legend hoodie', 420, Icons.local_fire_department_rounded, minLevel: 14),
  _ShopItem('Diamond bell', 520, Icons.diamond_rounded, minLevel: 16),
  _ShopItem('Galaxy cloak', 650, Icons.public_rounded, minLevel: 18),
];

final _shopItemNames = _shopItems.map((item) => item.name).toSet();

_ShopItem? _shopItemFor(String name) {
  for (final item in _shopItems) {
    if (item.name == name) return item;
  }
  return null;
}

List<String> _inventoryItems(List<String> ownedItems) {
  return [
    for (final item in ownedItems)
      if (_shopItemNames.contains(item)) item,
  ];
}

List<String> _equippedItems(String accessory) {
  final normalized = accessory.trim();
  if (normalized.isEmpty || normalized == 'No item' || normalized == 'No item yet') return const [];
  return normalized
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty && item != 'No item' && item != 'No item yet' && _shopItemNames.contains(item))
      .take(2)
      .toList();
}

String _accessoryLabel(List<String> items) {
  final equipped = items.where((item) => item.trim().isNotEmpty).take(2).toList();
  return equipped.isEmpty ? 'No item' : equipped.join(', ');
}

class _MoneyChoice {
  const _MoneyChoice(this.label, this.icon, this.amount, {this.bnpl = false});

  final String label;
  final IconData icon;
  final double amount;
  final bool bnpl;
}
