import 'dart:math';

import 'package:flutter/material.dart';

/// Entrypoint of the application.
void main() {
  runApp(const MyApp());
}

/// [Widget] building the [MaterialApp].
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Dock(
            items: const [
              DockItem(icon: Icons.person, label: 'Profile'),
              DockItem(icon: Icons.message, label: 'Messages'),
              DockItem(icon: Icons.call, label: 'Calls'),
              DockItem(icon: Icons.camera, label: 'Camera'),
              DockItem(icon: Icons.photo, label: 'Photos'),
            ],
            builder: (item, callbacks) => DockItemWidget(
              item: item,
              isPlaceholder: callbacks.isPlaceholder(item),
              onDragStarted: () => callbacks.onDragStarted(item),
              onDraggableCanceled: (velocity, offset) =>
                  callbacks.onDraggableCanceled(velocity, offset),
              onDragCompleted: () => callbacks.onDragCompleted(item),
            ),
          ),
        ),
      ),
    );
  }
}

/// Represents a dock item with an icon and label.
class DockItem {
  final IconData icon;
  final String label;

  const DockItem({required this.icon, required this.label});
}

/// Represents callbacks used by a dock item.
class DockItemCallbacks<T> {
  final bool Function(T item) isPlaceholder;
  final void Function(T item) onDragStarted;
  final Function(Velocity velocity, Offset offset) onDraggableCanceled;
  final void Function(T item) onDragCompleted;

  DockItemCallbacks({
    required this.isPlaceholder,
    required this.onDragStarted,
    required this.onDraggableCanceled,
    required this.onDragCompleted,
  });
}

/// Displays a single item in the dock.
class DockItemWidget extends StatefulWidget {
  final DockItem item;
  final bool isPlaceholder;
  final VoidCallback onDragStarted;
  final Function(Velocity velocity, Offset offset) onDraggableCanceled;
  final VoidCallback onDragCompleted;

  const DockItemWidget({
    super.key,
    required this.item,
    this.isPlaceholder = false,
    required this.onDragStarted,
    required this.onDraggableCanceled,
    required this.onDragCompleted,
  });

  @override
  State<DockItemWidget> createState() => _DockItemWidgetState();
}

