import 'package:flutter/material.dart';
import 'dart:ui';

class GlassMorphismWidget extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final Color? color;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Border? border;

  const GlassMorphismWidget({
    super.key,
    required this.child,
    this.blur = 10.0,
    this.opacity = 0.2,
    this.color,
    this.borderRadius,
    this.padding,
    this.margin,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: (color ?? colorScheme.surface).withOpacity(opacity),
              borderRadius: borderRadius ?? BorderRadius.circular(16),
              border: border ?? Border.all(
                color: colorScheme.outline.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: blur * 2,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class GlassMorphismCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final Color? color;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Border? border;
  final VoidCallback? onTap;

  const GlassMorphismCard({
    super.key,
    required this.child,
    this.blur = 10.0,
    this.opacity = 0.2,
    this.color,
    this.borderRadius,
    this.padding,
    this.margin,
    this.border,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final glassWidget = GlassMorphismWidget(
      blur: blur,
      opacity: opacity,
      color: color,
      borderRadius: borderRadius,
      padding: padding,
      margin: margin,
      border: border,
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        child: glassWidget,
      );
    }

    return glassWidget;
  }
}

class GlassMorphismAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final double blur;
  final double opacity;
  final Color? backgroundColor;
  final double elevation;

  const GlassMorphismAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.blur = 15.0,
    this.opacity = 0.3,
    this.backgroundColor,
    this.elevation = 0,
  });

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: GlassMorphismWidget(
        blur: blur,
        opacity: opacity,
        color: backgroundColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        child: AppBar(
          title: title,
          actions: actions,
          leading: leading,
          automaticallyImplyLeading: automaticallyImplyLeading,
          backgroundColor: Colors.transparent,
          elevation: elevation,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class GlassMorphismBottomSheet extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final Color? color;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;

  const GlassMorphismBottomSheet({
    super.key,
    required this.child,
    this.blur = 15.0,
    this.opacity = 0.3,
    this.color,
    this.borderRadius,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return GlassMorphismWidget(
      blur: blur,
      opacity: opacity,
      color: color,
      borderRadius: borderRadius ?? const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
      padding: padding,
      child: child,
    );
  }
}

class GlassMorphismDialog extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final Color? color;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;

  const GlassMorphismDialog({
    super.key,
    required this.child,
    this.blur = 20.0,
    this.opacity = 0.4,
    this.color,
    this.borderRadius,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return GlassMorphismWidget(
      blur: blur,
      opacity: opacity,
      color: color,
      borderRadius: borderRadius ?? BorderRadius.circular(20),
      padding: padding,
      child: child,
    );
  }
}

class GlassMorphismTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final double blur;
  final double opacity;
  final Color? color;
  final BorderRadius? borderRadius;

  const GlassMorphismTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.blur = 10.0,
    this.opacity = 0.2,
    this.color,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GlassMorphismWidget(
      blur: blur,
      opacity: opacity,
      color: color,
      borderRadius: borderRadius ?? BorderRadius.circular(12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        onChanged: onChanged,
        onFieldSubmitted: onSubmitted,
        style: TextStyle(color: colorScheme.onSurface),
        decoration: InputDecoration(
          hintText: hintText,
          labelText: labelText,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
          labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

class GlassMorphismButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double blur;
  final double opacity;
  final Color? color;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;

  const GlassMorphismButton({
    super.key,
    required this.child,
    this.onPressed,
    this.blur = 10.0,
    this.opacity = 0.3,
    this.color,
    this.borderRadius,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return GlassMorphismCard(
      blur: blur,
      opacity: opacity,
      color: color,
      borderRadius: borderRadius ?? BorderRadius.circular(12),
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      onTap: onPressed,
      child: child,
    );
  }
}