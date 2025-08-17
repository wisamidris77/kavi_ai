import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? largeDesktop;

  const ResponsiveLayout({super.key, required this.mobile, this.tablet, this.desktop, this.largeDesktop});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1400) {
          return largeDesktop ?? desktop ?? tablet ?? mobile;
        } else if (constraints.maxWidth >= 1100) {
          return desktop ?? tablet ?? mobile;
        } else if (constraints.maxWidth >= 650) {
          return tablet ?? mobile;
        } else {
          return mobile;
        }
      },
    );
  }
}

class ResponsiveBreakpoints {
  static const double mobile = 650;
  static const double tablet = 1100;
  static const double desktop = 1400;
  static const double largeDesktop = 1800;
}

class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext, BoxConstraints) builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: builder);
  }
}

class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int mobileColumns;
  final int tabletColumns;
  final int desktopColumns;
  final int largeDesktopColumns;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 16.0,
    this.runSpacing = 16.0,
    this.mobileColumns = 1,
    this.tabletColumns = 2,
    this.desktopColumns = 3,
    this.largeDesktopColumns = 4,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, constraints) {
        int columns = mobileColumns;

        if (constraints.maxWidth >= ResponsiveBreakpoints.largeDesktop) {
          columns = largeDesktopColumns;
        } else if (constraints.maxWidth >= ResponsiveBreakpoints.desktop) {
          columns = desktopColumns;
        } else if (constraints.maxWidth >= ResponsiveBreakpoints.tablet) {
          columns = tabletColumns;
        }

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: spacing,
            mainAxisSpacing: runSpacing,
            childAspectRatio: _getChildAspectRatio(constraints.maxWidth),
          ),
          itemCount: children.length,
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }

  double _getChildAspectRatio(double width) {
    if (width >= ResponsiveBreakpoints.largeDesktop) {
      return 1.2;
    } else if (width >= ResponsiveBreakpoints.desktop) {
      return 1.1;
    } else if (width >= ResponsiveBreakpoints.tablet) {
      return 1.0;
    } else {
      return 0.9;
    }
  }
}

class ResponsiveRow extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final double spacing;

  const ResponsiveRow({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.spacing = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < ResponsiveBreakpoints.mobile) {
          // Stack vertically on mobile
          return Column(mainAxisAlignment: mainAxisAlignment, crossAxisAlignment: crossAxisAlignment, children: _addSpacing(children, spacing, true));
        } else {
          // Use row on larger screens
          return Row(mainAxisAlignment: mainAxisAlignment, crossAxisAlignment: crossAxisAlignment, children: _addSpacing(children, spacing, false));
        }
      },
    );
  }

  List<Widget> _addSpacing(List<Widget> widgets, double spacing, bool isVertical) {
    if (widgets.isEmpty) return [];

    final result = <Widget>[];
    for (int i = 0; i < widgets.length; i++) {
      result.add(widgets[i]);
      if (i < widgets.length - 1) {
        result.add(isVertical ? SizedBox(height: spacing) : SizedBox(width: spacing));
      }
    }
    return result;
  }
}

class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? width;
  final double? height;
  final BoxDecoration? decoration;

  const ResponsiveContainer({super.key, required this.child, this.padding, this.margin, this.width, this.height, this.decoration});

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, constraints) {
        double responsiveWidth = width ?? constraints.maxWidth;
        double responsivePadding = _getResponsivePadding(constraints.maxWidth);

        // Adjust width for different screen sizes
        if (width == null) {
          if (constraints.maxWidth >= ResponsiveBreakpoints.largeDesktop) {
            responsiveWidth = 1600;
          } else if (constraints.maxWidth >= ResponsiveBreakpoints.desktop) {
            responsiveWidth = 1200;
          } else if (constraints.maxWidth >= ResponsiveBreakpoints.tablet) {
            responsiveWidth = 900;
          } else {
            responsiveWidth = constraints.maxWidth;
          }
        }

        return Container(
          width: responsiveWidth,
          height: height,
          padding: padding ?? EdgeInsets.all(responsivePadding),
          margin: margin,
          decoration: decoration,
          child: child,
        );
      },
    );
  }

  double _getResponsivePadding(double width) {
    if (width >= ResponsiveBreakpoints.largeDesktop) {
      return 32.0;
    } else if (width >= ResponsiveBreakpoints.desktop) {
      return 24.0;
    } else if (width >= ResponsiveBreakpoints.tablet) {
      return 16.0;
    } else {
      return 12.0;
    }
  }
}

