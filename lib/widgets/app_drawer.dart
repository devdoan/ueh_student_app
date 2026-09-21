import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class _DrawerItem {
  const _DrawerItem(this.icon, this.label);

  final FaIconData icon;
  final String label;
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <_DrawerItem>[
      const _DrawerItem(FontAwesomeIcons.newspaper, 'Tin tức UEH'),
      const _DrawerItem(FontAwesomeIcons.calendarCheck, 'Sự kiện UEH'),
      const _DrawerItem(FontAwesomeIcons.chartLine, 'Xem điểm'),
      const _DrawerItem(FontAwesomeIcons.fingerprint, 'Định danh khuôn mặt'),
      const _DrawerItem(FontAwesomeIcons.calendarDays, 'Thời khóa biểu'),
      const _DrawerItem(FontAwesomeIcons.clipboardList, 'Lịch thi'),
      const _DrawerItem(FontAwesomeIcons.heartPulse, 'Chăm sóc sức khỏe'),
      const _DrawerItem(FontAwesomeIcons.leaf, 'UEH Go Green Station'),
      const _DrawerItem(FontAwesomeIcons.phone, 'Liên hệ trực tiếp UEH'),
      const _DrawerItem(FontAwesomeIcons.coins, 'UEH Green Coin'),
      const _DrawerItem(FontAwesomeIcons.solidCircleCheck, 'Đã điểm danh'),
    ];

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF005F69)),
            child: Center(
              child: Image(
                image: AssetImage('assets/images/logo-header.png'),
              ),
            ),
          ),
          for (final item in items)
            ListTile(
              leading: FaIcon(item.icon, size: 20),
              title: Text(item.label),
              onTap: () {
                Navigator.of(context).pop();
              },
            ),
        ],
      ),
    );
  }
}
