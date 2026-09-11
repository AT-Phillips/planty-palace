import 'package:flutter/material.dart';

import '../styles/app_theme.dart';
import 'primitives.dart';

/// The app's search input: a soft filled pill with a leading magnifier and a
/// clear button that appears once there is text.
///
/// Deliberately does *not* use the global [InputDecorationTheme] the forms
/// use. That theme is an outlined 20dp-radius box, which is right for a text
/// field you fill in but reads as a form control rather than a search affordance -
/// the outline draws as much attention as the content. A borderless filled
/// pill is the shape search has settled on across modern mobile apps, and it
/// lets the results below carry the visual weight.
class SearchField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;

  const SearchField({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
  });

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() => setState(() {});

  void _clear() {
    widget.controller.clear();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final hasText = widget.controller.text.isNotEmpty;

    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: p.ground2,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          Icon(Icons.search_rounded, size: 19, color: p.inkFaint),
          const SizedBox(width: 9),
          Expanded(
            child: TextField(
              controller: widget.controller,
              onChanged: widget.onChanged,
              textInputAction: TextInputAction.search,
              style: TextStyle(fontSize: 14.5, color: p.ink),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: TextStyle(fontSize: 14.5, color: p.inkFaint),
                // Strip the global outlined/filled decoration entirely - the
                // surrounding pill is the visual, the field itself is bare.
                isDense: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (hasText)
            GestureDetector(
              onTap: _clear,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(
                  Icons.cancel_rounded,
                  size: 17,
                  color: p.inkFaint,
                ),
              ),
            )
          else
            const SizedBox(width: 14),
        ],
      ),
    );
  }
}

/// A filter bar that scrolls horizontally rather than overflowing.
///
/// The filter controls previously sat in a fixed `Row` with a `Spacer`. On a
/// narrow device three pills ("Overdue", a Space picker, a sort picker) are
/// wider than the screen, which a fixed Row resolves by throwing a layout
/// overflow. Scrolling absorbs any number of controls at any text size -
/// including the large accessibility sizes, where even two pills can overrun.
class FilterBar extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  const FilterBar({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.fromLTRB(Gap.screen, 0, Gap.screen, 12),
  });

  @override
  Widget build(BuildContext context) {
    // The infinite width is load-bearing. A horizontal SingleChildScrollView
    // sitting in a Column with the default centre cross-alignment shrinks to
    // its content and is then centred, so the pills no longer lined up with
    // the search field above them. Forcing full width makes the scroll view
    // fill the row and lay its content out from the left edge.
    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: padding,
        child: Row(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}
