// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:gpt_markdown/gpt_markdown.dart';
// import 'package:flutter_markdown/flutter_markdown.dart';
// import 'package:markdown/markdown.dart' as md;

// class LaTeXRendering extends StatelessWidget {
//   final String content;
//   final TextStyle? style;
//   final bool enableMath;

//   const LaTeXRendering({
//     super.key,
//     required this.content,
//     this.style,
//     this.enableMath = true,
//   });

//   @override
//   Widget build(BuildContext context) {
//     if (!enableMath) {
//       return MarkdownBody(
//         data: content,
//         styleSheet: MarkdownStyleSheet(
//           textScaler: const TextScaler.linear(1.0),
//         ),
//       );
//     }

//     return GptMarkdown(
//       content,
//       // style: MarkdownStyleSheet(
//       //   textScaler: const TextScaler.linear(1.0),
//       //   code: style?.copyWith(
//       //     backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
//       //     fontFamily: 'monospace',
//       //   ),
//       //   codeblockDecoration: BoxDecoration(
//       //     color: Theme.of(context).colorScheme.surfaceContainerHighest,
//       //     borderRadius: BorderRadius.circular(8),
//       //   ),
//       // ),
//     );
//   }
// }

// class _MathBuilder extends MarkdownElementBuilder {
//   @override
//   Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
//     final mathContent = element.textContent;
    
//     if (mathContent.isEmpty) return null;

//     // Check if it's inline or block math
//     final isInline = element.tag == 'math' && !mathContent.contains('\n');
    
//     if (isInline) {
//       return _InlineMathWidget(mathContent: mathContent);
//     } else {
//       return _BlockMathWidget(mathContent: mathContent);
//     }
//   }
// }

// class _CodeWithLaTeXBuilder extends MarkdownElementBuilder {
//   @override
//   Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
//     final codeContent = element.textContent;
//     final language = element.attributes['class']?.replaceAll('language-', '') ?? '';
    
//     // Check if the code block contains LaTeX
//     if (language == 'latex' || language == 'tex' || 
//         codeContent.contains('\\') || codeContent.contains('$')) {
//       return _LaTeXCodeBlock(
//         content: codeContent,
//         language: language,
//       );
//     }
    
//     return null; // Let default builder handle it
//   }
// }

// class _InlineMathWidget extends StatelessWidget {
//   final String mathContent;

//   const _InlineMathWidget({required this.mathContent});

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;

//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
//       decoration: BoxDecoration(
//         color: colorScheme.surfaceContainerHighest,
//         borderRadius: BorderRadius.circular(4),
//         border: Border.all(
//           color: colorScheme.outlineVariant,
//           width: 1,
//         ),
//       ),
//       child: Text(
//         mathContent,
//         style: theme.textTheme.bodyMedium?.copyWith(
//           fontFamily: 'serif',
//           fontStyle: FontStyle.italic,
//         ),
//       ),
//     );
//   }
// }

// class _BlockMathWidget extends StatelessWidget {
//   final String mathContent;

//   const _BlockMathWidget({required this.mathContent});

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;

