import 'dart:math';
import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants.dart';
import '../models/person.dart';
import '../state/broadcast_provider.dart';
import '../utils/proximity_utils.dart';

final ringVisibilityProvider = StateProvider<Set<int>>((ref) => {0, 1, 2, 3});
final focusQuadrantProvider = StateProvider<int?>((ref) => null);

class RadarView extends ConsumerWidget {
  const RadarView({
    super.key,
    required this.people,
    required this.maxRangeMeters,
    required this.onTapPerson,
  });

  final List<Person> people;
  final double maxRangeMeters;
  final void Function(Person) onTapPerson;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overlays = ref.watch(broadcastProvider.notifier).activeOverlays();
    return LayoutBuilder(
      builder: (context, constraints) {
        final double radarMaxWidth = constraints.maxWidth;
        final size = min(constraints.maxHeight, radarMaxWidth);
        final double innerSide = (size - ProximityConstants.radarOuterPaddingPx * 2).clamp(0, size);
        final double halfSide = innerSide / 2;

        // Precompute buckets for counts and placement
        final List<Person> b0 = [];
        final List<Person> b1 = [];
        final List<Person> b2 = [];
        final List<Person> b3 = [];
        for (final p in people) {
          switch (getBucketForDistance(p.distanceMeters)) {
            case 0:
              b0.add(p);
              break;
            case 1:
              b1.add(p);
              break;
            case 2:
              b2.add(p);
              break;
            default:
              b3.add(p);
              break;
          }
        }
        final List<int> bucketCounts = [b0.length, b1.length, b2.length, b3.length];

        // Distance segmented menu removed; allow all rings, focus per quadrant optional
        final Set<int> allowedRings = {0, 1, 2, 3};
        final Set<int> toggled = ref.watch(ringVisibilityProvider);
        final Set<int> visibleRings = toggled.intersection(allowedRings);
        final int? focused = ref.watch(focusQuadrantProvider);
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: Size.square(size),
                    painter: _QuadrantBackgroundPainter(
                      Theme.of(context).colorScheme.primary,
                      hiddenQuadrants: focused == null ? allowedRings.difference(visibleRings) : const <int>{},
                      outerPaddingPx: ProximityConstants.radarOuterPaddingPx,
                      showDividers: focused == null,
                    ),
                  ),
              
              if (focused == null) ...[
                // Corner toggle icons exactly at inner square corners
                for (final idx in [0, 1, 2, 3])
                  Transform.translate(
                    offset: () {
                      final bool left = idx == 0 || idx == 2;
                      final bool top = idx == 0 || idx == 1;
                      final double dx = left ? (-halfSide + ProximityConstants.cornerButtonSizePx / 2) : (halfSide - ProximityConstants.cornerButtonSizePx / 2);
                      final double dy = top ? (-halfSide + ProximityConstants.cornerButtonSizePx / 2) : (halfSide - ProximityConstants.cornerButtonSizePx / 2);
                      return Offset(dx, dy);
                    }(),
                    child: _CornerToggleButton(
                      index: idx,
                      isEnabled: visibleRings.contains(idx),
                      count: bucketCounts[idx],
                      sizePx: ProximityConstants.cornerButtonSizePx,
                      onToggle: () {
                        final current = ref.read(ringVisibilityProvider);
                        final next = {...current};
                        if (next.contains(idx)) {
                          next.remove(idx);
                        } else {
                          next.add(idx);
                        }
                        ref.read(ringVisibilityProvider.notifier).state = next;
                      },
                    ),
                  ),
              ],
              ...() {
                // Place each person into its quadrant; distribute on a grid
                List<Widget> layerChildren = [];

                double dotRadiusForCount(int n, double cellW, double cellH) {
                  final double base = n <= 8 ? ProximityConstants.defaultDotRadiusPx : (ProximityConstants.defaultDotRadiusPx - (n - 8) * 0.3).clamp(ProximityConstants.minDotRadiusPx, ProximityConstants.defaultDotRadiusPx);
                  final double maxByCell = (min(cellW, cellH) / 2 - 3).clamp(5.0, ProximityConstants.defaultDotRadiusPx);
                  return min(base, maxByCell);
                }

                Offset quadTopLeft(int idx) {
                  final double startX = -halfSide;
                  final double startY = -halfSide;
                  switch (idx) {
                    case 0:
                      return Offset(startX, startY);
                    case 1:
                      return Offset(0, startY);
                    case 2:
                      return Offset(startX, 0);
                    default:
                      return Offset(0, 0);
                  }
                }

                void placeGrid(
                  List<Person> ps,
                  int quadrantIdx, {
                  required double quadW,
                  required double quadH,
                  required Offset origin,
                  int? maxItems,
                  bool avoidCenter = false,
                }) {
                  if (ps.isEmpty) return;
                  ps.sort((a, b) => a.id.compareTo(b.id));
                  final List<Person> list = maxItems == null ? ps : ps.take(maxItems).toList();
                  final int n = list.length;
                  final int cols = max(1, (sqrt(n)).ceil());
                  final int rows = max(1, (n / cols).ceil());
                  final double cellW = quadW / cols;
                  final double cellH = quadH / rows;
                  final double dotR = dotRadiusForCount(n, cellW, cellH);
                  final Offset tl = origin;

                  for (int i = 0; i < n; i++) {
                    final int row = i ~/ cols;
                    final int col = i % cols;
                    double cx = tl.dx + col * cellW + cellW / 2;
                    double cy = tl.dy + row * cellH + cellH / 2;
                    if (avoidCenter && n == 1) {
                      final double minGapPx = 18 + dotR + 8; // icon radius + dot + margin
                      final double shift = max(minGapPx, quadH * 0.18);
                      cy -= shift; // move upward from center
                    }
                    final p = list[i];
                    layerChildren.add(
                      _AnimatedDot(
                        key: ValueKey(p.id),
                        offset: Offset(cx, cy),
                        child: _PersonDot(
                          person: p,
                          onTap: () => onTapPerson(p),
                          radiusPx: dotR,
                        ),
                      ),
                    );
                  }
                }

                if (focused == null) {
                  // Overview: limit to max items per quadrant and show "+X mehr" label when applicable
                  if (visibleRings.contains(0)) {
                    placeGrid(b0, 0, quadW: halfSide, quadH: halfSide, origin: quadTopLeft(0), maxItems: ProximityConstants.maxVisibleDotsPerQuadrant);
                    final int extra = b0.length - ProximityConstants.maxVisibleDotsPerQuadrant;
                    if (extra > 0) {
                      final labelSize = const Size(56, 22);
                      final Offset tl = quadTopLeft(0);
                      final Offset center = Offset(tl.dx + halfSide - labelSize.width / 2 - 6, tl.dy + halfSide - labelSize.height / 2 - 6);
                      layerChildren.add(
                        Transform.translate(
                          offset: center,
                          child: _MoreBadge(text: '+$extra mehr'),
                        ),
                      );
                    }
                  }
                  if (visibleRings.contains(1)) {
                    placeGrid(b1, 1, quadW: halfSide, quadH: halfSide, origin: quadTopLeft(1), maxItems: ProximityConstants.maxVisibleDotsPerQuadrant);
                    final int extra = b1.length - ProximityConstants.maxVisibleDotsPerQuadrant;
                    if (extra > 0) {
                      final labelSize = const Size(56, 22);
                      final Offset tl = quadTopLeft(1);
                      final Offset center = Offset(tl.dx + halfSide - labelSize.width / 2 - 6, tl.dy + halfSide - labelSize.height / 2 - 6);
                      layerChildren.add(
                        Transform.translate(
                          offset: center,
                          child: _MoreBadge(text: '+$extra mehr'),
                        ),
                      );
                    }
                  }
                  if (visibleRings.contains(2)) {
                    placeGrid(b2, 2, quadW: halfSide, quadH: halfSide, origin: quadTopLeft(2), maxItems: ProximityConstants.maxVisibleDotsPerQuadrant);
                    final int extra = b2.length - ProximityConstants.maxVisibleDotsPerQuadrant;
                    if (extra > 0) {
                      final labelSize = const Size(56, 22);
                      final Offset tl = quadTopLeft(2);
                      final Offset center = Offset(tl.dx + halfSide - labelSize.width / 2 - 6, tl.dy + halfSide - labelSize.height / 2 - 6);
                      layerChildren.add(
                        Transform.translate(
                          offset: center,
                          child: _MoreBadge(text: '+$extra mehr'),
                        ),
                      );
                    }
                  }
                  if (visibleRings.contains(3)) {
                    placeGrid(b3, 3, quadW: halfSide, quadH: halfSide, origin: quadTopLeft(3), maxItems: ProximityConstants.maxVisibleDotsPerQuadrant);
                    final int extra = b3.length - ProximityConstants.maxVisibleDotsPerQuadrant;
                    if (extra > 0) {
                      final labelSize = const Size(56, 22);
                      final Offset tl = quadTopLeft(3);
                      final Offset center = Offset(tl.dx + halfSide - labelSize.width / 2 - 6, tl.dy + halfSide - labelSize.height / 2 - 6);
                      layerChildren.add(
                        Transform.translate(
                          offset: center,
                          child: _MoreBadge(text: '+$extra mehr'),
                        ),
                      );
                    }
                  }
                } else {
                  final int idx = focused;
                  final List<Person> ps = [b0, b1, b2, b3][idx];
                  placeGrid(
                    ps,
                    idx,
                    quadW: innerSide,
                    quadH: innerSide,
                    origin: Offset(-innerSide / 2, -innerSide / 2),
                    maxItems: null,
                    avoidCenter: true,
                  );
                }
                // Make quadrant area tappable above content in overview
                if (focused == null) {
                  for (final idx in [0, 1, 2, 3]) {
                    layerChildren.add(
                      Transform.translate(
                        offset: () {
                          final bool left = idx == 0 || idx == 2;
                          final bool top = idx == 0 || idx == 1;
                          final double cx = left ? -halfSide / 2 : halfSide / 2;
                          final double cy = top ? -halfSide / 2 : halfSide / 2;
                          return Offset(cx, cy);
                        }(),
                        child: SizedBox(
                          width: halfSide,
                          height: halfSide,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => ref.read(focusQuadrantProvider.notifier).state = idx,
                          ),
                        ),
                      ),
                    );
                  }
                }

                final Widget content = Stack(alignment: Alignment.center, children: layerChildren);
                return [
                  AnimatedScale(
                    scale: focused == null ? 1.0 : 1.0, // keep scale stable; content area changes
                    duration: ProximityConstants.scaleAnimationDuration,
                    curve: Curves.easeInOutCubic,
                    child: KeyedSubtree(key: ValueKey('content-${focused ?? -1}'), child: content),
                  ),
                ];
              }(),
              if (focused != null)
                Positioned(
                  left: ProximityConstants.radarOuterPaddingPx + 8,
                  top: ProximityConstants.radarOuterPaddingPx + 8,
                  child: IconButton.filled(
                    onPressed: () => ref.read(focusQuadrantProvider.notifier).state = null,
                    icon: const Icon(Icons.arrow_back),
                    style: ButtonStyle(
                      padding: const WidgetStatePropertyAll(EdgeInsets.all(8)),
                      minimumSize: const WidgetStatePropertyAll(Size(36, 36)),
                      backgroundColor: WidgetStatePropertyAll(Theme.of(context).colorScheme.primary),
                      foregroundColor: WidgetStatePropertyAll(Theme.of(context).colorScheme.onPrimary),
                    ),
                  ),
                ),
              // Broadcast overlay texts
              Positioned.fill(
                child: IgnorePointer(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      for (final o in overlays)
                        _OverlayText(text: o.text, since: DateTime.now().difference(o.createdAt)),
                    ],
                  ),
                ),
              ),
              // Center indicator
              if (focused == null)
                const _CenterPulse()
              else
                IgnorePointer(
                  child: Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: SizedBox.square(
                        dimension: 36,
                        child: Center(
                          child: Icon(
                            getProximityIcon(
                              focused == 0 ? 1000.0 : 
                              focused == 1 ? 10000.0 : 
                              focused == 2 ? 50000.0 : 
                              300000.0
                            ),
                            size: 20,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Close Row children and Row
        ],
        );
      },
    );
  }
}

