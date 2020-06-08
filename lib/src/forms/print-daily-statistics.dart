import 'dart:math';

import 'package:intl/intl.dart';
import 'package:nightscout_reporter/src/globals.dart';
import 'package:nightscout_reporter/src/jsonData.dart';

import 'base-print.dart';

class PrintDailyStatistics extends BasePrint {
  @override
  String id = "daystats";

  String _titleGraphic = Intl.message("Tagesstatistik");

  @override
  String get title => _titleGraphic;

  bool showHbA1c, showStdabw, showCount, showPercentile, showVarK, showTDD, showExtendedInsulinStatictics;
  double _maxTDD = 0.0;

  @override
  List<ParamInfo> params = [
    ParamInfo(0, msgParam1, boolValue: true),
    ParamInfo(1, msgParam2, boolValue: true),
    ParamInfo(2, msgParam3, boolValue: true),
    ParamInfo(3, msgParam4, boolValue: true),
    ParamInfo(4, msgParam5, boolValue: false),
    ParamInfo(5, msgParam6, boolValue: false),
    ParamInfo(6, msgParam7, boolValue: false),
  ];

  static String get msgParam1 => Intl.message("Spalte Messwerte");
  static String get msgParam2 => Intl.message("Spalte Standardabweichung");
  static String get msgParam3 => Intl.message("Spalten Perzentile");
  static String get msgParam4 => Intl.message("Spalte HbA1c");
  static String get msgParam5 => Intl.message("Spalte Variationskoeffizient");
  static String get msgParam6 => Intl.message("Spalte TDD");
  static String get msgParam7 => Intl.message("erweiterte Insulinstatistik");

  @override
  extractParams() {
    showCount = params[0].boolValue;
    showStdabw = params[1].boolValue;
    showPercentile = params[2].boolValue;
    showHbA1c = params[3].boolValue;
    showVarK = params[4].boolValue;
    showTDD = false;//params[5].boolValue;
    showExtendedInsulinStatictics = params[6].boolValue;
  }

  @override
  dynamic get estimatePageCount {
    int count = g?.period?.dayCount ?? 0;
    count = (count / 19).ceil();
    return {"count": count, "isEstimated": false};
  }

//  @override
//  String get title => Intl.message("Tagesstatistik");

  @override
  bool get isPortrait => false;

  @override
  double get scale => 1.0;

  SettingsData _settings;

  PrintDailyStatistics() {
    init();
  }

