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
  CatActivity _activity = CatActivity.idle;
  int _selectedTab = 0;

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

  void _setFinance(FinanceState next) {
    final oldLevel = widget.finance.level;
    widget.onFinanceChanged(next);
    if (next.level > oldLevel) {
      final unlocked = [
        for (var level = oldLevel + 1; level <= next.level; level++) FinanceState.rewardForLevel(level),
      ].where((item) => item != 'No item yet').toList();
      if (unlocked.isNotEmpty) {
        final owned = <String>{...widget.cat.ownedItems, ...unlocked}.toList();
        widget.onCatChanged(widget.cat.copyWith(ownedItems: owned));
        _showSnack('Level ${next.level} unlocked: ${unlocked.last}.');
      } else {
        _showSnack('Level ${next.level} unlocked.');
      }
    }
  }

  void _rotateActivity() {
    final next = switch (DateTime.now().second % 4) {
      0 => CatActivity.sleep,
      1 => CatActivity.eat,
      2 => CatActivity.play,
      _ => CatActivity.idle,
    };
    if (mounted) setState(() => _activity = next);
  }

  void _recordSaving(String label, double amount, IconData icon) {
    final tx = List<GXTransaction>.of(widget.finance.transactions)
      ..insert(0, GXTransaction(label, amount, icon, true));
    _setFinance(
      widget.finance.copyWith(
        savedThisWeek: widget.finance.savedThisWeek + amount,
        meowPoints: widget.finance.meowPoints + (amount * 2).round(),
        levelXp: widget.finance.levelXp + amount.round(),
        streak: widget.finance.streak + 1,
        resilienceDays: widget.finance.resilienceDays + 1,
        emergencyFundPercent: math.min(100, widget.finance.emergencyFundPercent + math.max(1, (amount / 20).round())),
        overrideMood: CatMood.neutral,
        transactions: tx,
      ),
    );
    setState(() => _activity = CatActivity.eat);
    _showTreatAnimation();
  }

  void _recordSpending(String label, double amount, IconData icon, {bool bnpl = false}) {
    final tx = List<GXTransaction>.of(widget.finance.transactions)
      ..insert(0, GXTransaction(label, amount, icon, false));
    _setFinance(
      widget.finance.copyWith(
        spentThisWeek: widget.finance.spentThisWeek + amount,
        levelXp: math.max(0, widget.finance.levelXp - (bnpl ? amount / 2 : amount / 10).round()),
        streak: bnpl ? math.max(0, widget.finance.streak - 2) : widget.finance.streak,
        overrideMood: bnpl ? CatMood.hissing : widget.finance.overrideMood,
        transactions: tx,
      ),
    );
    setState(() => _activity = bnpl ? CatActivity.idle : CatActivity.play);
    if (bnpl) _showSnack('BNPL Hiss activated: ${widget.cat.name} spotted a debt trap.');
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

  void _reviewReport() {
    final tx = List<GXTransaction>.of(widget.finance.transactions)
      ..insert(0, GXTransaction('Weekly grooming report reviewed', 0, Icons.fact_check, true));
    _setFinance(
      widget.finance.copyWith(
        reportsReviewed: widget.finance.reportsReviewed + 1,
        meowPoints: widget.finance.meowPoints + 30,
        overrideMood: CatMood.neutral,
        transactions: tx,
      ),
    );
    _showSnack('Financial grooming complete. Fur status improved.');
  }

  void _buyAccessory(String accessory, int cost) {
    final owned = widget.cat.ownedItems.contains(accessory);
    if (!owned && widget.finance.meowPoints < cost) {
      _showSnack('Not enough Meow-Points yet.');
      return;
    }
    widget.onCatChanged(
      widget.cat.copyWith(
        accessory: accessory,
        ownedItems: owned ? widget.cat.ownedItems : [...widget.cat.ownedItems, accessory],
      ),
    );
    if (!owned) _setFinance(widget.finance.copyWith(meowPoints: widget.finance.meowPoints - cost));
    _showSnack(owned ? '$accessory equipped.' : '$accessory bought and equipped.');
  }

  void _unequipAccessory() {
    if (widget.cat.accessory == 'No item') {
      _showSnack('No item is equipped.');
      return;
    }
    widget.onCatChanged(widget.cat.copyWith(accessory: 'No item'));
    _showSnack('Item unequipped.');
  }

  void _sendNudge(int index) {
    final friends = List<CatFriend>.of(widget.finance.friends);
    friends[index] = friends[index].copyWith(score: math.min(100, friends[index].score + 8));
    _setFinance(widget.finance.copyWith(friends: friends, meowPoints: widget.finance.meowPoints + 8));
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
        cat: widget.cat,
        finance: widget.finance,
        onUserChanged: widget.onUserChanged,
        onCatChanged: widget.onCatChanged,
        onFinanceChanged: widget.onFinanceChanged,
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
          subtitle: '${widget.cat.name} is guarding your financial resilience',
          points: widget.finance.meowPoints,
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
                    Text('Meet ${widget.cat.name}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.cat.breed} • ${widget.finance.stage.label} • ${widget.finance.mood.label} • ${_activity.label}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              StatusPill(text: widget.cat.accessory == 'No item' ? 'No item equipped' : widget.cat.accessory, icon: Icons.workspace_premium_rounded),
            ],
          ),
          const SizedBox(height: 18),
          AnimatedBuilder(
            animation: Listenable.merge([_catController, _heartController]),
            builder: (context, _) {
              return CatRoomScene(
                mood: widget.finance.mood,
                stage: widget.finance.stage,
                accessory: widget.cat.accessory,
                bounce: _catController.value,
                breedIndex: widget.cat.breedIndex,
                level: widget.finance.level,
                activity: _activity,
                showHearts: _showHearts,
                heartProgress: _heartController.value,
              );
            },
          ),
          const SizedBox(height: 12),
          ProgressLine(
            label: 'Level ${widget.finance.level} • ${widget.finance.levelReward}',
            value: widget.finance.level >= 20 ? 'Max' : '${widget.finance.levelXp}/${widget.finance.nextLevelXp} XP',
            progress: widget.finance.levelProgress,
            color: const Color(0xFF7C3AED),
          ),
          MetricGrid(
            items: [
              MetricItem('Resilience', '${widget.finance.resilienceScore}%', Icons.shield_rounded),
              MetricItem('Streak', '${widget.finance.streak} days', Icons.local_fire_department_rounded),
              MetricItem('Goal', 'RM${widget.finance.weeklyGoal.round()}', Icons.flag_rounded),
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
          ProgressLine(label: 'Weekly savings', value: 'RM${widget.finance.savedThisWeek.toStringAsFixed(2)} / RM${widget.finance.weeklyGoal.round()}', progress: widget.finance.savingsProgress, color: const Color(0xFF18A999)),
          ProgressLine(label: 'Weekly spending', value: 'RM${widget.finance.spentThisWeek.toStringAsFixed(2)} / RM${widget.finance.weeklyBudget.round()}', progress: widget.finance.budgetProgress, color: widget.finance.spentThisWeek > widget.finance.weeklyBudget ? const Color(0xFFE63946) : const Color(0xFF4361EE)),
          ProgressLine(label: 'Emergency fund', value: '${widget.finance.emergencyFundPercent}%', progress: widget.finance.emergencyFundPercent / 100, color: const Color(0xFFFFB703)),
          FilledButton.icon(onPressed: _reviewReport, icon: const Icon(Icons.brush_rounded), label: const Text('Groom weekly report')),
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
          for (final transaction in widget.finance.transactions.take(5))
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: transaction.positive ? const Color(0xFFE7F8F4) : const Color(0xFFFFECEC),
                foregroundColor: transaction.positive ? const Color(0xFF087E6F) : const Color(0xFFE63946),
                child: Icon(transaction.icon),
              ),
              title: Text(transaction.title),
              subtitle: Text(transaction.positive ? 'Protective behavior' : 'Spending behavior'),
              trailing: Text(
                transaction.amount == 0 ? 'Done' : '${transaction.positive ? '+' : '-'}RM${transaction.amount.toStringAsFixed(2)}',
                style: TextStyle(fontWeight: FontWeight.w800, color: transaction.positive ? const Color(0xFF087E6F) : const Color(0xFFE63946)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _insights() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        PageHeader(title: 'Financial Grooming', subtitle: 'Review behavior, remove debt fleas, and unlock style', points: widget.finance.meowPoints),
        const SizedBox(height: 14),
        AppSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PanelTitle(title: 'Weekly Report', action: 'Grooming', icon: Icons.fact_check_rounded),
              const SizedBox(height: 12),
              _InsightTile(icon: Icons.savings_rounded, title: 'Savings health', body: widget.finance.savedThisWeek >= widget.finance.weeklyGoal ? 'Goal met. ${widget.cat.name} keeps the Chonk status.' : 'RM${(widget.finance.weeklyGoal - widget.finance.savedThisWeek).clamp(0, 999).toStringAsFixed(2)} left to feed the weekly goal.'),
              _InsightTile(icon: Icons.credit_card_off_rounded, title: 'BNPL risk', body: widget.finance.mood == CatMood.hissing || widget.finance.spentThisWeek > widget.finance.weeklyBudget ? 'Debt fleas detected. Transfer to GX Pocket to start recovery.' : 'No debt fleas spotted in the current demo week.'),
              _InsightTile(icon: Icons.school_rounded, title: 'GIGih mission', body: 'Complete one financial literacy session to earn 80 Meow-Points.'),
              FilledButton.icon(onPressed: _reviewReport, icon: const Icon(Icons.cleaning_services_rounded), label: Text('Review report (${widget.finance.reportsReviewed} completed)')),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AppSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PanelTitle(title: 'Inventory', action: 'Owned', icon: Icons.inventory_2_rounded),
              const SizedBox(height: 12),
              _InventoryPanel(
                equipped: widget.cat.accessory,
                ownedItems: widget.cat.ownedItems,
                onEquip: (item) => _buyAccessory(item, 0),
                onUnequip: _unequipAccessory,
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
                items: _shopItems.where((item) => item.cost <= 120).toList(),
                ownedItems: widget.cat.ownedItems,
                equipped: widget.cat.accessory,
                onBuy: _buyAccessory,
              ),
              const SizedBox(height: 12),
              _ShopSection(
                title: 'Cozy Room',
                items: _shopItems.where((item) => item.cost > 120 && item.cost <= 260).toList(),
                ownedItems: widget.cat.ownedItems,
                equipped: widget.cat.accessory,
                onBuy: _buyAccessory,
              ),
              const SizedBox(height: 12),
              _ShopSection(
                title: 'Rare Flex',
                items: _shopItems.where((item) => item.cost > 260).toList(),
                ownedItems: widget.cat.ownedItems,
                equipped: widget.cat.accessory,
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
        PageHeader(title: 'Cat Cafe', subtitle: "Friends' cats show who may need a savings nudge", points: widget.finance.meowPoints),
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
        if (widget.finance.friends.isEmpty)
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
          for (var i = 0; i < widget.finance.friends.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppSurface(
                child: _FriendRow(
                  friend: widget.finance.friends[i],
                  onOpen: () => _openFriendDetail(widget.finance.friends[i]),
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
              Center(
                child: CustomPaint(
                  size: const Size(220, 170),
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
    return CustomPaint(
      size: const Size(76, 66),
      painter: CatPainter(
        mood: friend.mood,
        stage: friend.stage,
        accessory: friend.accessory,
        bounce: .5,
        breedIndex: friend.breedIndex,
        activity: CatActivity.idle,
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

class _InventoryPanel extends StatelessWidget {
  const _InventoryPanel({
    required this.equipped,
    required this.ownedItems,
    required this.onEquip,
    required this.onUnequip,
  });

  final String equipped;
  final List<String> ownedItems;
  final ValueChanged<String> onEquip;
  final VoidCallback onUnequip;

  @override
  Widget build(BuildContext context) {
    if (ownedItems.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.inventory_2_rounded, size: 36, color: Color(0xFF18A999)),
          SizedBox(height: 10),
          Text('No items yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          SizedBox(height: 4),
          Text('Earn Meow-Points, buy items from the catalog, then equip them here.'),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                equipped == 'No item' ? 'Equipped: none' : 'Equipped: $equipped',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            TextButton.icon(onPressed: onUnequip, icon: const Icon(Icons.remove_circle_outline_rounded), label: const Text('Unequip')),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in ownedItems)
              ChoiceChip(
                avatar: Icon(_iconForItem(item), size: 18),
                label: Text(item),
                selected: equipped == item,
                onSelected: (_) => onEquip(item),
              ),
          ],
        ),
      ],
    );
  }
}

class _ShopSection extends StatelessWidget {
  const _ShopSection({
    required this.title,
    required this.items,
    required this.ownedItems,
    required this.equipped,
    required this.onBuy,
  });

  final String title;
  final List<_ShopItem> items;
  final List<String> ownedItems;
  final String equipped;
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
                equipped: equipped == item.name,
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
    required this.onBuy,
  });

  final _ShopItem item;
  final bool owned;
  final bool equipped;
  final void Function(String accessory, int cost) onBuy;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(item.icon, size: 18),
      label: Text(equipped ? '${item.name} • Equipped' : owned ? '${item.name} • Equip' : '${item.name} • ${item.cost} MP'),
      onPressed: () => onBuy(item.name, item.cost),
    );
  }
}

class _ShopItem {
  const _ShopItem(this.name, this.cost, this.icon);

  final String name;
  final int cost;
  final IconData icon;
}

const _shopItems = [
  _ShopItem('Golden collar', 80, Icons.workspace_premium_rounded),
  _ShopItem('GIGih bowtie', 120, Icons.school_rounded),
  _ShopItem('Round-up ribbon', 90, Icons.savings_rounded),
  _ShopItem('Budget bandana', 110, Icons.account_balance_wallet_rounded),
  _ShopItem('Catnip cape', 180, Icons.auto_awesome_rounded),
  _ShopItem('Cozy scarf', 160, Icons.ac_unit_rounded),
  _ShopItem('Tiny backpack', 220, Icons.backpack_rounded),
  _ShopItem('Savings glasses', 240, Icons.visibility_rounded),
  _ShopItem('Moon charm', 260, Icons.dark_mode_rounded),
  _ShopItem('Guardian crown', 320, Icons.castle_rounded),
  _ShopItem('Emergency fund medal', 360, Icons.shield_rounded),
  _ShopItem('Legend hoodie', 420, Icons.local_fire_department_rounded),
  _ShopItem('Diamond bell', 520, Icons.diamond_rounded),
  _ShopItem('Galaxy cloak', 650, Icons.public_rounded),
];

IconData _iconForItem(String item) {
  return _shopItems
      .firstWhere(
        (shopItem) => shopItem.name == item,
        orElse: () => const _ShopItem('Item', 0, Icons.inventory_2_rounded),
      )
      .icon;
}

class _MoneyChoice {
  const _MoneyChoice(this.label, this.icon, this.amount, {this.bnpl = false});

  final String label;
  final IconData icon;
  final double amount;
  final bool bnpl;
}
