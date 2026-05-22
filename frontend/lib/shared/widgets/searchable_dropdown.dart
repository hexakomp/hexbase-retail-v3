import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SearchableDropdown<T> extends StatefulWidget {
  final String label;
  final String hint;
  final T? value;
  final String Function(T) displayText;
  final Future<List<T>> Function(String query) onSearch;
  final void Function(T? value) onSelected;
  final Widget Function(T item)? itemBuilder;
  final bool enabled;

  const SearchableDropdown({
    super.key,
    required this.label,
    required this.hint,
    required this.displayText,
    required this.onSearch,
    required this.onSelected,
    this.value,
    this.itemBuilder,
    this.enabled = true,
  });

  @override
  State<SearchableDropdown<T>> createState() => _SearchableDropdownState<T>();
}

class _SearchableDropdownState<T> extends State<SearchableDropdown<T>> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  OverlayEntry? _overlay;
  List<T> _results = [];
  int _selectedIndex = -1;
  Timer? _debounce;
  bool _loading = false;

  /// Unique group id so that TapRegion recognises the overlay as "inside".
  late final Object _tapGroupId = UniqueKey();

  @override
  void initState() {
    super.initState();
    if (widget.value != null) {
      _controller.text = widget.displayText(widget.value as T);
    }
    // No focus listener — we rely on TapRegion.onTapOutside to close.
  }

  @override
  void didUpdateWidget(covariant SearchableDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep the text field in sync when the parent resets or changes the value.
    if (widget.value != oldWidget.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _controller.text = widget.value != null
            ? widget.displayText(widget.value as T)
            : '';
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    _closeOverlay();
    super.dispose();
  }

  void _search(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted) return;
      setState(() => _loading = true);
      try {
        final results = await widget.onSearch(query);
        if (mounted) {
          setState(() {
            _results = results;
            _selectedIndex = -1;
            _loading = false;
          });
          _openOverlay();
        }
      } catch (_) {
        if (mounted) setState(() => _loading = false);
      }
    });
  }

  void _openOverlay() {
    _closeOverlay();
    if (_results.isEmpty) return;

    final renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    // Capture theme colours before entering the OverlayEntry builder.
    final colorScheme = Theme.of(context).colorScheme;

    _overlay = OverlayEntry(
      builder: (ctx) {
        return Positioned(
          left: offset.dx,
          top: offset.dy + size.height + 4,
          width: size.width,
          child: TapRegion(
            // Same groupId as the text field — taps here are NOT "outside".
            groupId: _tapGroupId,
            child: ExcludeFocus(
              // Prevents Tab / arrow traversal from entering the dropdown.
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(4),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 250),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _results.length,
                    itemBuilder: (_, i) {
                      final isSelected = i == _selectedIndex;
                      return ListTile(
                        dense: true,
                        selected: isSelected,
                        // Visible background highlight for the selected row.
                        selectedTileColor: colorScheme.primaryContainer,
                        selectedColor: colorScheme.onPrimaryContainer,
                        hoverColor: colorScheme.primary.withOpacity(0.08),
                        title: widget.itemBuilder != null
                            ? widget.itemBuilder!(_results[i])
                            : Text(widget.displayText(_results[i])),
                        onTap: () => _select(_results[i]),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlay!);
  }

  void _closeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  void _select(T item) {
    _controller.text = widget.displayText(item);
    widget.onSelected(item);
    _closeOverlay();
    _results = [];
    _selectedIndex = -1;
    // Defer focus change until after onSelected's state update rebuilds the tree.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    if (_results.isEmpty) return;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(
        () =>
            _selectedIndex = (_selectedIndex + 1).clamp(0, _results.length - 1),
      );
      _overlay?.markNeedsBuild();
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(
        () =>
            _selectedIndex = (_selectedIndex - 1).clamp(0, _results.length - 1),
      );
      _overlay?.markNeedsBuild();
    } else if (event.logicalKey == LogicalKeyboardKey.enter &&
        _selectedIndex >= 0) {
      _select(_results[_selectedIndex]);
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      _closeOverlay();
    } else if (event.logicalKey == LogicalKeyboardKey.tab) {
      // Close overlay but let the Tab event propagate normally.
      _closeOverlay();
    }
  }

  @override
  Widget build(BuildContext context) {
    return TapRegion(
      groupId: _tapGroupId,
      // Any tap outside both the text field and the overlay closes the list.
      onTapOutside: (_) => _closeOverlay(),
      child: KeyboardListener(
        focusNode: FocusNode(skipTraversal: true),
        onKeyEvent: _handleKeyEvent,
        child: TextFormField(
          controller: _controller,
          focusNode: _focusNode,
          enabled: widget.enabled,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : const Icon(Icons.search, size: 18),
          ),
          onChanged: _search,
        ),
      ),
    );
  }
}
