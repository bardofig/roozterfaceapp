import 'package:flutter/material.dart';
import 'package:roozterfaceapp/models/rooster_model.dart';
import 'package:roozterfaceapp/widgets/rooster_tile.dart';

class RoosterListView extends StatefulWidget {
  final List<RoosterModel> roosters;
  final Future<bool> Function(RoosterModel) onDelete;
  final Function(RoosterModel) onTap;
  final VoidCallback? onLoadMore;
  final bool isLoadingMore;

  const RoosterListView({
    super.key,
    required this.roosters,
    required this.onDelete,
    required this.onTap,
    this.onLoadMore,
    this.isLoadingMore = false,
  });

  @override
  State<RoosterListView> createState() => _RoosterListViewState();
}

class _RoosterListViewState extends State<RoosterListView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom && !widget.isLoadingMore && widget.onLoadMore != null) {
      widget.onLoadMore!();
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9); // Cargar al 90% del scroll
  }

  @override
  Widget build(BuildContext context) {
    if (widget.roosters.isEmpty && !widget.isLoadingMore) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "No hay ejemplares en esta categoría.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ),
      );
    }
    return ListView.builder(
      controller: _scrollController,
      // Añadimos padding para que el último elemento no sea tapado por el FAB
      padding: const EdgeInsets.only(bottom: 80.0, top: 8.0),
      // Optimización de rendimiento: altura fija para elementos
      itemExtent: 100.0,
      // +1 para el indicador de carga si es necesario
      itemCount: widget.roosters.length + (widget.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == widget.roosters.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final rooster = widget.roosters[index];
        return Dismissible(
          key: Key(rooster.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20.0),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (direction) => widget.onDelete(rooster),
          child: RoosterTile(
            rooster: rooster,
            onTap: () => widget.onTap(rooster),
          ),
        );
      },
    );
  }
}