class _CornerToggleButton extends StatelessWidget {
  const _CornerToggleButton({required this.index, required this.isEnabled, required this.count, required this.sizePx, required this.onToggle});
  final int index;
  final bool isEnabled;
  final int count;
  final double sizePx;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    // Use fake distance to get icon for each quadrant
    final icon = getProximityIcon(
      index == 0 ? 1000.0 : 
      index == 1 ? 10000.0 : 
      index == 2 ? 50000.0 : 
      300000.0
    );
    final button = DecoratedBox(
      decoration: BoxDecoration(
        color: isEnabled ? color : Theme.of(context).colorScheme.surfaceContainerHighest,
        shape: BoxShape.circle,
        border: Border.all(color: isEnabled ? color : Theme.of(context).colorScheme.outline, width: 1.25),
      ),
      child: SizedBox.square(
        dimension: sizePx,
        child: Center(child: Icon(icon, size: sizePx * 0.42, color: isEnabled ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurfaceVariant)),
      ),
    );

    final withBadge = count > 0
        ? Badge(
            alignment: Alignment.bottomRight,
            backgroundColor: color,
            label: Text(count > 99 ? '99+' : '$count', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
            child: button,
          )
        : button;

    return GestureDetector(
      onTap: onToggle,
      child: withBadge,
    );
  }
}

