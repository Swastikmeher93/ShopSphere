import 'package:ecommerce_app/constants/app_colors.dart';
import 'package:ecommerce_app/model/auth_user.dart';
import 'package:ecommerce_app/provider/auth_provider.dart';
import 'package:ecommerce_app/screens/widgets/shop_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final displayName = [user?.firstName, user?.lastName]
        .whereType<String>()
        .where((part) => part.trim().isNotEmpty)
        .join(' ');
    final title = displayName.isEmpty ? user?.username ?? 'Shopper' : displayName;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('My profile'),
        backgroundColor: AppColors.coral,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              _ProfileHeader(user: user, name: title),
              const SizedBox(height: 16),
              if (user == null)
                const ShopSectionCard(
                  title: 'Profile unavailable',
                  child: Text('We could not load your profile details.'),
                )
              else ...[
                ShopSectionCard(
                  title: 'Account',
                  child: Column(
                    children: [
                      _ProfileInfoRow(
                          icon: Icons.alternate_email_rounded,
                          label: 'Username',
                          value: user.username),
                      _ProfileInfoRow(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: user.email),
                      _ProfileInfoRow(
                          icon: Icons.badge_outlined,
                          label: 'Profile ID',
                          value: '${user.id}',
                          isLast: true),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                ShopSectionCard(
                  title: 'Personal details',
                  child: Column(
                    children: [
                      _ProfileInfoRow(
                          icon: Icons.person_outline_rounded,
                          label: 'First name',
                          value: user.firstName),
                      _ProfileInfoRow(
                          icon: Icons.person_outline_rounded,
                          label: 'Last name',
                          value: user.lastName),
                      _ProfileInfoRow(
                          icon: Icons.cake_outlined,
                          label: 'Birthday',
                          value: user.birthDate),
                      _ProfileInfoRow(
                          icon: Icons.hourglass_empty_rounded,
                          label: 'Age',
                          value: user.age == null ? null : '${user.age}'),
                      _ProfileInfoRow(
                          icon: Icons.wc_rounded,
                          label: 'Gender',
                          value: user.gender),
                      _ProfileInfoRow(
                          icon: Icons.phone_outlined,
                          label: 'Phone',
                          value: user.phone,
                          isLast: true),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                ShopSectionCard(
                  title: 'About you',
                  child: Column(
                    children: [
                      _ProfileInfoRow(
                          icon: Icons.bloodtype_outlined,
                          label: 'Blood group',
                          value: user.bloodGroup),
                      _ProfileInfoRow(
                          icon: Icons.height_rounded,
                          label: 'Height',
                          value: user.height == null ? null : '${user.height} cm'),
                      _ProfileInfoRow(
                          icon: Icons.monitor_weight_outlined,
                          label: 'Weight',
                          value: user.weight == null ? null : '${user.weight} kg'),
                      _ProfileInfoRow(
                          icon: Icons.remove_red_eye_outlined,
                          label: 'Eye color',
                          value: user.eyeColor),
                      _ProfileInfoRow(
                          icon: Icons.face_rounded,
                          label: 'Hair',
                          value: _hairDescription(user.hair),
                          isLast: true),
                    ],
                  ),
                ),
                if (user.address != null) ...[
                  const SizedBox(height: 14),
                  ShopSectionCard(
                    title: 'Address',
                    child: Column(
                      children: [
                        _ProfileInfoRow(
                            icon: Icons.location_on_outlined,
                            label: 'Street',
                            value: _mapValue(user.address, 'address')),
                        _ProfileInfoRow(
                            icon: Icons.location_city_outlined,
                            label: 'City',
                            value: _mapValue(user.address, 'city')),
                        _ProfileInfoRow(
                            icon: Icons.map_outlined,
                            label: 'State / ZIP',
                            value: _joinValues([
                              _mapValue(user.address, 'state'),
                              _mapValue(user.address, 'postalCode'),
                            ])),
                        _ProfileInfoRow(
                            icon: Icons.public_rounded,
                            label: 'Country',
                            value: _mapValue(user.address, 'country'),
                            isLast: true),
                      ],
                    ),
                  ),
                ],
                if (user.company != null || user.university != null) ...[
                  const SizedBox(height: 14),
                  ShopSectionCard(
                    title: 'Work & education',
                    child: Column(
                      children: [
                        _ProfileInfoRow(
                            icon: Icons.business_outlined,
                            label: 'Company',
                            value: _mapValue(user.company, 'name')),
                        _ProfileInfoRow(
                            icon: Icons.work_outline_rounded,
                            label: 'Job title',
                            value: _mapValue(user.company, 'title')),
                        _ProfileInfoRow(
                            icon: Icons.groups_outlined,
                            label: 'Department',
                            value: _mapValue(user.company, 'department')),
                        _ProfileInfoRow(
                            icon: Icons.school_outlined,
                            label: 'University',
                            value: user.university,
                            isLast: true),
                      ],
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 22),
              SizedBox(
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(authProvider.notifier).signOut();
                    if (context.mounted) {
                      Navigator.of(context)
                          .popUntil((route) => route.isFirst);
                    }
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sign out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.deepCoral,
                    side: const BorderSide(color: AppColors.deepCoral),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user, required this.name});

  final AuthUser? user;
  final String name;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.coral, AppColors.warmOrange],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 38,
              backgroundColor: Colors.white,
              backgroundImage: user?.image == null
                  ? null
                  : NetworkImage(user!.image!),
              child: user?.image == null
                  ? Text(
                      _initials(name),
                      style: const TextStyle(
                        color: AppColors.deepCoral,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      )),
                  const SizedBox(height: 4),
                  Text(
                    user?.role ?? user?.email ?? 'ShopSphere member',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String? value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final shownValue = value == null || value!.trim().isEmpty ? 'Not provided' : value!;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                    color: AppColors.palePeach.withValues(alpha: 0.85)),
              ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 19, color: AppColors.deepCoral),
          const SizedBox(width: 11),
          SizedBox(
            width: 112,
            child: Text(label,
                style: TextStyle(
                    color: AppColors.ink.withValues(alpha: 0.58),
                    fontSize: 12)),
          ),
          Expanded(
            child: Text(shownValue,
                textAlign: TextAlign.end,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                )),
          ),
        ],
      ),
    );
  }
}

String _mapValue(Map<String, dynamic>? map, String key) =>
    map?[key]?.toString() ?? '';

String _hairDescription(Map<String, dynamic>? hair) =>
    _joinValues([hair?['color']?.toString(), hair?['type']?.toString()]);

String _joinValues(Iterable<String?> values) => values
    .whereType<String>()
    .where((value) => value.trim().isNotEmpty)
    .join(', ');

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty);
  final initials = parts.take(2).map((part) => part[0].toUpperCase()).join();
  return initials.isEmpty ? 'S' : initials;
}
