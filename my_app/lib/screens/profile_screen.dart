import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../widgets/app_widgets.dart';

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
          subtitle: 'Manage your account, cat identity, and resilience targets',
          points: widget.finance.meowPoints,
        ),
        const SizedBox(height: 14),
        AppSurface(
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
              _ReadOnlyFact(label: 'User ID', value: widget.user.userId.isEmpty ? 'Not assigned yet' : widget.user.userId),
              const SizedBox(height: 2),
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
                title: const Text('Student / fresh graduate mode'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AppSurface(
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
              _ReadOnlyFact(label: 'Breed', value: widget.cat.breed),
              _ReadOnlyFact(label: 'Accessory', value: widget.cat.accessory),
              _ReadOnlyFact(label: 'Current mood', value: widget.finance.mood.label),
              _ReadOnlyFact(label: 'Growth stage', value: widget.finance.stage.label),
              _ReadOnlyFact(label: 'Level', value: '${widget.finance.level} / 20'),
              _ReadOnlyFact(label: 'Unlocked', value: widget.finance.levelReward),
              _ReadOnlyFact(label: 'Owned items', value: widget.cat.ownedItems.isEmpty ? 'None yet' : widget.cat.ownedItems.join(', ')),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AppSurface(
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
              FilledButton.icon(
                onPressed: _saveProfile,
                icon: const Icon(Icons.save_rounded),
                label: const Text('Save profile'),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: widget.onSignOut,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sign out'),
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReadOnlyFact extends StatelessWidget {
  const _ReadOnlyFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: Colors.black54))),
          Flexible(
            child: SelectableText(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
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
