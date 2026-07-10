import 'package:flutter/material.dart';

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
    final scheme = Theme.of(context).colorScheme;
    final base = scheme.surfaceContainerHighest;
    final highlight = Color.alphaBlend(
      scheme.onSurface.withValues(alpha: 0.06),
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
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