class ResponsiveSidebar extends StatelessWidget {
  final Widget child;
  final double? width;
  final Color? backgroundColor;
  final bool showOnMobile;

  const ResponsiveSidebar({super.key, required this.child, this.width, this.backgroundColor, this.showOnMobile = false});

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < ResponsiveBreakpoints.tablet;

        if (isMobile && !showOnMobile) {
          return const SizedBox.shrink();
        }

        double sidebarWidth = width ?? _getResponsiveWidth(constraints.maxWidth);

        return Container(width: sidebarWidth, color: backgroundColor ?? Theme.of(context).colorScheme.surface, child: child);
      },
    );
  }

  double _getResponsiveWidth(double screenWidth) {
    if (screenWidth >= ResponsiveBreakpoints.largeDesktop) {
      return 320;
    } else if (screenWidth >= ResponsiveBreakpoints.desktop) {
      return 280;
    } else if (screenWidth >= ResponsiveBreakpoints.tablet) {
      return 240;
    } else {
      return screenWidth * 0.8; // 80% of screen width on mobile
    }
  }
}

class ResponsiveScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? drawer;
  final Widget? endDrawer;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final bool? resizeToAvoidBottomInset;

  const ResponsiveScaffold({
    super.key,
    this.appBar,
    this.body,
    this.drawer,
    this.endDrawer,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.resizeToAvoidBottomInset,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < ResponsiveBreakpoints.tablet;

        return Scaffold(
          appBar: appBar,
          body: body,
          drawer: isMobile ? drawer : null,
          endDrawer: isMobile ? endDrawer : null,
          bottomNavigationBar: bottomNavigationBar,
          floatingActionButton: floatingActionButton,
          floatingActionButtonLocation: floatingActionButtonLocation,
          resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        );
      },
    );
  }
}

class ResponsiveNavigationRail extends StatelessWidget {
  final List<NavigationRailDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;
  final Widget? leading;
  final Widget? trailing;
  final double? minWidth;
  final double? minExtendedWidth;
  final bool useIndicator;
  final Color? backgroundColor;
  final Color? selectedIconTheme;
  final Color? unselectedIconTheme;
  final Color? selectedLabelTextStyle;
  final Color? unselectedLabelTextStyle;

  const ResponsiveNavigationRail({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    this.onDestinationSelected,
    this.leading,
    this.trailing,
    this.minWidth,
    this.minExtendedWidth,
    this.useIndicator = true,
    this.backgroundColor,
    this.selectedIconTheme,
    this.unselectedIconTheme,
    this.selectedLabelTextStyle,
    this.unselectedLabelTextStyle,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, constraints) {
        // final isMobile = constraints.maxWidth < ResponsiveBreakpoints.tablet;

        // if (isMobile) {
        //   // Use bottom navigation on mobile
        //   return BottomNavigationBar(
        //     currentIndex: selectedIndex,
        //     onTap: onDestinationSelected,
        //     type: BottomNavigationBarType.fixed,
        //     items: destinations.map((dest) => BottomNavigationBarItem(
        //       icon: dest.icon,
        //       label: dest.tet,
        //     )).toList(),
        //   );
        // } else {
        // Use navigation rail on larger screens
        return NavigationRail(
          destinations: destinations,
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          leading: leading,
          trailing: trailing,
          minWidth: minWidth ?? 56,
          minExtendedWidth: minExtendedWidth ?? 72,
          useIndicator: useIndicator,
          backgroundColor: backgroundColor,
          selectedIconTheme: selectedIconTheme != null ? IconThemeData(color: selectedIconTheme) : null,
          unselectedIconTheme: unselectedIconTheme != null ? IconThemeData(color: unselectedIconTheme) : null,
          selectedLabelTextStyle: selectedLabelTextStyle != null ? TextStyle(color: selectedLabelTextStyle) : null,
          unselectedLabelTextStyle: unselectedLabelTextStyle != null ? TextStyle(color: unselectedLabelTextStyle) : null,
        );
        // }
      },
    );
  }
}
