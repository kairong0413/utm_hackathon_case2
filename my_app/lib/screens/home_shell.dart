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
    required this.onSignOut,
  });

  final GXUser user;
  final CatProfile cat;
  final FinanceState finance;
  final ValueChanged<FinanceState> onFinanceChanged;
  final ValueChanged<GXUser> onUserChanged;
  final ValueChanged<CatProfile> onCatChanged;
  final VoidCallback onSignOut;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with TickerProviderStateMixin {
  late final AnimationController _catController;
  late final AnimationController _heartController;
  bool _showHearts = false;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _catController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
    _heartController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  }

  @override
  void dispose() {
    _catController.dispose();
    _heartController.dispose();
    super.dispose();
  }

  void _setFinance(FinanceState next) => widget.onFinanceChanged(next);

  void _feedRoundUp() {
    final tx = List<GXTransaction>.of(widget.finance.transactions)
      ..insert(0, GXTransaction('Round-up fed the cat', 4.80, Icons.restaurant, true));
    _setFinance(
      widget.finance.copyWith(
        savedThisWeek: widget.finance.savedThisWeek + 4.80,
        meowPoints: widget.finance.meowPoints + 15,
        streak: widget.finance.streak + 1,
        resilienceDays: widget.finance.resilienceDays + 1,
        overrideMood: CatMood.neutral,
        transactions: tx,
      ),
    );
    _showTreatAnimation();
  }

  void _addPocketTreat() {
    final tx = List<GXTransaction>.of(widget.finance.transactions)
      ..insert(0, GXTransaction('GX Pocket treat', 20, Icons.account_balance_wallet, true));
    _setFinance(
      widget.finance.copyWith(
        savedThisWeek: widget.finance.savedThisWeek + 20,
        meowPoints: widget.finance.meowPoints + 50,
        emergencyFundPercent: math.min(100, widget.finance.emergencyFundPercent + 7),
        overrideMood: CatMood.neutral,
        transactions: tx,
      ),
    );
    _showTreatAnimation();
  }

  void _logBoba() {
    final tx = List<GXTransaction>.of(widget.finance.transactions)
      ..insert(0, GXTransaction('Boba gulp', 15, Icons.local_drink, false));
    _setFinance(
      widget.finance.copyWith(
        spentThisWeek: widget.finance.spentThisWeek + 15,
        transactions: tx,
      ),
    );
  }

  void _triggerBnplHiss() {
    final tx = List<GXTransaction>.of(widget.finance.transactions)
      ..insert(0, GXTransaction('BNPL alert: fashion checkout', 200, Icons.warning_rounded, false));
    _setFinance(
      widget.finance.copyWith(
        spentThisWeek: widget.finance.spentThisWeek + 200,
        streak: math.max(0, widget.finance.streak - 2),
        overrideMood: CatMood.hissing,
        transactions: tx,
      ),
    );
    _showSnack('BNPL Hiss activated: ${widget.cat.name} spotted a debt trap.');
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
    if (widget.finance.meowPoints < cost) {
      _showSnack('Not enough Meow-Points yet.');
      return;
    }
    widget.onCatChanged(widget.cat.copyWith(accessory: accessory));
    _setFinance(widget.finance.copyWith(meowPoints: widget.finance.meowPoints - cost));
  }

  void _sendNudge(int index) {
    final friends = List<CatFriend>.of(widget.finance.friends);
    friends[index] = friends[index].copyWith(score: math.min(100, friends[index].score + 8));
    _setFinance(widget.finance.copyWith(friends: friends, meowPoints: widget.finance.meowPoints + 8));
    _showSnack('Savings nudge sent.');
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
                      '${widget.cat.breed} • ${widget.finance.stage.label} • ${widget.finance.mood.label}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              StatusPill(text: widget.cat.accessory, icon: Icons.workspace_premium_rounded),
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
                showHearts: _showHearts,
                heartProgress: _heartController.value,
              );
            },
          ),
          const SizedBox(height: 12),
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
          _ActionButton(icon: Icons.restaurant_rounded, title: 'Feed with Round-up', subtitle: '+RM4.80 savings, +15 Meow-Points', color: const Color(0xFF18A999), onTap: _feedRoundUp),
          _ActionButton(icon: Icons.account_balance_wallet_rounded, title: 'Send GX Pocket Treat', subtitle: '+RM20 emergency fund recovery', color: const Color(0xFFFFB703), onTap: _addPocketTreat),
          _ActionButton(icon: Icons.local_drink_rounded, title: 'Log RM15 Boba', subtitle: 'Cat does a quick gulp animation', color: const Color(0xFF7C3AED), onTap: _logBoba),
          _ActionButton(icon: Icons.warning_rounded, title: 'Simulate BNPL Checkout', subtitle: 'Debt trap detection triggers a hiss', color: const Color(0xFFE63946), onTap: _triggerBnplHiss),
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
              const PanelTitle(title: 'Meow-Points Shop', action: 'Customize', icon: Icons.storefront_rounded),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _ShopChip('Golden collar', 80, Icons.workspace_premium_rounded, _buyAccessory),
                  _ShopChip('GIGih bowtie', 120, Icons.school_rounded, _buyAccessory),
                  _ShopChip('Catnip cape', 180, Icons.auto_awesome_rounded, _buyAccessory),
                  _ShopChip('Guardian crown', 240, Icons.castle_rounded, _buyAccessory),
                ],
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
        for (var i = 0; i < widget.finance.friends.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppSurface(
              child: Row(
                children: [
                  CustomPaint(size: const Size(76, 66), painter: CatPainter(mood: widget.finance.friends[i].mood, stage: CatStage.kitten, accessory: 'Friend', bounce: .5, breedIndex: i)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${widget.finance.friends[i].catName} with ${widget.finance.friends[i].owner}', style: const TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(minHeight: 8, borderRadius: BorderRadius.circular(99), value: widget.finance.friends[i].score / 100),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(tooltip: 'Send nudge', onPressed: () => _sendNudge(i), icon: const Icon(Icons.volunteer_activism_rounded)),
                ],
              ),
            ),
          ),
      ],
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

class _ShopChip extends StatelessWidget {
  const _ShopChip(this.name, this.cost, this.icon, this.onBuy);

  final String name;
  final int cost;
  final IconData icon;
  final void Function(String accessory, int cost) onBuy;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text('$name • $cost MP'),
      onPressed: () => onBuy(name, cost),
    );
  }
}
