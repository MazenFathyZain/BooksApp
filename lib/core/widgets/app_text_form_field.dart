// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
//
// import '../theming/colors.dart';
// import '../theming/styles.dart';
//
// class AppTextFormField extends StatelessWidget {
//   final EdgeInsetsGeometry? contentPadding;
//   final InputBorder? focusBorder;
//   final InputBorder? enabledBorder;
//   final TextStyle? inputTextStyle;
//   final TextStyle? hintStyle;
//   final String? hintText;
//   final bool? isObscureText;
//   final Widget? suffixIcon;
//   final Widget? prefixIcon;
//   final TextEditingController? controller;
//   final Function(String?) validator;
//   final TextInputType? keyboardType;
//
//   const AppTextFormField({
//     super.key,
//     this.contentPadding,
//     this.focusBorder,
//     this.enabledBorder,
//     this.inputTextStyle,
//     this.hintStyle,
//     required this.hintText,
//     this.isObscureText,
//     this.suffixIcon,
//     this.prefixIcon,
//     this.controller,
//     required this.validator,
//     this.keyboardType
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return TextFormField(
//       cursorColor: Colors.blue  ,
//       keyboardType: keyboardType,
//       controller: controller,
//       decoration: InputDecoration(
//         isDense: true,
//         contentPadding: contentPadding ??
//             EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
//         focusedBorder: focusBorder ??
//             OutlineInputBorder(
//               borderSide: const BorderSide(
//                 color: Colors.blue,
//                 width: 1.3,
//               ),
//               borderRadius: BorderRadius.circular(16.0),
//             ),
//         enabledBorder: enabledBorder ??
//             OutlineInputBorder(
//               borderSide: const BorderSide(
//                 color: ColorsManager.lighterGray,
//                 width: 1.3,
//               ),
//               borderRadius: BorderRadius.circular(16.0),
//             ),
//         // in case Erorr
//         errorBorder: OutlineInputBorder(
//           borderSide: const BorderSide(color: Colors.red, width: 1.3),
//           borderRadius: BorderRadius.circular(16.0),
//         ),
//         focusedErrorBorder: OutlineInputBorder(
//           borderSide: const BorderSide(color: Colors.red, width: 1.3),
//           borderRadius: BorderRadius.circular(16.0),
//         ),
//         hintStyle: hintStyle ?? TextStyles.font14LightGreyRegular,
//         hintText: hintText,
//         suffixIcon: suffixIcon,
//         prefixIcon: prefixIcon,
//         filled: true,
//         fillColor: ColorsManager.lightestGray,
//       ),
//
//       obscureText: isObscureText ?? false,
//       style: TextStyles.font14DarkblueMediam,
//       validator: (value) {
//         return validator(value);
//       },
//     );
//   }
// }
