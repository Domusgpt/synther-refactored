import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/firebase_manager.dart';
import 'premium_manager.dart';

/// Premium upgrade screen with subscription options
class PremiumUpgradeScreen extends StatefulWidget {
  const PremiumUpgradeScreen({Key? key}) : super(key: key);

  @override
  State<PremiumUpgradeScreen> createState() => _PremiumUpgradeScreenState();
}

class _PremiumUpgradeScreenState extends State<PremiumUpgradeScreen> {
  final PremiumManager _premiumManager = PremiumManager();
  Map<String, SubscriptionOffer> _offers = {};
  bool _isLoading = true;
  bool _isYearly = true;
  String? _selectedTier;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOffers();
    _setupCallbacks();
  }

  void _loadOffers() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Get available subscriptions
    final offers = _premiumManager.getAvailableSubscriptions();
    
    setState(() {
      _offers = offers;
      _isLoading = false;
      
      if (_offers.isEmpty) {
        _errorMessage = 'Unable to load subscription options. Please try again later.';
      }
    });
  }

  void _setupCallbacks() {
    _premiumManager.setCallbacks(
      onPurchaseSuccess: (tier) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome to Synther ${tier.toUpperCase()}!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate back
        Navigator.of(context).pop(true);
      },
      onPurchaseError: (error) {
        setState(() {
          _errorMessage = error;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red,
          ),
        );
      },
      onPurchaseRestored: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Purchases restored successfully'),
          ),
        );
      },
    );
  }

  Future<void> _purchaseSubscription(String tier) async {
    setState(() {
      _selectedTier = tier;
      _errorMessage = null;
    });

    final success = await _premiumManager.purchaseSubscription(
      tier,
      isYearly: _isYearly,
    );

    if (!success && mounted) {
      setState(() {
        _selectedTier = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firebase = context.watch<FirebaseManager>();
    final currentTier = firebase.userProfile?.premiumTier ?? PremiumTier.free;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upgrade to Premium'),
        actions: [
          TextButton(
            onPressed: () async {
              await _premiumManager.restorePurchases();
            },
            child: const Text('Restore Purchases'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Current status
                  if (currentTier != PremiumTier.free)
                    Card(
                      color: theme.colorScheme.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(
                              Icons.star,
                              size: 48,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Current Plan: ${currentTier.name.toUpperCase()}',
                              style: theme.textTheme.titleLarge,
                            ),
                            if (firebase.userProfile?.premiumExpiryDate != null)
                              Text(
                                'Expires: ${_formatDate(firebase.userProfile!.premiumExpiryDate!)}',
                                style: theme.textTheme.bodyMedium,
                              ),
                          ],
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Billing toggle
                  Center(
                    child: SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                          value: false,
                          label: Text('Monthly'),
                        ),
                        ButtonSegment(
                          value: true,
                          label: Text('Yearly (Save 17%)'),
                        ),
                      ],
                      selected: {_isYearly},
                      onSelectionChanged: (Set<bool> selection) {
                        setState(() {
                          _isYearly = selection.first;
                        });
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Error message
                  if (_errorMessage != null)
                    Card(
                      color: theme.colorScheme.errorContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: theme.colorScheme.onErrorContainer),
                        ),
                      ),
                    ),
                  
                  // Subscription tiers
                  if (_offers.isEmpty && _errorMessage == null)
                    const Center(
                      child: Text('No subscription options available'),
                    )
                  else
                    ..._buildSubscriptionTiers(theme),
                  
                  const SizedBox(height: 24),
                  
                  // Benefits comparison
                  _buildBenefitsTable(theme),
                ],
              ),
            ),
    );
  }

  List<Widget> _buildSubscriptionTiers(ThemeData theme) {
    return _offers.entries.map((entry) {
      final tier = entry.key;
      final offer = entry.value;
      final isSelected = _selectedTier == tier;
      final isPro = tier == 'pro'; // Highlight Pro as recommended
      
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Card(
          elevation: isPro ? 8 : 2,
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : isPro
                  ? theme.colorScheme.secondaryContainer
                  : null,
          child: InkWell(
            onTap: () => _purchaseSubscription(tier),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        tier.toUpperCase(),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (isPro)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'RECOMMENDED',
                            style: TextStyle(
                              color: theme.colorScheme.onPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isYearly ? offer.yearlyPrice : offer.monthlyPrice,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    _isYearly ? 'per year' : 'per month',
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (_isYearly)
                    Text(
                      'Save ${offer.yearlySavingsPercent.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(height: 16),
                  ...offer.features.map((feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(feature),
                        ),
                      ],
                    ),
                  )),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSelected ? null : () => _purchaseSubscription(tier),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isPro
                            ? theme.colorScheme.primary
                            : null,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        isSelected ? 'Processing...' : 'Choose ${tier.toUpperCase()}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildBenefitsTable(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Compare Plans',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1),
                3: FlexColumnWidth(1),
                4: FlexColumnWidth(1),
              },
              children: [
                TableRow(
                  children: [
                    const Text('Feature', style: TextStyle(fontWeight: FontWeight.bold)),
                    _buildTableHeader('FREE'),
                    _buildTableHeader('PLUS'),
                    _buildTableHeader('PRO'),
                    _buildTableHeader('STUDIO'),
                  ],
                ),
                _buildFeatureRow('No Ads', ['❌', '✓', '✓', '✓']),
                _buildFeatureRow('Cloud Presets', ['3', '50', '200', '∞']),
                _buildFeatureRow('LLM Generations/Day', ['5', '50', '200', '∞']),
                _buildFeatureRow('Export to WAV', ['❌', '✓', '✓', '✓']),
                _buildFeatureRow('MIDI Export', ['❌', '❌', '✓', '✓']),
                _buildFeatureRow('Cloud Sync', ['❌', '❌', '✓', '✓']),
                _buildFeatureRow('Collaboration', ['❌', 'Basic', 'Advanced', 'Advanced']),
                _buildFeatureRow('Commercial Use', ['❌', '❌', '❌', '✓']),
                _buildFeatureRow('Priority Support', ['❌', '❌', '❌', '✓']),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader(String text) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  TableRow _buildFeatureRow(String feature, List<String> values) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(feature, style: const TextStyle(fontSize: 14)),
        ),
        ...values.map((value) => Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: value == '❌' ? Colors.grey : null,
              ),
            ),
          ),
        )),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}