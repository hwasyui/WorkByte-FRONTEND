import 'package:flutter/material.dart';

const Map<String, String> kCategoryLabels = {
  'mobiledev': 'Mobile Dev',
  'backenddev': 'Backend Dev',
  'webdev': 'Web Dev',
  'uiuxdesign': 'UI/UX Design',
  'graphicdesign': 'Graphic Design',
  'copywriting': 'Copywriting',
  'dataanalytics': 'Data Analytics',
  'videoediting': 'Video Editing',
  'marketing': 'Marketing',
  'general': 'General',
  'mobile_dev': 'Mobile Dev',
  'backend_dev': 'Backend Dev',
  'web_dev': 'Web Dev',
  'ui_ux_design': 'UI/UX Design',
  'graphic_design': 'Graphic Design',
  'data_analytics': 'Data Analytics',
  'video_editing': 'Video Editing',
};

const Map<String, IconData> kCategoryIcons = {
  'mobiledev': Icons.phone_android_rounded,
  'backenddev': Icons.dns_rounded,
  'webdev': Icons.language_rounded,
  'uiuxdesign': Icons.design_services_rounded,
  'graphicdesign': Icons.brush_rounded,
  'copywriting': Icons.edit_note_rounded,
  'dataanalytics': Icons.bar_chart_rounded,
  'videoediting': Icons.videocam_rounded,
  'marketing': Icons.campaign_rounded,
  'general': Icons.work_outline_rounded,
  'mobile_dev': Icons.phone_android_rounded,
  'backend_dev': Icons.dns_rounded,
  'web_dev': Icons.language_rounded,
  'ui_ux_design': Icons.design_services_rounded,
  'graphic_design': Icons.brush_rounded,
  'data_analytics': Icons.bar_chart_rounded,
  'video_editing': Icons.videocam_rounded,
};

String categoryLabel(String? value) {
  if (value == null || value.trim().isEmpty) return 'General';
  return kCategoryLabels[value.trim().toLowerCase()] ?? value;
}
