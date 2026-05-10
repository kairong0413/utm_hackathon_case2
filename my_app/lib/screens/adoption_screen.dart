import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../widgets/app_widgets.dart';
import '../widgets/cat_room_scene.dart';

class AdoptionScreen extends StatefulWidget {
  const AdoptionScreen({super.key, required this.onAdopted});

  final void Function(CatProfile cat, double weeklyGoal) onAdopted;

  @override
  State<AdoptionScreen> createState() => _AdoptionScreenState();
}

class _AdoptionScreenState extends State<AdoptionScreen> {
  final _nameController = TextEditingController(text: 'Mojo');
  final _breeds = const ['Calico', 'Tuxedo', 'Ginger', 'Siamese'];
  int _breedIndex = 0;
  double _weeklyGoal = 50;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _adopt() {
    final name = _nameController.text.trim().isEmpty ? 'Mojo' : _nameController.text.trim();
    widget.onAdopted(
      CatProfile(
        name: name,
        breed: _breeds[_breedIndex],
        breedIndex: _breedIndex,
        accessory: 'No item',
        ownedItems: const [],
      ),
      _weeklyGoal,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: ListView(
              padding: const EdgeInsets.all(20),
              shrinkWrap: true,
              children: [
                Text(
                  'Adopt your GX-Cat',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  'Name your cat, choose a breed, and set the first weekly savings goal.',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.black54),
                ),
                const SizedBox(height: 22),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth > 760;
                    final preview = AppSurface(
                      child: CatRoomScene(
                        mood: CatMood.thriving,
                        stage: CatStage.kitten,
                        accessory: 'No item',
                        bounce: .5,
                        breedIndex: _breedIndex,
                        level: 1,
                        activity: CatActivity.idle,
                        showHearts: false,
                        heartProgress: 0,
                      ),
                    );
                    final form = _buildForm();
                    return wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: preview),
                              const SizedBox(width: 16),
                              Expanded(child: form),
                            ],
                          )
                        : Column(children: [preview, const SizedBox(height: 14), form]);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Cat name', prefixIcon: Icon(Icons.badge_rounded)),
          ),
          const SizedBox(height: 16),
          Text('Choose breed', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < _breeds.length; i++)
                ChoiceChip(
                  label: Text(_breeds[i]),
                  selected: _breedIndex == i,
                  onSelected: (_) => setState(() => _breedIndex = i),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: Text('Weekly savings goal', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
              Text('RM${_weeklyGoal.round()}', style: const TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
          Slider(
            min: 20,
            max: 200,
            divisions: 18,
            value: _weeklyGoal,
            label: 'RM${_weeklyGoal.round()}',
            onChanged: (value) => setState(() => _weeklyGoal = value),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _adopt,
            icon: const Icon(Icons.favorite_rounded),
            label: const Text('Start resilience journey'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          ),
        ],
      ),
    );
  }
}