class _MoreBadge extends StatelessWidget {
  const _MoreBadge({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.inverseSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onInverseSurface),
        ),
      ),
    );
  }
}

class _SideToggleButton extends StatelessWidget {
  const _SideToggleButton({required this.ringIndex, required this.isEnabled, required this.onToggle, this.count = 0});
  final int ringIndex;
  final bool isEnabled;
  final VoidCallback onToggle;
  final int count;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final icon = getProximityIcon(
      ringIndex == 0 ? 1000.0 : 
      ringIndex == 1 ? 10000.0 : 
      ringIndex == 2 ? 50000.0 : 
      300000.0
    );
    final button = DecoratedBox(
      decoration: BoxDecoration(
        color: isEnabled ? color.withValues(alpha: 0.15) : color.withValues(alpha: 0.06),
        shape: BoxShape.circle,
        border: Border.all(color: isEnabled ? color : color.withValues(alpha: 0.4), width: 1.25),
      ),
      child: SizedBox.square(
        dimension: 36,
        child: Center(child: Icon(icon, size: 18, color: isEnabled ? color : color.withValues(alpha: 0.5))),
      ),
    );

    final withBadge = count > 0
        ? Badge(
            alignment: Alignment.topRight,
            backgroundColor: color,
            label: Text(count > 99 ? '99+' : '$count'),
            child: button,
          )
        : button;

