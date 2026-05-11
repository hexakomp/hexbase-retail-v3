import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final keyboardNavigationProvider =
    Provider.autoDispose<KeyboardNavigationController>((ref) {
      final controller = KeyboardNavigationController();
      ref.onDispose(controller.dispose);
      return controller;
    });

class KeyboardNavigationController {
  bool tabAsEnter = false;

  final List<FocusNode> _nodes = [];

  FocusNode register() {
    final node = FocusNode();
    _nodes.add(node);
    return node;
  }

  void unregister(FocusNode node) {
    _nodes.remove(node);
    node.dispose();
  }

  void focusNext(FocusNode current) {
    final index = _nodes.indexOf(current);
    if (index >= 0 && index < _nodes.length - 1) {
      _nodes[index + 1].requestFocus();
    }
  }

  void dispose() {
    for (final node in _nodes) {
      node.dispose();
    }
    _nodes.clear();
  }
}
