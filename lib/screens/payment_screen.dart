import 'package:flutter/material.dart';
import '../data/database.dart';
import '../models/debt.dart';
import '../models/payment.dart';

class PaymentScreen extends StatefulWidget {
  final Debt debt;
  const PaymentScreen({super.key, required this.debt});
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}
class _PaymentScreenState extends State<PaymentScreen> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  List<Payment> _payments = [];
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async { final p = await AppDatabase.instance.paymentsFor(widget.debt.id!); if (mounted) setState(() => _payments = p); }
  Future<void> _add() async {
    final value = double.tryParse(_amount.text);
    if (value == null || value <= 0 || value > widget.debt.remaining) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تحقق من المبلغ؛ يجب ألا يتجاوز المتبقي.'))); return;
    }
    await AppDatabase.instance.addPayment(Payment(debtId: widget.debt.id!, amount: value, paidAt: DateTime.now(), note: _note.text.trim()), widget.debt.paid + value);
    if (mounted) Navigator.pop(context, true);
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('تسجيل دفعة')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      Card(child: ListTile(title: Text(widget.debt.person), subtitle: Text('المتبقي: ${widget.debt.remaining.toStringAsFixed(2)} ${widget.debt.currency}'))),
      const SizedBox(height: 16),
      TextField(controller: _amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'مبلغ الدفعة')),
      const SizedBox(height: 12),
      TextField(controller: _note, decoration: const InputDecoration(labelText: 'ملاحظة (اختياري)')),
      const SizedBox(height: 16),
      FilledButton(onPressed: _add, child: const Text('تأكيد الدفعة')),
      const SizedBox(height: 24),
      const Text('سجل الدفعات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ..._payments.map((p) => Card(child: ListTile(leading: const Icon(Icons.check_circle_outline), title: Text('${p.amount.toStringAsFixed(2)} ${widget.debt.currency}'), subtitle: Text('${p.paidAt.toLocal()}'.split('.').first + (p.note.isEmpty ? '' : ' • ${p.note}'))))),
    ]),
  );
}
