import 'package:flutter/material.dart';

import '../game/dusk_horde_game.dart';
import '../game/levels.dart';
import '../meta/perks.dart';
import '../meta/progress.dart';
import '../meta/weapon_catalog.dart';
import 'theme.dart';

/// The main menu between runs: spend scrap on gun tiers and perks, pick the
/// loadout, deploy.
class Workbench extends StatefulWidget {
  const Workbench({super.key, required this.game});

  final DuskHordeGame game;

  @override
  State<Workbench> createState() => _WorkbenchState();
}

class _WorkbenchState extends State<Workbench> {
  String _weapon = 'pistol';

  Progress get p => widget.game.progress;

  void _change(bool Function() action) {
    if (action()) {
      setState(() {});
      widget.game.store.save(p);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Palette.bg,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Column(
            children: [
              _header(),
              const SizedBox(height: 6),
              _levelPicker(),
              const SizedBox(height: 8),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 150, child: _weaponList()),
                    const SizedBox(width: 12),
                    Expanded(flex: 3, child: _tiers()),
                    const SizedBox(width: 12),
                    Expanded(flex: 2, child: _perks()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                const Text(
                  'WORKBENCH',
                  style: TextStyle(
                    color: Palette.text,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(width: 20),
                Text(
                  'SCRAP ${p.scrap}',
                  style: const TextStyle(color: Palette.scrap, fontSize: 15),
                ),
                const SizedBox(width: 14),
                Text(
                  'CORES ${p.cores}',
                  style: const TextStyle(color: Palette.core, fontSize: 15),
                ),
                const SizedBox(width: 14),
                Text(
                  'BEST WAVE ${p.bestWave}',
                  style: const TextStyle(color: Palette.muted, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        FilledButton(
          key: const Key('deploy'),
          style: FilledButton.styleFrom(
            backgroundColor: Palette.blood,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          ),
          onPressed: widget.game.deploy,
          child: const Text(
            'DEPLOY',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }

  /// Which apocalypse to deploy into, and story or Endless.
  Widget _levelPicker() {
    Widget chip({
      required Key key,
      required String label,
      required String? lockedText,
      required bool selected,
      required VoidCallback onTap,
    }) {
      final locked = lockedText != null;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: OutlinedButton(
          key: key,
          style: OutlinedButton.styleFrom(
            backgroundColor: selected ? Palette.chosen : null,
            foregroundColor: Palette.text,
            disabledForegroundColor: Palette.muted,
            side: BorderSide(
              color: selected
                  ? Palette.chosen
                  : Palette.muted.withValues(alpha: 0.4),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            visualDensity: VisualDensity.compact,
          ),
          onPressed: locked ? null : onTap,
          child: Text(
            locked ? '$label  ·  $lockedText' : label,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      );
    }

    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final l in Levels.all)
            chip(
              key: Key('level-${l.id}'),
              label:
                  '${l.number}. ${l.name.toUpperCase()}'
                  '${_best(l.id)}',
              lockedText: p.isLevelOpen(l.id) ? null : l.unlockText,
              selected: p.level == l.id,
              onTap: () => _change(() {
                p.level = l.id;
                return true;
              }),
            ),
          chip(
            key: const Key('endless'),
            label: p.endless ? 'ENDLESS: ON' : 'ENDLESS: OFF',
            lockedText: p.endlessOpen
                ? null
                : 'Survive the night at the Crash Site',
            selected: p.endless && p.endlessOpen,
            onTap: () => _change(() {
              p.endless = !p.endless;
              return true;
            }),
          ),
        ],
      ),
    );
  }

  /// "  ·  best 7" after a level's name, story or Endless.
  String _best(String id) {
    final best = (p.endless && p.endlessOpen ? p.endlessBest : p.bestWaves)[id];
    return best == null ? '' : '  ·  best $best';
  }

  Widget _weaponList() {
    return ListView(
      children: [
        for (final w in Weapons.all) _weaponCard(w),
        const SizedBox(height: 6),
        const Text(
          'Tick up to 2 guns to take into the run.',
          style: TextStyle(color: Palette.muted, fontSize: 11),
        ),
      ],
    );
  }

  Widget _weaponCard(WeaponDef w) {
    final unlocked = p.unlocked.contains(w.id);
    final selected = _weapon == w.id;
    final inLoadout = p.loadout.contains(w.id);
    return GestureDetector(
      onTap: () => setState(() => _weapon = w.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? Palette.panelHi : Palette.panel,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? Palette.text.withValues(alpha: 0.4)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    w.name,
                    style: TextStyle(
                      color: unlocked ? Palette.text : Palette.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    unlocked ? 'Tier ${p.tierCount(w.id)} / 5' : 'LOCKED',
                    style: const TextStyle(color: Palette.muted, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (unlocked)
              Checkbox(
                value: inLoadout,
                onChanged: (on) => _change(() {
                  if (on == true && p.loadout.length < 2) {
                    p.loadout.add(w.id);
                    return true;
                  }
                  if (on == false && p.loadout.length > 1) {
                    p.loadout.remove(w.id);
                    return true;
                  }
                  return false;
                }),
              ),
          ],
        ),
      ),
    );
  }

  Widget _tiers() {
    final w = Weapons.byId(_weapon);
    if (!p.unlocked.contains(w.id)) {
      return _panel(
        child: Center(
          child: Text(
            '${w.name} is locked.\n${w.unlockText}.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Palette.muted, fontSize: 14),
          ),
        ),
      );
    }
    final owned = p.tierCount(w.id);
    final chosen = p.tiersOf(w.id);
    final s = p.statsFor(w);
    return _panel(
      child: ListView(
        children: [
          Text(
            '${w.name}:  ${s.damage.toStringAsFixed(1)} dmg · '
            '${s.shotsPerSecond.toStringAsFixed(1)}/s · '
            'mag ${s.magazine} · reload ${s.reloadSeconds.toStringAsFixed(2)} s'
            '${s.pierce > 0 ? ' · pierce ${s.pierce}' : ''}'
            '${s.critChance > 0 ? ' · crit ${(s.critChance * 100).round()}%' : ''}'
            '${s.reserve != null ? ' · spare ${s.reserve}' : ''}',
            style: const TextStyle(color: Palette.muted, fontSize: 11),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < 4; i++) _tierRow(w, i, owned, chosen[i]),
          _signatureRow(w, owned),
        ],
      ),
    );
  }

  Widget _tierRow(WeaponDef w, int i, int owned, int? choice) {
    final (a, b) = standardTiers[i];
    final isNext = i == owned;
    final isOwned = i < owned;
    final why = isNext ? p.whyNotBuyTier(w.id) : null;
    Widget option(int idx, UpgradeOption o) {
      final picked = isOwned && choice == idx;
      final enabled = isOwned ? !picked : isNext && why == null;
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: OutlinedButton(
            key: Key('tier-${w.id}-$i-$idx'),
            style: OutlinedButton.styleFrom(
              backgroundColor: picked ? Palette.chosen : null,
              foregroundColor: Palette.text,
              disabledForegroundColor: picked
                  ? Palette.text
                  : Palette.muted.withValues(alpha: 0.6),
              side: BorderSide(
                color: picked
                    ? Palette.chosen
                    : Palette.muted.withValues(alpha: 0.4),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onPressed: !enabled
                ? null
                : () => _change(
                    () => isOwned
                        ? p.respec(w.id, i, idx)
                        : p.buyTier(w.id, choice: idx),
                  ),
            child: Text(o.label, style: const TextStyle(fontSize: 12)),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 74,
            child: Text(
              isOwned ? 'TIER ${i + 1}  ✓' : 'TIER ${i + 1}\n${tierCosts[i]}',
              style: TextStyle(
                color: isOwned ? Palette.text : Palette.scrap,
                fontSize: 11,
              ),
            ),
          ),
          option(0, a),
          option(1, b),
        ],
      ),
    );
  }

  Widget _signatureRow(WeaponDef w, int owned) {
    final isOwned = owned >= 5;
    final why = owned == 4 ? p.whyNotBuyTier(w.id) : 'Buy tier 4 first';
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isOwned
            ? Palette.chosen.withValues(alpha: 0.5)
            : Palette.panelHi,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TIER 5 · ${w.signatureName.toUpperCase()}',
                  style: const TextStyle(
                    color: Palette.text,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                Text(
                  w.signatureText,
                  style: const TextStyle(color: Palette.muted, fontSize: 11),
                ),
              ],
            ),
          ),
          if (!isOwned)
            OutlinedButton(
              key: Key('tier-${w.id}-4'),
              onPressed: why == null
                  ? () => _change(() => p.buyTier(w.id))
                  : null,
              child: Text(
                why ?? '${tierCosts[4]} + 1 core',
                style: const TextStyle(fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }

  Widget _perks() {
    return _panel(
      child: ListView(
        children: [
          const Text(
            'SURVIVOR PERKS',
            style: TextStyle(
              color: Palette.text,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          for (final perk in Perks.all) _perkRow(perk),
        ],
      ),
    );
  }

  Widget _perkRow(PerkDef perk) {
    final lvl = p.perkLevel(perk.id);
    final maxed = lvl >= perk.maxLevel;
    final cost = maxed ? 0 : perk.costs[lvl];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${perk.name}  ${'●' * lvl}${'○' * (perk.maxLevel - lvl)}',
                  style: const TextStyle(color: Palette.text, fontSize: 13),
                ),
                Text(
                  perk.perLevel,
                  style: const TextStyle(color: Palette.muted, fontSize: 11),
                ),
              ],
            ),
          ),
          OutlinedButton(
            key: Key('perk-${perk.id}'),
            onPressed: maxed || p.scrap < cost
                ? null
                : () => _change(() => p.buyPerk(perk)),
            child: Text(
              maxed ? 'MAX' : '$cost',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _panel({required Widget child}) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Palette.panel,
      borderRadius: BorderRadius.circular(8),
    ),
    child: child,
  );
}