    return GestureDetector(
      onTap: onToggle,
      child: withBadge,
    );
  }
}

class _QuadrantBackgroundPainter extends CustomPainter {
  const _QuadrantBackgroundPainter(this.primary, {required this.hiddenQuadrants, required this.outerPaddingPx, this.showDividers = true});
  final Color primary;
  final Set<int> hiddenQuadrants;
  final double outerPaddingPx;
  final bool showDividers;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    final rect = Rect.fromLTWH((size.width - side) / 2 + outerPaddingPx, (size.height - side) / 2 + outerPaddingPx, side - 2 * outerPaddingPx, side - 2 * outerPaddingPx);

    final border = Paint()
      ..style = PaintingStyle.stroke
      ..color = primary.withValues(alpha: 0.5)
      ..strokeWidth = 2;
    canvas.drawRect(rect, border);

    if (showDividers) {
      final divider = Paint()
        ..style = PaintingStyle.stroke
        ..color = primary.withValues(alpha: 0.2)
        ..strokeWidth = 1;

      // Center vertical and horizontal lines
      final double midX = rect.left + rect.width / 2;
      final double midY = rect.top + rect.height / 2;
      canvas.drawLine(Offset(midX, rect.top), Offset(midX, rect.bottom), divider);
      canvas.drawLine(Offset(rect.left, midY), Offset(rect.right, midY), divider);
    }