  fillRow(dynamic row, double f, String firstCol, DayData day, String style) {
    addTableRow(true, cm(2.9), row, {"text": msgDate, "style": "total", "alignment": "center"},
        {"text": firstCol, "style": "total", "alignment": "center"});
    addTableRow(true, cm(f * 100), row, {"text": msgDistribution, "style": "total", "alignment": "center"}, {
      "style": style,
      "canvas": [
        {"type": "rect", "color": colLow, "x": cm(0), "y": cm(0), "w": cm(day.lowPrz(g) * f), "h": cm(0.5)},
        {"type": "rect", "color": colNormLow, "x": cm(day.lowPrz(g) * f), "y": cm(0), "w": cm(day.bottomPrz(g) * f), "h": cm(0.5)},
        {"type": "rect", "color": colNorm, "x": cm((day.lowPrz(g) + day.bottomPrz(g)) * f), "y": cm(0), "w": cm(day.normPrz(g) * f), "h": cm(0.5)},
        {"type": "rect", "color": colNormHigh, "x": cm((day.lowPrz(g) + day.bottomPrz(g) + day.normPrz(g)) * f), "y": cm(0), "w": cm(day.topPrz(g) * f), "h": cm(0.5)},
        {
          "type": "rect",
          "color": colHigh,
          "x": cm((day.lowPrz(g) + day.bottomPrz(g) + day.normPrz(g) + day.topPrz(g)) * f),
          "y": cm(0),
          "w": cm(day.highPrz(g) * f),
          "h": cm(0.5)
        }
      ]
    });
    addTableRow(showTDD, cm(f*100), row, {
      "text": msgTDD,
      "style": "total",
      "alignment": "center"
    }, {
      "style": style,
      "canvas": [
        {"type": "rect", "color": colBasalDay, "x": cm(0), "y": cm(0), "w": cm(day.ieBasalSum * f * 100 / _maxTDD), "h": cm(0.5)},
        {
          "type": "rect",
          "color": colBolus,
          "x": cm(day.ieBasalSum * f * 100 / _maxTDD),
          "y": cm(0),
          "w": cm(day.ieBolusSum * f * 100 / _maxTDD),
          "h": cm(0.5)
        },
      ]
    });

    addTableRow(true, "*", row, {
      "text": msgVeryLow(_settings.thresholds.bgLow),
      "style": "total",
      "alignment": "center",
      "fillColor": colLow
    }, {
      "text": "${g.fmtNumber(day.lowPrz(g), 0)} %",
      "style": style,
      "alignment": "right",
      "fillColor": style == "total" ? colLow : null
    });
    addTableRow(true, "*", row, {
      "text": msgLow(_settings.thresholds.bgLow, _settings.thresholds.bgTargetBottom),
      "style": "total",
      "alignment": "center",
      "fillColor": colNormLow
    }, {
      "text": "${g.fmtNumber(day.bottomPrz(g), 0)} %",
      "style": style,
      "alignment": "right",
      "fillColor": style == "total" ? colNormLow : null
    });
    addTableRow(true, "*", row, {"text": msgNormal, "style": "total", "alignment": "center", "fillColor": colNorm}, {
      "text": "${g.fmtNumber(day.normPrz(g), 0)} %",
      "style": style,
      "alignment": "right",
      "fillColor": style == "total" ? colNorm : null
    });
    addTableRow(true, "*", row, {
      "text": msgHigh(_settings.thresholds.bgTargetTop, _settings.thresholds.bgHigh),
      "style": "total",
      "alignment": "center",
      "fillColor": colNormHigh
    }, {
      "text": "${g.fmtNumber(day.topPrz(g), 0)} %",
      "style": style,
      "alignment": "right",
      "fillColor": style == "total" ? colNormHigh : null
    });
    addTableRow(true, "*", row, {
      "text": msgVeryHigh(_settings.thresholds.bgHigh),
      "style": "total",
      "alignment": "center",
      "fillColor": colHigh
    }, {
      "text": "${g.fmtNumber(day.highPrz(g), 0)} %",
      "style": style,
      "alignment": "right",
      "fillColor": style == "total" ? colHigh : null
    });
    // two columns for carbohydrates. Maybe they are better placed in an extra area below the line
    // to avoid columns to grow beyond every limit.
/*
    addRow(true, "auto", row, {"text": "KH\nin g", "style": "total", "alignment": "center"},
      {"text": "${carbFromData(day.carbs)}", "style": style, "alignment": "right"});
    addRow(true, "auto", row, {"text": msgKHPerDay, "style": "total", "alignment": "center"},
      {"text": "${carbFromData(day.avgCarbs)}", "style": style, "alignment": "right"});
// */
    addTableRow(showCount, "auto", row, {"text": msgValues, "style": "total", "alignment": "center"},
        {"text": "${g.fmtNumber(day.entryCountValid, 0)}", "style": style, "alignment": "right"});
    addTableRow(true, "auto", row, {"text": msgMin, "style": "total", "alignment": "center"},
        {"text": "${g.glucFromData(day.min)}", "style": style, "alignment": "right"});
    addTableRow(true, "auto", row, {"text": msgMax, "style": "total", "alignment": "center"},
        {"text": "${g.glucFromData(day.max)}", "style": style, "alignment": "right"});
    addTableRow(true, "auto", row, {"text": msgAverage, "style": "total", "alignment": "center"},
        {"text": "${g.glucFromData(day.mid, 1)}", "style": style, "alignment": "right"});
    addTableRow(showStdabw, "auto", row, {"text": msgDeviation, "style": "total", "alignment": "center"},
        {"text": "${g.fmtNumber(day.stdAbw(g.glucMGDL), 1)}", "style": style, "alignment": "right"});
    addTableRow(showVarK, "auto", row, {"text": msgVarK, "style": "total", "alignment": "center"},
        {"text": "${g.fmtNumber(day.varK, 1)}", "style": style, "alignment": "right"});
    addTableRow(showPercentile, "auto", row, {"text": msg25, "style": "total", "alignment": "center"},
        {"text": "${percentileFor(Globals.percentile(day.entries, 25))}", "style": style, "alignment": "right"});
    addTableRow(showPercentile, "auto", row, {"text": msgMedian, "style": "total", "alignment": "center"},
        {"text": "${percentileFor(Globals.percentile(day.entries, 50))}", "style": style, "alignment": "right"});
    addTableRow(showPercentile, "auto", row, {"text": msg75, "style": "total", "alignment": "center"},
        {"text": "${percentileFor(Globals.percentile(day.entries, 75))}", "style": style, "alignment": "right"});
    addTableRow(showHbA1c, "auto", row, {"text": msgHbA1C, "style": "total", "alignment": "center", "color": colHbA1c},
        {"text": "${hba1c(day.mid)} %", "style": style, "alignment": "right", "color": colHbA1c});
    tableHeadFilled = true;
  }