//     return Container(
//       width: double.infinity,
//       margin: const EdgeInsets.symmetric(vertical: 8),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: colorScheme.surfaceVariant,
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(
//           color: colorScheme.outlineVariant,
//           width: 1,
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           Text(
//             mathContent,
//             style: theme.textTheme.bodyLarge?.copyWith(
//               fontFamily: 'serif',
//               fontStyle: FontStyle.italic,
//             ),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'LaTeX Math',
//             style: theme.textTheme.bodySmall?.copyWith(
//               color: colorScheme.onSurfaceVariant,
//               fontStyle: FontStyle.italic,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _LaTeXCodeBlock extends StatelessWidget {
//   final String content;
//   final String language;

//   const _LaTeXCodeBlock({
//     required this.content,
//     required this.language,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;

//     return Container(
//       width: double.infinity,
//       margin: const EdgeInsets.symmetric(vertical: 8),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: colorScheme.surfaceVariant,
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(
//           color: colorScheme.outlineVariant,
//           width: 1,
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Language indicator
//           Row(
//             children: [
//               Icon(
//                 Icons.code,
//                 size: 16,
//                 color: colorScheme.primary,
//               ),
//               const SizedBox(width: 8),
//               Text(
//                 language.isNotEmpty ? language.toUpperCase() : 'LATEX',
//                 style: theme.textTheme.bodySmall?.copyWith(
//                   color: colorScheme.primary,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const Spacer(),
//               IconButton(
//                 icon: const Icon(Icons.copy, size: 16),
//                 onPressed: () => _copyToClipboard(context, content),
//                 tooltip: 'Copy LaTeX',
//                 padding: EdgeInsets.zero,
//                 constraints: const BoxConstraints(
//                   minWidth: 24,
//                   minHeight: 24,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
          
//           // LaTeX content
//           SelectableText(
//             content,
//             style: theme.textTheme.bodyMedium?.copyWith(
//               fontFamily: 'monospace',
//               color: colorScheme.onSurfaceVariant,
//             ),
//           ),
          
//           const SizedBox(height: 8),
          
//           // Preview button
//           TextButton.icon(
//             onPressed: () => _showLaTeXPreview(context, content),
//             icon: const Icon(Icons.preview, size: 16),
//             label: const Text('Preview Math'),
//             style: TextButton.styleFrom(
//               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void _copyToClipboard(BuildContext context, String text) async {
//     try {
//       await Clipboard.setData(ClipboardData(text: text));
//       if (context.mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('LaTeX copied to clipboard'),
//             duration: Duration(seconds: 2),
//           ),
//         );
//       }
//     } catch (e) {
//       if (context.mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Failed to copy to clipboard: $e'),
//             backgroundColor: Colors.red,
//             duration: const Duration(seconds: 2),
//           ),
//         );
//       }
//     }
//   }

//   void _showLaTeXPreview(BuildContext context, String latexContent) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('LaTeX Preview'),
//         content: SizedBox(
//           width: double.maxFinite,
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               _BlockMathWidget(mathContent: latexContent),
//               const SizedBox(height: 16),
//               Text(
//                 'Raw LaTeX:',
//                 style: Theme.of(context).textTheme.titleSmall,
//               ),
//               const SizedBox(height: 8),
//               Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: Theme.of(context).colorScheme.surfaceVariant,
//                   borderRadius: BorderRadius.circular(4),
//                 ),
//                 child: SelectableText(
//                   latexContent,
//                   style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                     fontFamily: 'monospace',
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: const Text('Close'),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class LaTeXHelper {
//   static bool containsLaTeX(String text) {
//     // Check for common LaTeX patterns
//     final latexPatterns = [
//       r'\$[^$]+\$', // Inline math
//       r'\$\$[^$]+\$\$', // Block math
//       r'\\[a-zA-Z]+', // LaTeX commands
//       r'\\[\(\)\[\]\{\}]', // LaTeX delimiters
//       r'\\frac\{[^}]+\}\{[^}]+\}', // Fractions
//       r'\\sum_\{[^}]+\}\^\{[^}]+\}', // Sums
//       r'\\int_\{[^}]+\}\^\{[^}]+\}', // Integrals
//     ];

//     for (final pattern in latexPatterns) {
//       if (RegExp(pattern).hasMatch(text)) {
//         return true;
//       }
//     }
//     return false;
//   }

//   static String extractLaTeX(String text) {
//     // Extract LaTeX content from markdown
//     final inlineMathRegex = RegExp(r'\$([^$]+)\$');
//     final blockMathRegex = RegExp(r'\$\$([^$]+)\$\$');
    
//     String result = text;
    
//     // Replace inline math
//     result = result.replaceAllMapped(inlineMathRegex, (match) {
//       return '<math>${match.group(1)}</math>';
//     });
    
//     // Replace block math
//     result = result.replaceAllMapped(blockMathRegex, (match) {
//       return '\n<math>\n${match.group(1)}\n</math>\n';
//     });
    
//     return result;
//   }

//   static List<String> findLaTeXExpressions(String text) {
//     final expressions = <String>[];
    
//     // Find inline math
//     final inlineMatches = RegExp(r'\$([^$]+)\$').allMatches(text);
//     for (final match in inlineMatches) {
//       expressions.add(match.group(1)!);
//     }
    
//     // Find block math
//     final blockMatches = RegExp(r'\$\$([^$]+)\$\$').allMatches(text);
//     for (final match in blockMatches) {
//       expressions.add(match.group(1)!);
//     }
    
//     return expressions;
//   }
// }

// class LaTeXRenderer extends StatelessWidget {
//   final String latexContent;
//   final bool isInline;
//   final TextStyle? style;

//   const LaTeXRenderer({
//     super.key,
//     required this.latexContent,
//     this.isInline = false,
//     this.style,
//   });

//   @override
//   Widget build(BuildContext context) {
//     if (isInline) {
//       return _InlineMathWidget(mathContent: latexContent);
//     } else {
//       return _BlockMathWidget(mathContent: latexContent);
//     }
//   }
// }