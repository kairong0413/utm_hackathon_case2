import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../widgets/app_widgets.dart';
import '../widgets/cat_room_scene.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.user,
    required this.cat,
    required this.finance,
    required this.onUserChanged,
    required this.onCatChanged,
    required this.onFinanceChanged,
    required this.onSignOut,
  });

  final GXUser user;
  final CatProfile cat;
  final FinanceState finance;
  final ValueChanged<GXUser> onUserChanged;
  final ValueChanged<CatProfile> onCatChanged;
  final ValueChanged<FinanceState> onFinanceChanged;
  final VoidCallback onSignOut;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _catNameController;
  late bool _studentMode;
  late double _weeklyGoal;
  late double _weeklyBudget;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(text: widget.user.phone);
    _catNameController = TextEditingController(text: widget.cat.name);
    _studentMode = widget.user.studentMode;
    _weeklyGoal = widget.finance.weeklyGoal;
    _weeklyBudget = widget.finance.weeklyBudget;
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user != widget.user || oldWidget.cat != widget.cat || oldWidget.finance != widget.finance) {
      _nameController.text = widget.user.name;
      _emailController.text = widget.user.email;
      _phoneController.text = widget.user.phone;
      _catNameController.text = widget.cat.name;
      _studentMode = widget.user.studentMode;
      _weeklyGoal = widget.finance.weeklyGoal;
      _weeklyBudget = widget.finance.weeklyBudget;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _catNameController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    widget.onUserChanged(
      widget.user.copyWith(
        name: _nameController.text.trim().isEmpty ? widget.user.name : _nameController.text.trim(),
        email: _emailController.text.trim().isEmpty ? widget.user.email : _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? widget.user.phone : _phoneController.text.trim(),
        studentMode: _studentMode,
      ),
    );
    widget.onCatChanged(
      widget.cat.copyWith(
        name: _catNameController.text.trim().isEmpty ? widget.cat.name : _catNameController.text.trim(),
      ),
    );
    widget.onFinanceChanged(
      widget.finance.copyWith(
        weeklyGoal: _weeklyGoal,
        weeklyBudget: _weeklyBudget,
      ),
    );
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Profile saved.')));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        PageHeader(
          title: 'Profile',
          subtitle: 'Your account, companion, and goals',
          points: widget.finance.meowPoints,
        ),
        const SizedBox(height: 14),
        _ProfileHero(user: widget.user, cat: widget.cat, finance: widget.finance),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 820;
            final account = _accountPanel();
            final cat = _catPanel();
            return wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: account),
                      const SizedBox(width: 14),
                      Expanded(child: cat),
                    ],
                  )
                : Column(
                    children: [
                      account,
                      const SizedBox(height: 14),
                      cat,
                    ],
                  );
          },
        ),
        const SizedBox(height: 14),
        _goalsPanel(),
      ],
    );
  }

  Widget _accountPanel() {
    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PanelTitle(title: 'User Profile', action: 'Account', icon: Icons.person_rounded),
          const SizedBox(height: 14),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.badge_rounded)),
          ),
          const SizedBox(height: 12),
          _InfoStrip(icon: Icons.fingerprint_rounded, label: 'User ID', value: widget.user.userId.isEmpty ? 'Not assigned yet' : widget.user.userId),
          const SizedBox(height: 12),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_rounded)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone_rounded)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _studentMode,
            onChanged: (value) => setState(() => _studentMode = value),
            title: const Text('Student mode'),
            secondary: const Icon(Icons.school_rounded),
          ),
        ],
      ),
    );
  }

  Widget _catPanel() {
    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PanelTitle(title: 'Cat Profile', action: 'Companion', icon: Icons.pets_rounded),
          const SizedBox(height: 14),
          TextField(
            controller: _catNameController,
            decoration: const InputDecoration(labelText: 'Cat name', prefixIcon: Icon(Icons.pets_rounded)),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ProfileStat(icon: Icons.category_rounded, label: 'Breed', value: widget.cat.breed),
              _ProfileStat(icon: Icons.workspace_premium_rounded, label: 'Items', value: widget.cat.accessory == 'No item' ? 'None' : widget.cat.accessory),
              _ProfileStat(icon: Icons.mood_rounded, label: 'Mood', value: widget.finance.mood.label),
              _ProfileStat(icon: Icons.trending_up_rounded, label: 'Stage', value: widget.finance.stage.label),
              _ProfileStat(icon: Icons.military_tech_rounded, label: 'Level', value: '${widget.finance.level} / 20'),
              _ProfileStat(icon: Icons.auto_awesome_rounded, label: 'Unlocked', value: widget.finance.levelReward),
            ],
          ),
          const SizedBox(height: 12),
          _InfoStrip(
            icon: Icons.shopping_bag_rounded,
            label: 'Owned',
            value: widget.cat.ownedItems.isEmpty ? 'No bought items yet' : widget.cat.ownedItems.join(', '),
          ),
        ],
      ),
    );
  }

  Widget _goalsPanel() {
    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PanelTitle(title: 'Financial Targets', action: 'Goals', icon: Icons.tune_rounded),
          const SizedBox(height: 14),
          _SliderSetting(
            label: 'Weekly savings goal',
            value: _weeklyGoal,
            min: 20,
            max: 200,
            prefix: 'RM',
            onChanged: (value) => setState(() => _weeklyGoal = value),
          ),
          _SliderSetting(
            label: 'Weekly spending budget',
            value: _weeklyBudget,
            min: 80,
            max: 500,
            prefix: 'RM',
            onChanged: (value) => setState(() => _weeklyBudget = value),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _saveProfile,
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Save profile'),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onSignOut,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sign out'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.user,
    required this.cat,
    required this.finance,
  });

  final GXUser user;
  final CatProfile cat;
  final FinanceState finance;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      padding: 0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _ProfileGlowPainter())),
            Padding(
              padding: const EdgeInsets.all(18),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 720;
                  final intro = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white.withValues(alpha: .85),
                        foregroundColor: const Color(0xFF087E6F),
                        child: Text(
                          user.name.isEmpty ? '?' : user.name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user.name,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text('${cat.name} • ${finance.stage.label}', style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          StatusPill(text: 'Level ${finance.level}', icon: Icons.military_tech_rounded),
                          StatusPill(text: '${finance.resilienceScore}% resilient', icon: Icons.shield_rounded),
                          StatusPill(text: '${finance.meowPoints} MP', icon: Icons.stars_rounded),
                        ],
                      ),
                    ],
                  );
                  final scene = CatRoomScene(
                    mood: finance.mood,
                    stage: finance.stage,
                    accessory: cat.accessory,
                    bounce: .5,
                    breedIndex: cat.breedIndex,
                    level: finance.level,
                    activity: CatActivity.idle,
                    showHearts: false,
                    heartProgress: 0,
                  );

                  return wide
                      ? Row(
                          children: [
                            Expanded(flex: 4, child: intro),
                            const SizedBox(width: 18),
                            Expanded(flex: 5, child: scene),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            intro,
                            const SizedBox(height: 14),
                            scene,
                          ],
                        );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileGlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFFFF7E6));
    canvas.drawCircle(Offset(size.width * .12, size.height * .2), 120, Paint()..color = const Color(0xFF18A999).withValues(alpha: .16));
    canvas.drawCircle(Offset(size.width * .92, size.height * .12), 150, Paint()..color = const Color(0xFFFFB703).withValues(alpha: .2));
    canvas.drawCircle(Offset(size.width * .72, size.height * .95), 170, Paint()..color = const Color(0xFF7C3AED).withValues(alpha: .09));
  }

  @override
  bool shouldRepaint(covariant _ProfileGlowPainter oldDelegate) => false;
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 155,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF7F4EF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE8E1D8)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: const Color(0xFF087E6F)),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoStrip extends StatelessWidget {
  const _InfoStrip({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCDEDE7)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF087E6F)),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: const TextStyle(color: Colors.black54))),
            Flexible(
              child: SelectableText(
                value,
                textAlign: TextAlign.end,
                style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF087E6F)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliderSetting extends StatelessWidget {
  const _SliderSetting({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.prefix,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final String prefix;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800))),
            Text('$prefix${value.round()}', style: const TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: ((max - min) / 10).round(),
          label: '$prefix${value.round()}',
          onChanged: onChanged,
        ),
      ],
    );
  }
}
