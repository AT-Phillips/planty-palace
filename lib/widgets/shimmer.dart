import 'package:flutter/material.dart';

import '../styles/app_theme.dart';
import 'primitives.dart';

/// Wraps a skeleton layout (made of [SkeletonBox]es) and sweeps an animated
/// highlight across it - a modern "loading" shimmer in place of a spinner.
/// The moving band also makes waits *feel* shorter than a static placeholder.
class ShimmerLoading extends StatefulWidget {
  final Widget child;

  const ShimmerLoading({super.key, required this.child});

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final base = p.ground2;
    final highlight = Color.alphaBlend(
      p.ink.withValues(alpha: 0.06),
      base,
    );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final slide = (_controller.value * 2.0 - 1.0) * bounds.width * 1.5;
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [base, highlight, base],
              stops: const [0.3, 0.5, 0.7],
              transform: _SlideTransform(slide),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlideTransform extends GradientTransform {
  final double dx;

  const _SlideTransform(this.dx);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(dx, 0, 0);
}

/// A single opaque placeholder block, for use inside a [ShimmerLoading].
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadius borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.palette.ground2,
        borderRadius: borderRadius,
      ),
    );
  }
}

/// One placeholder row shaped like a search result (thumbnail + two text
/// lines), for the shimmering list shown while a search is in flight.
class SkeletonListTile extends StatelessWidget {
  const SkeletonListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const SkeletonBox(width: 44, height: 44),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(
                  width: MediaQuery.of(context).size.width * 0.5,
                  height: 12,
                ),
                const SizedBox(height: 8),
                const SkeletonBox(width: 90, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A full shimmering placeholder list, drop-in for a search screen's loading
/// state. Non-scrollable - it's meant to sit inside an [Expanded].
class SearchSkeletonList extends StatelessWidget {
  final int rows;

  const SearchSkeletonList({super.key, this.rows = 7});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: rows,
        itemBuilder: (_, __) => const SkeletonListTile(),
      ),
    );
  }
}

/// Skeleton for the photo grid on My Plants: square photo blocks with two
/// caption lines, matching the real tile's proportions so the layout does not
/// shift when content arrives.
class PlantGridSkeleton extends StatelessWidget {
  final int count;

  const PlantGridSkeleton({super.key, this.count = 6});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(Gap.screen, 4, Gap.screen, 16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.78,
        ),
        itemCount: count,
        itemBuilder:
            (_, __) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: SkeletonBox(
                    height: double.infinity,
                    width: double.infinity,
                    borderRadius: AppRadius.lgAll,
                  ),
                ),
                const SizedBox(height: 9),
                SkeletonBox(
                  width: MediaQuery.of(context).size.width * 0.24,
                  height: 11,
                ),
                const SizedBox(height: 6),
                const SkeletonBox(width: 62, height: 9),
              ],
            ),
      ),
    );
  }
}

/// Skeleton for the Care list: a ring-sized circle, two text lines, and the
/// trailing action disc.
class CareListSkeleton extends StatelessWidget {
  final int rows;

  const CareListSkeleton({super.key, this.rows = 6});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(Gap.screen, 4, Gap.screen, 16),
        itemCount: rows,
        itemBuilder:
            (_, __) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  const SkeletonBox(
                    width: 48,
                    height: 48,
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(
                          width: MediaQuery.of(context).size.width * 0.33,
                          height: 12,
                        ),
                        const SizedBox(height: 7),
                        const SkeletonBox(width: 104, height: 10),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const SkeletonBox(
                    width: 38,
                    height: 38,
                    borderRadius: BorderRadius.all(Radius.circular(19)),
                  ),
                ],
              ),
            ),
      ),
    );
  }
}

/// Skeleton for the Spaces hub: the tall hero banner followed by collapsed
/// section cards.
class SpacesSkeleton extends StatelessWidget {
  const SpacesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(Gap.screen, 8, Gap.screen, 16),
        children: const [
          SkeletonBox(height: 148, borderRadius: AppRadius.xlAll),
          SizedBox(height: 22),
          SkeletonBox(height: 74, borderRadius: AppRadius.lgAll),
          SizedBox(height: 12),
          SkeletonBox(height: 74, borderRadius: AppRadius.lgAll),
          SizedBox(height: 12),
          SkeletonBox(height: 74, borderRadius: AppRadius.lgAll),
        ],
      ),
    );
  }
}
