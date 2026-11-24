import 'package:material_ui/material_ui.dart';
import 'app_colors.dart';

class AppTextStyles {
  static const TextStyle headline1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );

  static const TextStyle headline2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );

  static const TextStyle subhead1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );

  static const TextStyle bodyText1 = TextStyle(
    fontSize: 14,
    color: AppColors.textDark,
  );

  static const TextStyle bodyText2 = TextStyle(
    fontSize: 12,
    color: AppColors.textLight,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textWhite,
  );

  static const TextStyle smallGreen = TextStyle(
    fontSize: 10,
    color: AppColors.primaryGreen,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle statusPending = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: AppColors.warningOrange,
  );

  static const TextStyle statusActive = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryGreen,
  );

  static const TextStyle statusAlert = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: AppColors.alertRed,
  );
}