  String percentileFor(double value) {
    if (value == -1) return "";
    return g.glucFromData(value, 1);
  }

  @override
  void fillPages(List<Page> pages) {
    tableHeadFilled = false;
    tableHeadLine = [];
    tableWidths = [];
    title = Intl.message("Tagesstatistik");
    titleInfo = titleInfoBegEnd();
    _settings = repData.status.settings;
    double f = 3.3;
    if(showTDD)
      f = f/2 - 0.3;
    var body = [];
    // maybe later the margins will work properly, up to now it
    // doesn't work beacause of hardcoded margins in the tablecells
    // this code has to be moved to addRow for operating correctly
/*
    int colCount = 6;
    double wid = width - 4.4 - f - 2.0;
    var widths = [cm(2.0), cm(f), w, w, w];
    if (showCount)widths.add(w);
    widths.add(w);
    widths.add(w);
    widths.add(w);
    if (showStdabw)widths.add(w);
    if (showPercentile)
    {
      widths.add(cm(1.5));
      widths.add(cm(1.5));
      widths.add(cm(1.5));
    }
    if (showHbA1c)widths.add(cm(1.5));
// */
    f /= 100;

    ProfileGlucData prevProfile = null;
    int lineCount = 0;
    var page = [];
    DayData totalDay = DayData(null, ProfileGlucData(ProfileStoreData("Intern")), repData.status);
    totalDay.basalData.targetHigh = 0;
    totalDay.basalData.targetLow = 1000;
    int totalDays = 0;
    int oldLength = pages.length;
    _maxTDD = 0.0;

    for (DayData day in repData.data.days)
    {
      day.init();
      if (day.entryCountValid == 0) continue;
      _maxTDD = max(_maxTDD, day.ieBasalSum + day.ieBolusSum);
    }

    for (DayData day in repData.data.days) {
      if (day.entryCountValid == 0) continue;
      totalDays++;
      totalDay.entries.addAll(day.entries);
      totalDay.bloody.addAll(day.bloody);
      totalDay.treatments.addAll(day.treatments);
      totalDay.basalData.targetHigh = max(totalDay.basalData.targetHigh, day.basalData.targetHigh);
      totalDay.basalData.targetLow = min(totalDay.basalData.targetLow, day.basalData.targetLow);
      var row = [];
      fillRow(row, f, fmtDate(day.date, null, true), day, "row");
      ProfileGlucData profile = repData.profile(DateTime(day.date.year, day.date.month, day.date.day));
      if (prevProfile == null ||
          profile.targetLow != prevProfile.targetLow ||
          profile.targetHigh != prevProfile.targetHigh) {
        body.add(tableHeadLine);
        lineCount += 2;
      }
      prevProfile = profile;

      body.add(row);
      lineCount++;
      if (lineCount == 21) {
        page.add(headerFooter());
        page.add(getTable(tableWidths, body));
        lineCount = 0;
        pages.add(Page(isPortrait, page));
        page = [];
        body = [];
        prevProfile = null;
      }
    }

    var row = [];
    totalDay.init();
    fillRow(row, f, msgDaySum(totalDays), totalDay, "total");
    body.add(row);

    if (prevProfile != null) {
      page.add(headerFooter());
      page.add(getTable(tableWidths, body));
      pages.add(Page(isPortrait, page));
    } else {
      Map test = pages.last.content.last as Map;
      test["columns"].last["table"]["body"].add(body.last);
    }
    if (repData.isForThumbs && pages.length - oldLength > 1) pages.removeRange(oldLength + 1, pages.length);
    if (showExtendedInsulinStatictics)
      pages.add(getInsulinPage(repData));
  }

