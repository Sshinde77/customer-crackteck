import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/api_constants.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';


/// Reusable phone number input field widget
class PhoneInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  const PhoneInputField({
    Key? key,
    required this.controller,
    required this.label,
    this.errorText,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          label,
          style: const TextStyle(
            color: AppColors.black,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),

        // Input Field
        Container(
          height: AppSpacing.inputHeight,
          decoration: BoxDecoration(
            color: AppColors.inputBackground,
            borderRadius: BorderRadius.circular(AppSpacing.inputBorderRadius),
            border: Border.all(
              color: errorText != null
                  ? Colors.red
                  : AppColors.inputBorder,
              width: AppSpacing.inputBorderWidth,
            ),
          ),
          child: Row(
            children: [
              // Country Code Prefix
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.inputHorizontalPadding,
                ),
                child: Text(
                  ApiConstants.defaultCountryCode,
                  style: const TextStyle(
                    color: AppColors.inputText,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              // Divider
              Container(
                width: 1,
                height: 30,
                color: AppColors.inputBorder,
              ),

              // Phone Number Input
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  onChanged: onChanged,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    counterText: '',
                    hintText: '9876543210',
                    hintStyle: TextStyle(
                      color: AppColors.lightGrey.withOpacity(0.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.inputHorizontalPadding,
                    ),
                  ),
                  style: const TextStyle(
                    color: AppColors.inputText,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Error Text
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              errorText!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}

