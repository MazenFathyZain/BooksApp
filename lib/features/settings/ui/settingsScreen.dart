import 'package:book/core/helpers/extension.dart';
import 'package:book/core/theming/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/localization/localization_cubit.dart';
import '../../../core/routing/routes.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          context.tr('settings'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildLanguageSection(context),
        ],
      ),
    );
  }

  Widget _buildLanguageSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, context.tr('language')),
        const SizedBox(height: 12),
        _buildLanguageCard(context),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Theme.of(context)
              .colorScheme
              .onBackground
              .withOpacity(0.8),
        ),
      ),
    );
  }

  Widget _buildLanguageCard(BuildContext context) {
    return BlocConsumer<LocaleCubit, LocaleState>(
      listener: (context, state) {
        if (state is LocaleChanged) {
          context.pushNamedAndRemoveUntil(
            Routes.homeScreen,
            predicate: (r) => false,
          );
        }
      },
      builder: (context, state) {
        final currentLanguage =
        state is LocaleChanged ? state.locale.languageCode : 'en';

        return Card(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // _languageItem(
              //   context,
              //   title: context.tr('arabic'),
              //   subtitle: 'Arabic',
              //   flag: '🇸🇦',
              //   code: 'ar',
              //   selected: currentLanguage == 'ar',
              //   isFirst: true,
              // ),
              // _divider(),
              // _languageItem(
              //   context,
              //   title: context.tr('english'),
              //   subtitle: 'English',
              //   flag: '🇬🇧',
              //   code: 'en',
              //   selected: currentLanguage == 'en',
              // ),
              _divider(),
              _languageItem(
                context,
                title: 'Тоҷикӣ',
                subtitle: 'Tajik',
                flag: '🇹🇯',
                code: 'en',
                selected: currentLanguage == 'en',
              ),
              _divider(),
              _languageItem(
                context,
                title: 'Русский',
                subtitle: 'Russian',
                flag: '🇷🇺',
                code: 'ar',
                selected: currentLanguage == 'ar',
                isLast: true,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _languageItem(
      BuildContext context, {
        required String title,
        required String subtitle,
        required String flag,
        required String code,
        required bool selected,
        bool isFirst = false,
        bool isLast = false,
      }) {
    return InkWell(
      onTap: () => context.read<LocaleCubit>().changeLocale(code),
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(12) : Radius.zero,
        bottom: isLast ? const Radius.circular(12) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _flag(flag),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _flag(String emoji) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        emoji,
        style: const TextStyle(fontSize: 20),
      ),
    );
  }

  Widget _divider() =>
      const Divider(height: 1, indent: 16, endIndent: 16);
}
