import 'package:flutter/material.dart';
import '../models/tranche.dart';

class TermsSheetScreen extends StatelessWidget {
  final Tranche tranche;

  const TermsSheetScreen({super.key, required this.tranche});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms Sheet'),
        backgroundColor: cs.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.description_outlined, size: 64, color: cs.primary),
              const SizedBox(height: 24),
              Text(
                tranche.trancheName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                tranche.productNameCN ?? tranche.product,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(Icons.picture_as_pdf, size: 48, color: Colors.red[400]),
                    const SizedBox(height: 12),
                    Text(
                      'termsheet-1784450545167.pdf',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Demo terms sheet document',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Chat'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
