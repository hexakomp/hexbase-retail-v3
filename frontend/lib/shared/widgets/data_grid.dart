import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef CellBuilder =
    Widget Function(BuildContext context, int row, int col, bool hasFocus);

class DataGrid extends StatefulWidget {
  final int columnCount;
  final List<String> columnHeaders;
  final List<Map<String, dynamic>> rows;
  final CellBuilder cellBuilder;
  final VoidCallback? onAddRow;
  final List<double>? columnWidths;

  const DataGrid({
    super.key,
    required this.columnCount,
    required this.columnHeaders,
    required this.rows,
    required this.cellBuilder,
    this.onAddRow,
    this.columnWidths,
  });

  @override
  State<DataGrid> createState() => _DataGridState();
}

class _DataGridState extends State<DataGrid> {
  int _focusedRow = 0;
  int _focusedCol = 0;

  void _moveFocus(int row, int col) {
    if (row < 0 || col < 0) return;
    if (row >= widget.rows.length) {
      widget.onAddRow?.call();
      return;
    }
    if (col >= widget.columnCount) {
      _moveFocus(row + 1, 0);
      return;
    }
    setState(() {
      _focusedRow = row;
      _focusedCol = col;
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.tab) {
            _moveFocus(_focusedRow, _focusedCol + 1);
          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            _moveFocus(_focusedRow, _focusedCol + 1);
          } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            _moveFocus(_focusedRow, _focusedCol - 1);
          } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            _moveFocus(_focusedRow + 1, _focusedCol);
          } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            _moveFocus(_focusedRow - 1, _focusedCol);
          }
        }
      },
      child: Column(
        children: [
          // Header row
          _buildHeaderRow(),
          // Data rows
          ...List.generate(widget.rows.length, (rowIndex) {
            return _buildDataRow(rowIndex);
          }),
        ],
      ),
    );
  }

  Widget _buildHeaderRow() {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: List.generate(widget.columnHeaders.length, (i) {
          final width = widget.columnWidths?.elementAtOrNull(i);
          return SizedBox(
            width: width,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Text(
                widget.columnHeaders[i],
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDataRow(int rowIndex) {
    return IntrinsicHeight(
      child: Row(
        children: List.generate(widget.columnCount, (colIndex) {
          final hasFocus = _focusedRow == rowIndex && _focusedCol == colIndex;
          final width = widget.columnWidths?.elementAtOrNull(colIndex);
          return GestureDetector(
            onTap: () => _moveFocus(rowIndex, colIndex),
            child: SizedBox(
              width: width,
              child: widget.cellBuilder(context, rowIndex, colIndex, hasFocus),
            ),
          );
        }),
      ),
    );
  }
}
