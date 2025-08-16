import 'package:flutter/material.dart';
import '../../core/token/token_tracker.dart';

class TokenUsageWidget extends StatelessWidget {
  final TokenUsage usage;
  final CostEstimate cost;
  final VoidCallback? onReset;

  const TokenUsageWidget({
    super.key,
    required this.usage,
    required this.cost,
    this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Usage Analytics',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (onReset != null)
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: onReset,
                    tooltip: 'Reset usage',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Token usage
            _buildUsageSection(context, colorScheme),
            const SizedBox(height: 16),
            
            // Cost estimates
            _buildCostSection(context, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageSection(BuildContext context, ColorScheme colorScheme) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Token Usage',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _UsageCard(
                title: 'Total Tokens',
                value: _formatNumber(usage.totalTokens),
                subtitle: 'All time',
                icon: Icons.token,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _UsageCard(
                title: 'Input Tokens',
                value: _formatNumber(usage.inputTokens),
                subtitle: 'User messages',
                icon: Icons.input,
                color: colorScheme.secondary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _UsageCard(
                title: 'Output Tokens',
                value: _formatNumber(usage.outputTokens),
                subtitle: 'AI responses',
                icon: Icons.output,
                color: colorScheme.tertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _UsageCard(
                title: 'Conversations',
                value: usage.conversations.toString(),
                subtitle: 'Total chats',
                icon: Icons.chat,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _UsageCard(
                title: 'Last Used',
                value: _formatDate(usage.lastUsed),
                subtitle: 'Recent activity',
                icon: Icons.schedule,
                color: colorScheme.secondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCostSection(BuildContext context, ColorScheme colorScheme) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cost Estimates',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _CostCard(
                title: 'Total Cost',
                value: _formatCurrency(cost.totalCost),
                subtitle: 'All time',
                icon: Icons.account_balance_wallet,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _CostCard(
                title: 'Daily Cost',
                value: _formatCurrency(cost.dailyCost),
                subtitle: 'Today',
                icon: Icons.today,
                color: colorScheme.secondary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _CostCard(
                title: 'Monthly Cost',
                value: _formatCurrency(cost.monthlyCost),
                subtitle: 'This month',
                icon: Icons.calendar_month,
                color: colorScheme.tertiary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  String _formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(4)}';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class _UsageCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _UsageCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _CostCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _CostCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}