import 'package:flutter/material.dart';

import '../models/pay_rule.dart';

Locale calendarLocaleForRule(PayRule rule) {
  return calendarLocaleForCountry(
    country: rule.country,
    currency: rule.currency,
  );
}

Locale calendarLocaleForCountry({
  required String country,
  required String currency,
}) {
  if (country == 'South Korea' || currency == 'KRW') {
    return const Locale('ko', 'KR');
  }
  return const Locale('en', 'GB');
}

Future<DateTime?> showAppDatePicker({
  required BuildContext context,
  required PayRule rule,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  return showDatePicker(
    context: context,
    locale: calendarLocaleForRule(rule),
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
  );
}

Future<DateTimeRange?> showAppDateRangePicker({
  required BuildContext context,
  required PayRule rule,
  required DateTime firstDate,
  required DateTime lastDate,
  required DateTimeRange initialDateRange,
}) {
  return showDateRangePicker(
    context: context,
    locale: calendarLocaleForRule(rule),
    firstDate: firstDate,
    lastDate: lastDate,
    initialDateRange: initialDateRange,
  );
}
