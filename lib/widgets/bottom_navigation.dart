import 'package:flutter/material.dart';

class CrackteckBottomSwitcher extends StatelessWidget {
  final bool isMoreOpen;
  final int currentIndex; // 0=Home, 2=Profile

  // ✅ needed for navigation arguments
  final int roleId;
  final String roleName;

  final VoidCallback onHome;
  final VoidCallback onProfile;

  final VoidCallback onMore;
  final VoidCallback onLess;

  // keep these for other buttons (you can wire routes from screen or here later)
  final VoidCallback onLeads;
  final VoidCallback onFollowUp;
  final VoidCallback onMeeting;
  final VoidCallback onQuotation;

  final Color activeColor;
  final Color inactiveColor;

  const CrackteckBottomSwitcher({
    super.key,
    required this.isMoreOpen,
    required this.currentIndex,
    required this.roleId,
    required this.roleName,
    required this.onHome,
    required this.onProfile,
    required this.onMore,
    required this.onLess,
    required this.onLeads,
    required this.onFollowUp,
    required this.onMeeting,
    required this.onQuotation,
    this.activeColor = const Color(0xFF145A00),
    this.inactiveColor = const Color(0xFFB5B5B5),
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, anim) =>
              FadeTransition(opacity: anim, child: child),
          child: isMoreOpen
              ? _MoreNavBar(
                  key: const ValueKey("more"),
                  roleId: roleId,
                  roleName: roleName,
                  onLeads: onLeads,
                  onFollowUp: onFollowUp,
                  onLess: onLess,
                  onMeeting: onMeeting,
                  onQuotation: onQuotation,
                  green: activeColor,
                )
              : _MainNavBar(
                  key: const ValueKey("main"),
                  roleId: roleId,
                  roleName: roleName,
                  currentIndex: currentIndex,
                  onHome: onHome,
                  onMore: onMore,
                  onProfile: onProfile,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                ),
        ),
      ),
    );
  }
}

// ---------------- MAIN NAV ----------------

class _MainNavBar extends StatelessWidget {
  final int currentIndex;
  final VoidCallback onHome;
  final VoidCallback onMore;
  final VoidCallback onProfile;
  final int roleId;
  final String roleName;

  final Color activeColor;
  final Color inactiveColor;

  const _MainNavBar({
    super.key,
    required this.roleId,
    required this.roleName,
    required this.currentIndex,
    required this.onHome,
    required this.onMore,
    required this.onProfile,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _NavItem(
            label: "Home",
            icon: Icons.home_outlined,
            isActive: currentIndex == 0,
            activeColor: activeColor,
            inactiveColor: inactiveColor,
            onPressed: onHome,
          ),
          _NavItem(
            label: "More",
            icon: Icons.keyboard_arrow_up_rounded,
            isActive: false,
            activeColor: activeColor,
            inactiveColor: inactiveColor,
            onPressed: onMore,
          ),
          _NavItem(
            label: "Profile",
            icon: Icons.person_outline,
            isActive: currentIndex == 2,
            activeColor: activeColor,
            inactiveColor: inactiveColor,
            onPressed: onProfile,
          ),
        ],
      ),
    );
  }
}

// ---------------- MORE NAV ----------------

class _MoreNavBar extends StatelessWidget {
  final int roleId;
  final String roleName;

  final VoidCallback onLeads;
  final VoidCallback onFollowUp;
  final VoidCallback onLess;
  final VoidCallback onMeeting;
  final VoidCallback onQuotation;

  final Color green;

  const _MoreNavBar({
    super.key,
    required this.roleId,
    required this.roleName,
    required this.onLeads,
    required this.onFollowUp,
    required this.onLess,
    required this.onMeeting,
    required this.onQuotation,
    required this.green,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // ✅ Leads navigates using your AppRoutes + SalesleadsArguments
          _QuickAction(
            icon: Icons.headset_mic_outlined,
            label: "Leads",
            iconColor: green,
            onTap: onLeads,
          ),

          _QuickAction(
            icon: Icons.calendar_month_outlined,
            label: "Follow-Up",
            iconColor: green,
            onTap: onFollowUp,
          ),
          _QuickAction(
            icon: Icons.keyboard_arrow_down_rounded,
            label: "Less",
            iconColor: green,
            labelColor: green,
            onTap: onLess,
          ),
          _QuickAction(
            icon: Icons.handshake_outlined,
            label: "Meeting",
            iconColor: green,
            onTap: onMeeting,
          ),
          _QuickAction(
            icon: Icons.receipt_long_outlined,
            label: "Quotation",
            iconColor: green,
            onTap: onQuotation,
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? labelColor;
  final Color? iconColor;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.labelColor,
    this.iconColor,
  });

  static const Color labelGrey = Color(0xFF6F6F6F);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor ?? Colors.black87, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: labelColor ?? labelGrey,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- NAV ITEM ----------------

class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onPressed;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? activeColor : inactiveColor;

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
