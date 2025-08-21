import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

class CodeBlockWidget extends StatefulWidget {
  final String code;
  final String? language;
  final bool showCopyButton;
  final bool showLineNumbers;

  const CodeBlockWidget({
    super.key,
    required this.code,
    this.language,
    this.showCopyButton = true,
    this.showLineNumbers = true,
  });

  @override
  State<CodeBlockWidget> createState() => _CodeBlockWidgetState();
}

class _CodeBlockWidgetState extends State<CodeBlockWidget> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with language and copy button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              border: Border(
                bottom: BorderSide(color: colorScheme.outlineVariant),
              ),
            ),
            child: Row(
              children: [
                if (widget.language != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.language!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
                if (widget.showCopyButton)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_copied)
                        Text(
                          'Copied!',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary,
                          ),
                        ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          _copied ? Icons.check : Icons.copy,
                          size: 16,
                          color: _copied ? colorScheme.primary : colorScheme.onSurfaceVariant,
                        ),
                        onPressed: _copyCode,
                        tooltip: 'Copy code',
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          
          // Code content
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            child: _buildCodeContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeContent() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    if (widget.showLineNumbers) {
      return _buildCodeWithLineNumbers();
    } else {
      return SelectableText(
        widget.code,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontFamily: 'monospace',
          color: colorScheme.onSurfaceVariant,
        ),
      );
    }
  }

  Widget _buildCodeWithLineNumbers() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final lines = widget.code.split('\n');
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Line numbers
        Container(
          padding: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(color: colorScheme.outlineVariant),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: lines.asMap().entries.map((entry) {
              final index = entry.key;
              final line = entry.value;
              return Container(
                height: 20,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '${index + 1}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        
        // Code content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: lines.map((line) {
              return SizedBox(
                height: 20,
                child: SelectableText(
                  line,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _copyCode() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    
    setState(() {
      _copied = true;
    });
    
    // Reset copied state after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _copied = false;
        });
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Code copied to clipboard'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// Enhanced markdown builder that uses our custom code block
class EnhancedMarkdownBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    if (element.tag == 'pre') {
      final codeElement = element.children?.firstWhere(
        (child) => child is md.Element && child.tag == 'code',
        orElse: () => element,
      ) as md.Element? ?? element;
      
      String language = '';
      if (codeElement.attributes.containsKey('class')) {
        final classes = codeElement.attributes['class']!.split(' ');
        language = classes.firstWhere(
          (cls) => cls.startsWith('language-'),
          orElse: () => '',
        ).replaceFirst('language-', '');
      }
      
      return CodeBlockWidget(
        code: codeElement.textContent,
        language: language.isNotEmpty ? language : null,
      );
    }
    
    return null;
  }
}