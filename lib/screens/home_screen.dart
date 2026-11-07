import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/database.dart';
import '../models/debt.dart';
import '../services/pdf_service.dart';
import 'debt_form_screen.dart';
import 'payment_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> {
  List<Debt> _debts = [];
  String _filter = 'الكل';
  String _search = '';
  String _currency = 'USD';
  bool _loading = true;
  final _searchController = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _searchController.dispose(); super.dispose(); }
  Future<void> _load() async {
    final data = await AppDatabase.instance.allDebts();
    if (mounted) setState(() { _debts = data; _loading = false; });
  }
  double get _total => _debts.where((d) => d.currency == _currency).fold(0, (s,d) => s + d.amount);
  double get _paid => _debts.where((d) => d.currency == _currency).fold(0, (s,d) => s + d.paid);
  double get _remaining => _debts.where((d) => d.currency == _currency).fold(0, (s,d) => s + d.remaining);
  List<Debt> get _visible => _debts.where((d) {
    final match = d.person.toLowerCase().contains(_search.toLowerCase());
    final status = _filter == 'الكل' || (_filter == 'غير مسدد' && d.paid == 0) ||
      (_filter == 'مسدد جزئياً' && d.paid > 0 && d.remaining > 0) || (_filter == 'مسدد' && d.remaining == 0);
    return match && status;
  }).toList();

  Future<void> _form([Debt? debt]) async {
    final changed = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => DebtFormScreen(debt: debt)));
    if (changed == true) _load();
  }
  Future<void> _payment(Debt debt) async {
    final changed = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => PaymentScreen(debt: debt)));
    if (changed == true) _load();
  }
  String _money(double n) => NumberFormat('#,##0.00').format(n);
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('دَيْني', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: .3)),
      actions: [IconButton(tooltip: 'تصدير PDF', onPressed: _debts.isEmpty ? null : () => PdfService.exportDebts(_debts, _currency), icon: const Icon(Icons.picture_as_pdf_outlined))]),
    floatingActionButton: FloatingActionButton.extended(onPressed: () => _form(), icon: const Icon(Icons.add), label: const Text('إضافة دين')),
    body: _loading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(
      onRefresh: _load,
      child: ListView(padding: const EdgeInsets.fromLTRB(18, 8, 18, 100), children: [
        _summary(),
        const SizedBox(height: 20),
        TextField(controller: _searchController, onChanged: (v) => setState(() => _search = v),
          decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'ابحث باسم الشخص أو الجهة', suffixIcon: Icon(Icons.tune))),
        const SizedBox(height: 12),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: ['الكل','غير مسدد','مسدد جزئياً','مسدد'].map((f) =>
          Padding(padding: const EdgeInsetsDirectional.only(end: 8), child: ChoiceChip(label: Text(f), selected: _filter == f, onSelected: (_) => setState(() => _filter = f)))).toList())),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('قائمة الديون', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('${_visible.length} سجل', style: TextStyle(color: Colors.white.withValues(alpha: .55))),
        ]),
        const SizedBox(height: 8),
        if (_visible.isEmpty) _empty() else ..._visible.map(_debtCard),
      ]),
    ),
  );

  Widget _summary() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(26),
      gradient: const LinearGradient(colors: [Color(0xFF5148D8), Color(0xFF242E68)], begin: Alignment.topRight, end: Alignment.bottomLeft),
      boxShadow: [BoxShadow(color: const Color(0xFF5148D8).withValues(alpha: .25), blurRadius: 24, offset: const Offset(0, 10))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [const Icon(Icons.account_balance_wallet_outlined), const SizedBox(width: 8), const Text('ملخص التزاماتك'), const Spacer(),
        PopupMenuButton<String>(initialValue: _currency, onSelected: (v) => setState(() => _currency = v),
          itemBuilder: (_) => ['USD','EUR','TRY','SYP','JOD','SAR','AED'].map((v) => PopupMenuItem(value: v, child: Text(v))).toList(),
          child: Chip(label: Text(_currency), visualDensity: VisualDensity.compact))]),
      const SizedBox(height: 18),
      const Text('إجمالي المبلغ المتبقي ($_currency)', style: TextStyle(color: Colors.white70)),
      const SizedBox(height: 4),
      Text('${_money(_remaining)} $_currency', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
      const SizedBox(height: 20),
      Row(children: [
        Expanded(child: _miniStat('إجمالي الديون', _money(_total))),
        Container(width: 1, height: 42, color: Colors.white24),
        Expanded(child: Padding(padding: const EdgeInsetsDirectional.only(start: 16), child: _miniStat('ما تم سداده', _money(_paid)))),
      ]),
      const SizedBox(height: 14),
      ClipRRect(borderRadius: BorderRadius.circular(20), child: LinearProgressIndicator(value: _total == 0 ? 0 : (_paid/_total).clamp(0,1), minHeight: 7, backgroundColor: Colors.white24, color: const Color(0xFF73E0B2))),
      const SizedBox(height: 6),
      Text(_total == 0 ? 'ابدأ بإضافة أول دين' : 'تم سداد ${(_paid/_total*100).clamp(0,100).toStringAsFixed(0)}% من إجمالي الديون', style: const TextStyle(fontSize: 11, color: Colors.white70)),
    ]),
  );
  Widget _miniStat(String title, String value) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
    const SizedBox(height: 4), Text('$value $_currency', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
  ]);
  Widget _debtCard(Debt d) {
    final settled = d.remaining == 0;
    final color = settled ? const Color(0xFF5ED6A2) : (d.paid > 0 ? const Color(0xFFFFC56D) : const Color(0xFFFF7D8D));
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(padding: const EdgeInsets.all(14), child: Column(children: [
        Row(children: [
          CircleAvatar(backgroundColor: color.withValues(alpha: .14), child: Icon(Icons.person_outline, color: color)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(d.person, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(d.dueDate == null ? 'دون تاريخ استحقاق' : 'الاستحقاق: ${DateFormat('yyyy/MM/dd').format(d.dueDate!)}',
              style: TextStyle(color: Colors.white.withValues(alpha: .55), fontSize: 11)),
          ])),
          PopupMenuButton<String>(onSelected: (v) async {
            if (v == 'edit') _form(d);
            if (v == 'delete') {
              final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
                title: const Text('حذف الدين؟'), content: const Text('سيتم حذف سجل الدفعات المرتبط به أيضاً.'),
                actions: [TextButton(onPressed: () => Navigator.pop(c,false), child: const Text('إلغاء')),
                  FilledButton(onPressed: () => Navigator.pop(c,true), child: const Text('حذف'))]));
              if (ok == true) { await AppDatabase.instance.deleteDebt(d.id!); _load(); }
            }
          }, itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('تعديل')),
            PopupMenuItem(value: 'delete', child: Text('حذف')),
          ]),
        ]),
        const Divider(height: 22),
        Row(children: [
          Expanded(child: _amountLabel('المبلغ الأصلي', '${_money(d.amount)} ${d.currency}')),
          Expanded(child: _amountLabel('المتبقي', '${_money(d.remaining)} ${d.currency}')),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: color.withValues(alpha: .13), borderRadius: BorderRadius.circular(20)), child: Text(d.status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold))),
        ]),
        if (d.note.isNotEmpty) Align(alignment: AlignmentDirectional.centerStart, child: Padding(padding: const EdgeInsets.only(top: 10), child: Text(d.note, style: TextStyle(color: Colors.white.withValues(alpha: .55), fontSize: 12)))),
        if (!settled) Align(alignment: AlignmentDirectional.centerStart, child: Padding(padding: const EdgeInsets.only(top: 10), child: TextButton.icon(onPressed: () => _payment(d), icon: const Icon(Icons.add_card), label: const Text('تسجيل دفعة')))),
      ])),
    );
  }
  Widget _amountLabel(String label, String value) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: .55))),
    const SizedBox(height: 3), Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
  ]);
  Widget _empty() => Padding(padding: const EdgeInsets.only(top: 55), child: Column(children: [
    Icon(Icons.receipt_long_outlined, size: 58, color: Colors.white.withValues(alpha: .25)),
    const SizedBox(height: 12), const Text('لا توجد ديون هنا', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
    const SizedBox(height: 5), Text('أضف ديناً جديداً لتبدأ تنظيم التزاماتك', style: TextStyle(color: Colors.white.withValues(alpha: .5))),
  ]));
}
