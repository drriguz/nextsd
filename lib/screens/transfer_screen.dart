import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';

enum TransferType { own, others, international }

class TransferScreen extends StatefulWidget {
  final TransferType transferType;
  final String? initialAmount;
  final String? initialRecipient;

  const TransferScreen({
    super.key,
    required this.transferType,
    this.initialAmount,
    this.initialRecipient,
  });

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _accountController = TextEditingController();
  final _bankController = TextEditingController();
  final _amountController = TextEditingController();
  final _remarksController = TextEditingController();
  String _selectedCurrency = 'CNY';

  @override
  void initState() {
    super.initState();
    if (widget.initialRecipient != null) {
      _nameController.text = widget.initialRecipient!;
    }
    if (widget.initialAmount != null) {
      _amountController.text = widget.initialAmount!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _accountController.dispose();
    _bankController.dispose();
    _amountController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle(l10n)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFromAccountCard(l10n),
              const SizedBox(height: 24),
              Text(l10n.transferToOthers, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              if (widget.transferType != TransferType.own) ...[
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: l10n.payeeName,
                    prefixIcon: const Icon(Icons.person_outline),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? l10n.payeeName : null,
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _accountController,
                decoration: InputDecoration(
                  labelText: widget.transferType == TransferType.own
                      ? l10n.toAccount
                      : l10n.toAccount,
                  prefixIcon: const Icon(Icons.account_balance),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.isEmpty) ? l10n.toAccount : null,
              ),
              if (widget.transferType == TransferType.international) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _bankController,
                  decoration: InputDecoration(
                    labelText: l10n.bankName,
                    prefixIcon: const Icon(Icons.business),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? l10n.bankName : null,
                ),
              ],
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 100,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedCurrency,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'CNY', child: Text('CNY')),
                        DropdownMenuItem(value: 'USD', child: Text('USD')),
                        DropdownMenuItem(value: 'HKD', child: Text('HKD')),
                        DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                      ],
                      onChanged: (v) => setState(() => _selectedCurrency = v ?? 'CNY'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n.transferAmount,
                        prefixIcon: const Icon(Icons.attach_money),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return l10n.transferAmount;
                        if (double.tryParse(v) == null) return l10n.transferAmount;
                        if (double.parse(v) <= 0) return l10n.transferAmount;
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _remarksController,
                decoration: InputDecoration(
                  labelText: l10n.remarksOptional,
                  prefixIcon: const Icon(Icons.edit_note),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () => _submit(l10n),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: Text(l10n.transferNow),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTitle(AppStrings l10n) {
    switch (widget.transferType) {
      case TransferType.own:
        return l10n.transferToOwn;
      case TransferType.others:
        return l10n.transferToOthers;
      case TransferType.international:
        return l10n.internationalTransfer;
    }
  }

  Widget _buildFromAccountCard(AppStrings l10n) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.account_balance_wallet, size: 24, color: cs.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.fromAccount, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  const SizedBox(height: 4),
                  const Text('**** **** **** 8888', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  Text('CNY 2,350,000.00', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                ],
              ),
            ),
            Icon(Icons.check_circle, color: cs.primary, size: 20),
          ],
        ),
      ),
    );
  }

  void _submit(AppStrings l10n) {
    if (_formKey.currentState!.validate()) {
      final amount = _amountController.text;
      final recipient = widget.transferType == TransferType.own
          ? _accountController.text
          : _nameController.text;

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Icon(Icons.check_circle, size: 64, color: Colors.green[400]),
                const SizedBox(height: 16),
                Text(l10n.transferSuccess, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(l10n.transferSuccessMsg, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 12),
                Text('$_selectedCurrency $amount', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('→ $recipient', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              ],
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: Text(l10n.done),
              ),
            ],
          );
        },
      );
    }
  }
}
