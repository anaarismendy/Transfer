import 'package:flutter/material.dart';

import 'package:prueba_tecnica/core/theme.dart';

List<BoxShadow> softShadows({double spread = 1}) => [
  BoxShadow(
    color: const Color(0xFFA094C7).withValues(alpha: 0.30),
    offset: Offset(6 * spread, 6 * spread),
    blurRadius: 14 * spread,
  ),
  BoxShadow(
    color: Colors.white.withValues(alpha: 0.88),
    offset: Offset(-6 * spread, -6 * spread),
    blurRadius: 14 * spread,
  ),
];

BoxDecoration softRaised({double radius = 22, Color color = surfaceSoft}) =>
    BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: softShadows(),
    );

BoxDecoration softInset({double radius = 16}) => BoxDecoration(
  borderRadius: BorderRadius.circular(radius),
  gradient: const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFDCD5EF), Color(0xFFF4F1FC)],
  ),
  border: Border.all(color: const Color(0xFFDAD3ED)),
);

BoxDecoration brandRaised({double radius = 26}) => BoxDecoration(
  gradient: brandGradient,
  borderRadius: BorderRadius.circular(radius),
  boxShadow: [
    BoxShadow(
      color: const Color(0xFF8278C3).withValues(alpha: 0.40),
      offset: const Offset(8, 8),
      blurRadius: 22,
    ),
  ],
);

const tabBarGap = 108.0;

String initialsOf(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  return parts.take(2).map((w) => w[0].toUpperCase()).join();
}

Color avatarColorFor(String seed) {
  if (seed.isEmpty) return avatarPalette.first;
  var hash = 0;
  for (final unit in seed.codeUnits) {
    hash = (hash + unit) % avatarPalette.length;
  }
  return avatarPalette[hash];
}

class Avatar extends StatelessWidget {
  final String name;
  final String seed;
  final double size;

  const Avatar({
    super.key,
    required this.name,
    required this.seed,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: avatarColorFor(seed),
        shape: BoxShape.circle,
      ),
      child: Text(
        initialsOf(name),
        style: TextStyle(
          color: avatarInk,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.34,
        ),
      ),
    );
  }
}

class BrandAvatar extends StatelessWidget {
  final String name;
  final double size;

  const BrandAvatar({super.key, required this.name, this.size = 46});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: brandGradient,
        shape: BoxShape.circle,
      ),
      child: Text(
        initialsOf(name),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.33,
        ),
      ),
    );
  }
}

class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;

  const SoftCard({
    super.key,
    required this.child,
    this.padding,
    this.radius = 22,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: softRaised(radius: radius),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class SoftList extends StatelessWidget {
  final List<Widget> children;

  const SoftList({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++)
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: i < children.length - 1
                        ? hairline
                        : Colors.transparent,
                  ),
                ),
              ),
              child: children[i],
            ),
        ],
      ),
    );
  }
}

class SoftField extends StatelessWidget {
  final String hint;
  final String? label;
  final TextEditingController? controller;
  final bool obscure;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final Widget? trailing;

  const SoftField({
    super.key,
    required this.hint,
    this.label,
    this.controller,
    this.obscure = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: const TextStyle(
              fontSize: 12,
              color: muted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
        ],
        DecoratedBox(
          decoration: softInset(),
          child: TextFormField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboardType,
            validator: validator,
            onChanged: onChanged,
            style: const TextStyle(fontSize: 15, color: ink),
            cursorColor: violet,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: placeholderInk, fontSize: 15),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 15,
              ),
              suffixIcon: trailing,
              errorStyle: const TextStyle(color: sentInk, fontSize: 11.5),
            ),
          ),
        ),
      ],
    );
  }
}

class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const GradientButton({super.key, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: enabled ? brandGradient : null,
          color: enabled ? null : disabledFill,
          borderRadius: BorderRadius.circular(18),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: const Color(0xFF786EBE).withValues(alpha: 0.40),
                    offset: const Offset(6, 6),
                    blurRadius: 16,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: enabled ? 1 : 0.7),
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

class SoftButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  const SoftButton({
    super.key,
    required this.label,
    this.color = violet,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        alignment: Alignment.center,
        decoration: softRaised(radius: 18),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 14.5,
          ),
        ),
      ),
    );
  }
}

class SoftCircleButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double size;

  const SoftCircleButton({
    super.key,
    required this.child,
    this.onPressed,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: surfaceSoft,
          shape: BoxShape.circle,
          boxShadow: softShadows(spread: 0.85),
        ),
        child: child,
      ),
    );
  }
}

class BackCircle extends StatelessWidget {
  const BackCircle({super.key});

  @override
  Widget build(BuildContext context) {
    return SoftCircleButton(
      size: 42,
      onPressed: () => Navigator.of(context).pop(),
      child: const Icon(Icons.chevron_left_rounded, color: inkSoft, size: 26),
    );
  }
}

class ScreenBackground extends StatelessWidget {
  final Widget child;

  const ScreenBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: screenGradient),
      child: child,
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? action;

  const SectionTitle({super.key, required this.text, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: ink,
            ),
          ),
        ),
        ?action,
      ],
    );
  }
}

class PageHeading extends StatelessWidget {
  final String text;
  final Widget? action;

  const PageHeading({super.key, required this.text, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: ink,
            ),
          ),
        ),
        ?action,
      ],
    );
  }
}
