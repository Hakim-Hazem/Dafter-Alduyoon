import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/debt.dart';
import '../data/database.dart';

class DebtFormScreen extends StatefulWidget {
  final Debt? debt;
  const DebtFormScreen({super.key, this.debt});
  @override
  State<DebtFormScreen> createState() => _DebtFormScreenState();
}
class _DebtFormScreenState extends State<DebtFormScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _person, _amount, _note;
  DateTime? _due;
  String _currency = 'USD';
  @override
  void initState() {
    super.initState();
    final d = widget.debt;
    _person = TextEditingController(text: d?.person ?? '');
    _amount = TextEditingController(text: d == null ? '' : d.amount.toString());
    _note = TextEditingController(text: d?.note ?? '');
    _due = d?.dueDate;
    _currency = d?.currency ?? 'USD';
  }
  @override
  void dispose() { _person.dispose(); _amount.dispose(); _note.dispose(); super.dispose(); }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(context: context, initialDate: _due ?? now,
      firstDate: DateTime(2020), lastDate: DateTime(2100));
    if (picked != null) setState(() => _due = picked);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final old = widget.debt;
    await AppDatabase.instance.saveDebt(Debt(
      id: old?.id, person: _person.text.trim(), amount: double.parse(_amount.text),
      currency: _currency, createdAt: old?.createdAt ?? DateTime.now(),
      dueDate: _due, note: _note.text.trim(), paid: old?.paid ?? 0,
    ));
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.debt == null ? 'إضافة دين جديد' : 'تعديل الدين')),
    body: SafeArea(child: ListView(padding: const EdgeInsets.all(20), children: [
      Form(key: _form, child: Column(children: [
        TextFormField(controller: _person, decoration: const InputDecoration(labelText: 'اسم الشخص أو الجهة', prefixIcon: Icon(Icons.person_outline)),
          validator: (v) => v == null || v.trim().isEmpty ? 'أدخل الاسم' : null),
        const SizedBox(height: 14),
        TextFormField(controller: _amount, keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'قيمة الدين', prefixIcon: Icon(Icons.payments_outlined)),
          validator: (v) { final n = double.tryParse(v ?? ''); return n == null || n <= 0 ? 'أدخل مبلغاً صحيحاً' : null; }),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(value: _currency, decoration: const InputDecoration(labelText: 'العملة'),
          items: const ['USD','EUR','TRY','SYP','JOD','SAR','AED'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (v) => setState(() => _currency = v ?? 'USD')),
        const SizedBox(height: 14),
        Card(child: ListTile(leading: const Icon(Icons.event), title: const Text('تاريخ الاستحقاق'),
          subtitle: Text(_due == null ? 'غير محدد' : DateFormat('yyyy/MM/dd').format(_due!)),
          trailing: IconButton(icon: const Icon(Icons.edit_calendar), onPressed: _pickDate),
          onTap: _pickDate)),
        const SizedBox(height: 14),
        TextFormField(controller: _note, maxLines: 3, decoration: const InputDecoration(labelText: 'ملاحظات (اختياري)', alignLabelWithHint: true)),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, height: 54, child: FilledButton.icon(onPressed: _save,
          icon: const Icon(Icons.save_outlined), label: const Text('حفظ الدين'))),
      ]))
    ])),
  );
}