class _DockItemWidgetState extends State<DockItemWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDragStarted() {
    widget.onDragStarted();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isPlaceholder) {
      return const SizedBox(width: 64, height: 64);
    }

    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _isHovered = true;
          _controller.forward();
        });
      },
      onExit: (_) {
        setState(() {
          _isHovered = false;
          _controller.reverse();
        });
      },
      child: Draggable<DockItem>(
        data: widget.item,
        feedback: Material(
          color: Colors.transparent,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors
                  .primaries[widget.item.hashCode % Colors.primaries.length],
            ),
            child: Icon(widget.item.icon, color: Colors.white, size: 24),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.3,
          child: _buildStackedContent(),
        ),
        onDragStarted: _handleDragStarted,
        onDraggableCanceled: widget.onDraggableCanceled,
        onDragCompleted: widget.onDragCompleted,
        child: _buildStackedContent(),
      ),
    );
  }

  Widget _buildStackedContent() {
    final shouldShowLabel = _isHovered && !widget.isPlaceholder;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          tween: Tween<double>(begin: 0, end: _isHovered ? -12 : 0),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, value),
              child: child,
            );
          },
          child: Container(
            width: 48,
            height: 48,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors
                  .primaries[widget.item.hashCode % Colors.primaries.length],
            ),
            child: Icon(widget.item.icon, color: Colors.white, size: 20),
          ),
        ),
        if (shouldShowLabel)
          Positioned(
            bottom: 72,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: Container(
                    key: const ValueKey("label"),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.item.label,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
                CustomPaint(
                  size: const Size(16, 8),
                  painter: TrianglePainter(color: Colors.black87),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Draws a downward-pointing triangle arrow.
class TrianglePainter extends CustomPainter {
  final Color color;

  TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, 0);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Dock of the reorderable [items].
class Dock<T extends Object> extends StatefulWidget {
  const Dock({
    super.key,
    this.items = const [],
    required this.builder,
  });

  /// Initial [T] items to put in this [Dock].
  final List<T> items;

  /// Builder building the provided [T] item.
  final Widget Function(T item, DockItemCallbacks<T> callbacks) builder;

  @override
  State<Dock<T>> createState() => _DockState<T>();
}

/// State of the [Dock] used to manipulate the [_items].
class _DockState<T extends Object> extends State<Dock<T>>
    with TickerProviderStateMixin {
  /// [T] items being manipulated.
  late final List<T> _items = widget.items.toList();

  final GlobalKey _rowKey = GlobalKey();
  T? _draggedItem;
  int? _placeholderIndex;
  Offset? _cursorGlobalOffset;
  int? _originalIndex;
  bool _isDroppingOutside = false;
  OverlayEntry? _returnOverlayEntry;
  late AnimationController _returnAnimationController;
  late Animation<Offset> _returnAnimation;

  @override
  void initState() {
    super.initState();
    _returnAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _returnAnimationController.dispose();
    _returnOverlayEntry?.remove();
    super.dispose();
  }

  void updateCursor(Offset globalPosition) {
    setState(() {
      _cursorGlobalOffset = globalPosition;
    });
  }

  void startDragging(T item) {
    final oldIndex = _items.indexOf(item);
    if (oldIndex == -1) return;
    setState(() {
      _draggedItem = item;
      _originalIndex = oldIndex;
      _items.removeAt(oldIndex);
      _placeholderIndex = oldIndex;
    });
  }

  void cancelDragging() {
    if (_draggedItem == null || _originalIndex == null) return;
    setState(() {
      _items.insert(_originalIndex!, _draggedItem!);
      _draggedItem = null;
      _placeholderIndex = null;
      _originalIndex = null;
    });
  }

  void onDraggableCanceled(T item, Velocity velocity, Offset offset) {
    if (_isDroppingOutside && _originalIndex != null) {
      startReturnAnimation(offset, _originalIndex!);
    } else {
      setState(() {
        _draggedItem = null;
        _placeholderIndex = null;
        _originalIndex = null;
      });
    }
  }

  void onDragCompleted(T item) {
    setState(() {
      _draggedItem = null;
      _placeholderIndex = null;
      _originalIndex = null;
    });
  }

  void startReturnAnimation(Offset dropPosition, int originalIndex) {
    final RenderBox? rowBox =
        _rowKey.currentContext?.findRenderObject() as RenderBox?;
    if (rowBox == null) return;
    final rowOffset = rowBox.localToGlobal(Offset.zero);
    const itemWidth = 64.0;
    final totalWidth = widget.items.length * itemWidth;
    final startX = rowOffset.dx + (rowBox.size.width - totalWidth) / 2;
    final targetX = startX + (originalIndex * itemWidth);
    final targetY = rowOffset.dy + (rowBox.size.height - itemWidth) / 2;
    _returnAnimation = Tween<Offset>(
      begin: dropPosition,
      end: Offset(targetX, targetY),
    ).animate(CurvedAnimation(
      parent: _returnAnimationController,
      curve: Curves.easeOutBack,
    ));
    _returnOverlayEntry?.remove();
    _returnOverlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            AnimatedBuilder(
              animation: _returnAnimationController,
              builder: (context, child) {
                updateCursor(_returnAnimation.value);
                return Positioned(
                  left: _returnAnimation.value.dx,
                  top: _returnAnimation.value.dy,
                  child: _buildReturnAnimationWidget(),
                );
              },
            ),
          ],
        );
      },
    );
    Overlay.of(context).insert(_returnOverlayEntry!);
    _returnAnimationController.forward().then((_) {
      _returnOverlayEntry?.remove();
      _returnOverlayEntry = null;
      _returnAnimationController.reset();
      setState(() {
        if (_draggedItem != null && _originalIndex != null) {
          _items.insert(_originalIndex!, _draggedItem!);
        }
        _draggedItem = null;
        _placeholderIndex = null;
        _originalIndex = null;
        _cursorGlobalOffset = null;
      });
    });
  }

  Widget _buildReturnAnimationWidget() {
    if (_draggedItem is DockItem) {
      final item = _draggedItem as DockItem;
      return SizedBox(
        width: 64,
        height: 64,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.primaries[item.hashCode % Colors.primaries.length],
          ),
          child: Icon(item.icon, color: Colors.white, size: 24),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  double _getScale(int index) {
    if (_cursorGlobalOffset == null) return 1.0;
    final rowBox = _rowKey.currentContext?.findRenderObject() as RenderBox?;
    if (rowBox == null) return 1.0;
    const baseItemWidth = 64.0;
    final rowOffset = rowBox.localToGlobal(Offset.zero);
    final xCenterOfDock = rowOffset.dx + rowBox.size.width / 2;
    final totalWidth = widget.items.length * baseItemWidth;
    final leftOfDockSlots = xCenterOfDock - totalWidth / 2;
    final itemCenterX = leftOfDockSlots + (index + 0.5) * baseItemWidth;
    final itemCenterY = rowOffset.dy + rowBox.size.height / 2;
    final itemCenter = Offset(itemCenterX, itemCenterY);
    final distance = (_cursorGlobalOffset! - itemCenter).distance;
    const sigma = 80.0;
    const maxScale = 1.3;
    const baseScale = 1.0;
    return baseScale +
        (maxScale - baseScale) * exp(-pow(distance, 2) / (2 * pow(sigma, 2)));
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (event) => updateCursor(event.position),
      child: Stack(
        children: [
          Positioned.fill(
            child: DragTarget<T>(
              onWillAcceptWithDetails: (_) => true,
              onMove: (details) => movePlaceholder(details.offset),
              onAcceptWithDetails: (_) => acceptDrag(),
              builder: (_, __, ___) => const SizedBox.expand(),
            ),
          ),
          Center(
            child: Container(
              key: _rowKey,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.black12,
              ),
              padding: const EdgeInsets.all(4),
              height: 80,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return DragTarget<T>(
                    onWillAcceptWithDetails: (_) => true,
                    onMove: (details) {
                      updateCursor(details.offset);
                      movePlaceholder(details.offset);
                    },
                    onLeave: (_) {
                      if (_cursorGlobalOffset != null) {
                        updateCursor(_cursorGlobalOffset!);
                      }
                    },
                    onAcceptWithDetails: (_) => acceptDrag(),
                    builder: (context, candidateData, rejectedData) {
                      List<Widget> children = [];
                      final bool needsPlaceholder =
                          _draggedItem != null && _placeholderIndex != null;
                      final totalCount =
                          _items.length + (needsPlaceholder ? 1 : 0);

                      for (int i = 0; i < totalCount; i++) {
                        if (needsPlaceholder && i == _placeholderIndex) {
                          children.add(const SizedBox(width: 64, height: 64));
                          continue;
                        }
                        final itemIndex =
                            (needsPlaceholder && i > _placeholderIndex!)
                                ? i - 1
                                : i;
                        final dockItem = _items[itemIndex] as DockItem;
                        children.add(
                          AnimatedScale(
                            scale: _getScale(i),
                            duration: const Duration(milliseconds: 100),
                            curve: Curves.easeOutCubic,
                            child: widget.builder(
                              dockItem as T,
                              DockItemCallbacks<T>(
                                isPlaceholder: (item) => item == _draggedItem,
                                onDragStarted: (item) => startDragging(item),
                                onDraggableCanceled: (vel, off) =>
                                    onDraggableCanceled(
                                        dockItem as T, vel, off),
                                onDragCompleted: (item) =>
                                    onDragCompleted(item),
                              ),
                            ),
                          ),
                        );
                      }
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: children,
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void movePlaceholder(Offset globalPosition) {
    if (_draggedItem == null) return;
    final rowBox = _rowKey.currentContext?.findRenderObject() as RenderBox?;
    if (rowBox == null) return;
    final rowOffset = rowBox.localToGlobal(Offset.zero);
    final rect = Rect.fromLTWH(
      rowOffset.dx,
      rowOffset.dy,
      rowBox.size.width,
      rowBox.size.height,
    );
    if (!rect.contains(globalPosition)) {
      _isDroppingOutside = true;
      return;
    }
    _isDroppingOutside = false;
    final localPos = rowBox.globalToLocal(globalPosition);
    final newIndex = _calculateDropIndex(localPos);
    setState(() {
      _placeholderIndex = newIndex;
    });
  }

  void acceptDrag() {
    if (_draggedItem == null || _placeholderIndex == null) return;
    setState(() {
      _items.insert(_placeholderIndex!, _draggedItem!);
      _draggedItem = null;
      _placeholderIndex = null;
      _originalIndex = null;
      _isDroppingOutside = false;
    });
  }

  int _calculateDropIndex(Offset localPosition) {
    const slotWidth = 64.0;
    final rowWidth = widget.items.length * slotWidth;
    final rowBox = _rowKey.currentContext?.findRenderObject() as RenderBox?;
    if (rowBox == null) return 0;
    final containerWidth = rowBox.size.width;
    final dockLeft = (containerWidth - rowWidth) / 2.0;
    final positionInDock = localPosition.dx - dockLeft;
    final idx = (positionInDock / slotWidth).floor();
    return idx.clamp(0, widget.items.length);
  }
}