    // Optional quadrant tinting when hidden
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = primary.withValues(alpha: 0.06);
    if (hiddenQuadrants.contains(0)) {
      canvas.drawRect(Rect.fromLTWH(rect.left, rect.top, rect.width / 2, rect.height / 2), fill);
    }
    final double midX = rect.left + rect.width / 2;
    final double midY = rect.top + rect.height / 2;
    if (hiddenQuadrants.contains(1)) {
      canvas.drawRect(Rect.fromLTWH(midX, rect.top, rect.width / 2, rect.height / 2), fill);
    }
    if (hiddenQuadrants.contains(2)) {
      canvas.drawRect(Rect.fromLTWH(rect.left, midY, rect.width / 2, rect.height / 2), fill);
    }
    if (hiddenQuadrants.contains(3)) {
      canvas.drawRect(Rect.fromLTWH(midX, midY, rect.width / 2, rect.height / 2), fill);
    }
  }

  @override
  bool shouldRepaint(covariant _QuadrantBackgroundPainter oldDelegate) {
    return oldDelegate.primary != primary || !setEquals(oldDelegate.hiddenQuadrants, hiddenQuadrants) || oldDelegate.outerPaddingPx != outerPaddingPx || oldDelegate.showDividers != showDividers;
  }
}

class _AnimatedDot extends StatefulWidget {
  const _AnimatedDot({super.key, required this.offset, required this.child});
  final Offset offset;
  final Widget child;

  @override
  State<_AnimatedDot> createState() => _AnimatedDotState();
}

class _AnimatedDotState extends State<_AnimatedDot> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _fade;
  Offset _prev = Offset.zero;

  @override
  void initState() {
    super.initState();
    _prev = widget.offset;
    _c = AnimationController(vsync: this, duration: ProximityConstants.dotAnimationDuration);
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    _c.forward();
  }

  @override
  void didUpdateWidget(covariant _AnimatedDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.offset != widget.offset) {
      _prev = oldWidget.offset;
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fade,
      builder: (context, _) {
        final lerp = Offset.lerp(_prev, widget.offset, _fade.value)!;
        return Transform.translate(
          offset: lerp,
          child: FadeTransition(opacity: _fade, child: widget.child),
        );
      },
    );
  }
}

class _PersonDot extends StatelessWidget {
  const _PersonDot({required this.person, required this.onTap, this.radiusPx = 12});
  final Person person;
  final VoidCallback onTap;
  final double radiusPx;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Use secondary palette for both states; offline uses lower-contrast styling
    final Color strokeColor = scheme.secondary;
    final double borderAlpha = person.isOnline ? 0.85 : 0.45;
    final double fillAlpha = person.isOnline ? 0.25 : 0.12;
    return Semantics(
      label: '${person.name}, ${person.distanceMeters.toStringAsFixed(0)} meters',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: strokeColor.withValues(alpha: fillAlpha),
            border: Border.all(color: strokeColor.withValues(alpha: borderAlpha), width: 1.5),
          ),
          child: CircleAvatar(
            radius: radiusPx,
            backgroundColor: strokeColor.withValues(alpha: fillAlpha),
            backgroundImage: person.avatarUrl != null && person.avatarUrl!.isNotEmpty
                ? NetworkImage(person.avatarUrl!)
                : null,
            onBackgroundImageError: (_, __) {},
            child: person.avatarUrl == null || person.avatarUrl!.isEmpty
                ? Text(person.name.characters.first, style: TextStyle(color: strokeColor))
                : null,
          ),
        ),
      ),
    );
  }
}

class _CenterPulse extends StatefulWidget {
  const _CenterPulse();

  @override
  State<_CenterPulse> createState() => _CenterPulseState();
}

class _CenterPulseState extends State<_CenterPulse> with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: ProximityConstants.pulseDuration)..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        final size = 16.0 + t * 16.0;
        final opacity = (1 - t).clamp(0.0, 1.0);
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle),
            ),
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: opacity), width: 2),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OverlayText extends StatelessWidget {
  const _OverlayText({required this.text, required this.since});
  final String text;
  final Duration since;

  @override
  Widget build(BuildContext context) {
    final progress = (since.inMilliseconds / ProximityConstants.broadcastLifetime.inMilliseconds).clamp(0.0, 1.0);
    final dy = -80 * progress;
    final opacity = (1.0 - progress);
    return Transform.translate(
      offset: Offset(0, dy),
      child: Opacity(
        opacity: opacity,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.inverseSurface.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            text,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onInverseSurface,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}


