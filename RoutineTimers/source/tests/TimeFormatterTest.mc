import Toybox.Lang;
import Toybox.Test;

(:test)
function testFormatMinutesSecondsBasic(logger as Logger) as Boolean {
    var result = TimeFormatter.formatMinutesSeconds(125);
    return result.equals("2:05");
}

(:test)
function testFormatMinutesSecondsZero(logger as Logger) as Boolean {
    var result = TimeFormatter.formatMinutesSeconds(0);
    return result.equals("0:00");
}

(:test)
function testFormatMinutesSecondsSingleDigitMinutes(logger as Logger) as Boolean {
    var result = TimeFormatter.formatMinutesSeconds(65);
    return result.equals("1:05");
}

(:test)
function testFormatMinutesSecondsLeadingZeroSeconds(logger as Logger) as Boolean {
    var result1 = TimeFormatter.formatMinutesSeconds(61);
    var result2 = TimeFormatter.formatMinutesSeconds(2);
    var result3 = TimeFormatter.formatMinutesSeconds(9);
    
    return result1.equals("1:01") &&
           result2.equals("0:02") &&
           result3.equals("0:09");
}

(:test)
function testFormatMinutesSecondsLargeValue(logger as Logger) as Boolean {
    var result = TimeFormatter.formatMinutesSeconds(3599);
    return result.equals("59:59");
}

(:test)
function testFormatMinutesSecondsNegative(logger as Logger) as Boolean {
    var result = TimeFormatter.formatMinutesSeconds(-5);
    return result.equals("0:00"); // Should clamp to 0
}

(:test)
function testFormatHoursMinutesSecondsOneHour(logger as Logger) as Boolean {
    var result = TimeFormatter.formatHoursMinutesSeconds(3600);
    return result.equals("1:00:00");
}

(:test)
function testFormatHoursMinutesSecondsComplex(logger as Logger) as Boolean {
    var result = TimeFormatter.formatHoursMinutesSeconds(3661);
    return result.equals("1:01:01");
}

(:test)
function testFormatHoursMinutesSecondsTwoHours(logger as Logger) as Boolean {
    var result = TimeFormatter.formatHoursMinutesSeconds(7323);
    return result.equals("2:02:03");
}

(:test)
function testFormatHoursMinutesSecondsUnderOneHour(logger as Logger) as Boolean {
    var result = TimeFormatter.formatHoursMinutesSeconds(3599);
    return result.equals("59:59"); // Should fall back to MM:SS
}

(:test)
function testFormatHoursMinutesSecondsNegative(logger as Logger) as Boolean {
    var result = TimeFormatter.formatHoursMinutesSeconds(-100);
    return result.equals("0:00"); // Should clamp to 0
}

(:test)
function testFormatSmartUnderOneHour(logger as Logger) as Boolean {
    var result = TimeFormatter.formatSmart(125);
    return result.equals("2:05"); // Should use MM:SS
}

(:test)
function testFormatSmartOverOneHour(logger as Logger) as Boolean {
    var result = TimeFormatter.formatSmart(3661);
    return result.equals("1:01:01"); // Should use H:MM:SS
}

(:test)
function testFormatSmartExactlyOneHour(logger as Logger) as Boolean {
    var result = TimeFormatter.formatSmart(3600);
    return result.equals("1:00:00"); // Should use H:MM:SS
}

(:test)
function testFormatSmartOneHourMinusOneSecond(logger as Logger) as Boolean {
    var result = TimeFormatter.formatSmart(3599);
    return result.equals("59:59"); // Should use MM:SS
}

(:test)
function testFormatSmartZero(logger as Logger) as Boolean {
    var result = TimeFormatter.formatSmart(0);
    return result.equals("0:00");
}

(:test)
function testFormatSmartNegative(logger as Logger) as Boolean {
    var result = TimeFormatter.formatSmart(-50);
    return result.equals("0:00"); // Should clamp to 0
}

(:test)
function testFormatSmartLargeValue(logger as Logger) as Boolean {
    var result = TimeFormatter.formatSmart(7323);
    return result.equals("2:02:03"); // Should use H:MM:SS
}

(:test)
function testFormatMinutesSecondsEdgeCases(logger as Logger) as Boolean {
    var result1 = TimeFormatter.formatMinutesSeconds(60);
    var result2 = TimeFormatter.formatMinutesSeconds(1);
    var result3 = TimeFormatter.formatMinutesSeconds(599);
    
    return result1.equals("1:00") &&
           result2.equals("0:01") &&
           result3.equals("9:59");
}

(:test)
function testFormatHoursMinutesSecondsEdgeCases(logger as Logger) as Boolean {
    var result1 = TimeFormatter.formatHoursMinutesSeconds(3601);
    var result2 = TimeFormatter.formatHoursMinutesSeconds(86399); // 23:59:59
    var result3 = TimeFormatter.formatHoursMinutesSeconds(90000);
    
    return result1.equals("1:00:01") &&
           result2.equals("23:59:59") &&
           result3.equals("25:00:00"); // 25 hours
}
