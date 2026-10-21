import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../theme/win_motion.dart';
import 'package:pdfrx/pdfrx.dart';
import '../../data/models.dart' show fmtXaf;
import '../../l10n/l10n.dart';
import '../../services/order_service.dart';
import '../../theme/win_colors.dart';
import '../../theme/win_theme.dart';
import '../../theme/win_typography.dart';
import '../../widgets/win_widgets.dart';

/// Historique de commandes (E39)  vraies données serveur (GET /api/orders),
/// statut, facture PDF consultable, remboursement demandable.
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<ApiOrder>? _orders;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final orders = await OrderService.instance.getOrders();
    if (mounted) setState(() => _orders = orders);
  }

  (BadgeColor, String) _statusInfo(String status) =>
      switch (status.toLowerCase()) {
        'completed' => (BadgeColor.success, context.l10n.shopOrderPaid),
        'pending' => (BadgeColor.warn, context.l10n.commonPending),
        'failed' => (BadgeColor.error, context.l10n.shopOrderFailed),
        'cancelled' => (BadgeColor.neutral, context.l10n.shopOrderCancelled),
        'refunded' => (BadgeColor.blue, context.l10n.shopOrderRefunded),
        'refund_requested' => (BadgeColor.warn, context.l10n.shopOrderRefundRequested),
        _ => (BadgeColor.neutral, status),
      };

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final orders = _orders;
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: s.onStrong),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(context.l10n.shopMyOrders, style: WinType.headlineS(s.onStrong)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_outlined, color: s.onStrong),
            onPressed: () {
              setState(() => _orders = null);
              _load();
            },
          ),
        ],
      ),
      body: orders == null
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.receipt_long_outlined, size: 64, color: s.onFaint),
                  const SizedBox(height: 12),
                  Text(context.l10n.shopNoOrders,
                      style: WinType.bodyM(s.onMuted)),
                ]))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final o = orders[i];
                      final (color, label) = _statusInfo(o.status);
                      return WinCard(
                        onTap: () => _showOrderDetail(context, o),
                        child: Row(children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: s.primaryContainer,
                              borderRadius: BorderRadius.circular(WinRadii.sm),
                            ),
                            child: Icon(Icons.receipt_long_outlined,
                                size: 22, color: s.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(o.orderNumber,
                                      style: WinType.titleM(s.onStrong)),
                                  const SizedBox(height: 2),
                                  Text(WinFormat.dateNumeric(o.createdAt),
                                      style: WinType.labelM(s.onMuted)),
                                ]),
                          ),
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${fmtXaf(o.totalAmount.round())} XAF',
                                    style: WinType.titleM(s.onStrong)),
                                const SizedBox(height: 4),
                                WinBadge(label, color: color),
                              ]),
                        ]),
                      );
                    },
                  ),
                ),
    );
  }

  void _showOrderDetail(BuildContext context, ApiOrder order) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _OrderDetailSheet(order: order, onChanged: _load),
    );
  }
}

class _OrderDetailSheet extends StatefulWidget {
  final ApiOrder order;
  final VoidCallback onChanged;
  const _OrderDetailSheet({required this.order, required this.onChanged});
  @override
  State<_OrderDetailSheet> createState() => _OrderDetailSheetState();
}

class _OrderDetailSheetState extends State<_OrderDetailSheet> {
  bool _refunding = false;

  Future<void> _requestRefund() async {
    setState(() => _refunding = true);
    final ok = await OrderService.instance.requestRefund(widget.order.id);
    if (!mounted) return;
    setState(() => _refunding = false);
    Navigator.pop(context);
    widget.onChanged();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? L10n.current.shopRefundSent
            : L10n.current.shopRefundFailed)));
  }

  void _viewInvoice() {
    Navigator.pop(context);
    Navigator.push(
        context,
        WinPageRoute(
            builder: (_) => _InvoiceViewerScreen(order: widget.order)));
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final o = widget.order;
    return Container(
      decoration: BoxDecoration(
        color: s.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(WinRadii.xl)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
                child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                  color: s.outline2,
                  borderRadius: BorderRadius.circular(WinRadii.full)),
            )),
            Text(o.orderNumber,
                style: WinType.archivo(size: 18, color: s.onStrong)),
            const SizedBox(height: 4),
            Text('${fmtXaf(o.totalAmount.round())} XAF',
                style: WinType.archivo(
                    size: 24, weight: FontWeight.w700, color: s.primary)),
            const SizedBox(height: 16),
            if (o.items.isNotEmpty) ...[
              Text(context.l10n.shopItems, style: WinType.labelM(s.onStrong)),
              const SizedBox(height: 8),
              ...o.items.map((i) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(children: [
                      Expanded(
                          child: Text(i.title ?? context.l10n.shopSubjectFallback(i.subjectId),
                              style: WinType.bodyM(s.onSurface))),
                      Text('${fmtXaf(i.price.round())} XAF',
                          style: WinType.bodyM(s.onMuted)),
                    ]),
                  )),
              const SizedBox(height: 12),
            ],
            WinButton(context.l10n.shopViewInvoice,
                block: true,
                icon: Icons.picture_as_pdf_outlined,
                onTap: _viewInvoice),
            if (o.isCompleted) ...[
              const SizedBox(height: 10),
              WinButton(context.l10n.shopRequestRefund,
                  block: true,
                  variant: WinButtonVariant.outline,
                  loading: _refunding,
                  onTap: _refunding ? null : _requestRefund),
            ],
          ]),
    );
  }
}

/// Visionneuse de facture  mêmes octets en mémoire uniquement, jamais écrits
/// sur le disque (même politique que document_viewer_screen.dart).
class _InvoiceViewerScreen extends StatefulWidget {
  final ApiOrder order;
  const _InvoiceViewerScreen({required this.order});
  @override
  State<_InvoiceViewerScreen> createState() => _InvoiceViewerScreenState();
}

class _InvoiceViewerScreenState extends State<_InvoiceViewerScreen> {
  Uint8List? _bytes;
  bool _loading = true;
  bool _error = false;
  late final String _sourceName =
      'winplus-invoice-${widget.order.id}-${DateTime.now().microsecondsSinceEpoch}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    final bytes = await OrderService.instance.getInvoiceBytes(widget.order.id);
    if (!mounted) return;
    setState(() {
      _bytes = bytes == null ? null : Uint8List.fromList(bytes);
      _loading = false;
      _error = bytes == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.surface,
        iconTheme: IconThemeData(color: s.onStrong),
        title: Text(context.l10n.shopInvoiceTitle(widget.order.orderNumber),
            style: WinType.titleM(s.onStrong)),
      ),
      body: SafeArea(child: _buildBody(s)),
    );
  }

  Widget _buildBody(WinScheme s) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error || _bytes == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.picture_as_pdf_outlined, size: 56, color: s.onFaint),
            const SizedBox(height: 16),
            Text(context.l10n.shopInvoiceLoadFailed,
                style: WinType.bodyM(s.onMuted)),
            const SizedBox(height: 16),
            WinButton(context.l10n.commonRetry, icon: Icons.refresh, onTap: _load),
          ]),
        ),
      );
    }
    return PdfViewer.data(
      _bytes!,
      sourceName: _sourceName,
      params: PdfViewerParams(backgroundColor: s.bg),
    );
  }
}