  Page getInsulinPage(ReportData src)
  {
    String t = _titleGraphic;
    _titleGraphic = Intl.message("Insulinstatistik");

    List<String> xValuesDaily = null;
    List<String> xValuesWeekly = null;
    List<String> xValuesMonthly = null;
    List<List<double>> valuesDaily = [];
    List<List<double>> valuesWeekly = [];
    List<List<double>> valuesMonthly = [];
    List<String> valueColor = [];
    List<String> valueLegend = [];

    Map<String, InsulinInjectionList> dV = new Map();
    Map<String, InsulinInjectionList> wV = new Map();
    Map<String, int> wC = new Map();
    Map<String, InsulinInjectionList> mV = new Map();
    Map<String, int> mC = new Map();
    Set<String> insulinProfiles = new Set();
    for (DayData day in src.data.days) {
      InsulinInjectionList sum = InsulinInjectionList();
      for (TreatmentData t in day.treatments)
        sum = sum.add2List(t.multipleInsulin);
      String dayStr = fmtDateShort(day.date, "day");
      String weekStr = fmtDateShort(day.date, "week");
      String monthStr = fmtDateShort(day.date, "month");
      dV.update(dayStr, (InsulinInjectionList v) => v.add2List(sum), ifAbsent: () => sum.copy);
      wV.update(weekStr, (InsulinInjectionList v) => v.add2List(sum), ifAbsent: () => sum.copy);
      wC.update(weekStr, (int v) => v + 1, ifAbsent: () => 1);
      mV.update(monthStr, (InsulinInjectionList v) => v.add2List(sum), ifAbsent: () => sum.copy);
      mC.update(monthStr, (int v) => v + 1, ifAbsent: () => 1);
      insulinProfiles.addAll(sum.injections.keys);
    }
    if (xValuesDaily == null)
      xValuesDaily = dV.keys.toList();
    if (xValuesWeekly == null)
      xValuesWeekly = wV.keys.toList();
    if (xValuesMonthly == null)
      xValuesMonthly = mV.keys.toList();
    for (String insulin in insulinProfiles)
    {
      if (insulin == "sum") {
        valueColor.add("#000000");
        valueLegend.add(Intl.message("Gesamtinsulin pro Tag"));
      } else
        {
          valueLegend.add(insulin + Intl.message(" pro Tag"));
          if (insulin.toLowerCase() == "novorapid")
            valueColor.add("#FF0000");
          else if (insulin.toLowerCase() == "actrapid")
            valueColor.add("#00FF00");
          else if (insulin.toLowerCase() == "insulatard")
            valueColor.add("#0000FF");
        }
      List<double> daily = [];
      List<double> weekly = [];
      List<double> monthly = [];
      for (String s in xValuesDaily) {
        if (dV[s].injections.containsKey(insulin))
          daily.add(dV[s].injections[insulin]);
        else daily.add(0);
      }
      for (String s in xValuesWeekly) {
        if (wV[s].injections.containsKey(insulin))
          weekly.add(wV[s].injections[insulin] / wC[s]);
        else
          weekly.add(0);
      }
      for (String s in xValuesMonthly) {
        if (mV[s].injections.containsKey(insulin))
          monthly.add(mV[s].injections[insulin] / mC[s]);
        else
          monthly.add(0);
      }
      valuesDaily.add(daily);
      valuesWeekly.add(weekly);
      valuesMonthly.add(monthly);
    }

    double contentWidth = new Page(false, null).width - 1.5*xorg; // 23.25 --> 29.7
    double contentHeight = new Page(false, null).height - 1.5*yorg; // 13 --> 21
    double weekly_monthly_distance = 1.5;
    double legendHeight = 1 + valueLegend.length * 0.5;
    double dailyWidth = contentWidth;
    double weeklyWidth = (contentWidth - weekly_monthly_distance)/2;
    double allGraphHeight = contentHeight / 2 - legendHeight;
    double xo = xorg*0.75; // 3.35
    double yo = yorg; // 3.9

    List<dynamic> content = [ headerFooter(), ];
    if (xValuesDaily.length > 1)
      content.addAll(drawGraphicGridGeneric(allGraphHeight, dailyWidth,
          xo, yo,
          xValuesDaily, valuesDaily, valueColor, valueLegend, graphBottom: allGraphHeight));
    if (xValuesWeekly.length > 1)
      content.addAll(drawGraphicGridGeneric(allGraphHeight, weeklyWidth,
          xo, yo + allGraphHeight + legendHeight,
          xValuesWeekly, valuesWeekly, valueColor, valueLegend, graphBottom: allGraphHeight));
    if (xValuesMonthly.length > 1)
      content.addAll(drawGraphicGridGeneric(allGraphHeight, weeklyWidth,
          xo + weeklyWidth + weekly_monthly_distance, yo + allGraphHeight + legendHeight,
          xValuesMonthly, valuesMonthly, valueColor, valueLegend, graphBottom: allGraphHeight));

    var ret = Page(isPortrait, content);

    _titleGraphic = t;
    return ret;
  }
}
