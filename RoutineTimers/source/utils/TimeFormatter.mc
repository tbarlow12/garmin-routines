import Toybox.Lang;

module TimeFormatter {
    // Format seconds as "MM:SS"
    function formatMinutesSeconds(totalSeconds as Number) as String {
        if (totalSeconds < 0) {
            totalSeconds = 0;
        }
        
        var minutes = totalSeconds / 60;
        var seconds = totalSeconds % 60;
        
        var minutesStr = minutes.format("%d");
        var secondsStr = seconds.format("%02d");
        
        return minutesStr + ":" + secondsStr;
    }

    // Format seconds as "H:MM:SS" for durations over 1 hour
    function formatHoursMinutesSeconds(totalSeconds as Number) as String {
        if (totalSeconds < 0) {
            totalSeconds = 0;
        }
        
        var hours = totalSeconds / 3600;
        var remaining = totalSeconds % 3600;
        var minutes = remaining / 60;
        var seconds = remaining % 60;
        
        if (hours > 0) {
            return hours.format("%d") + ":" + 
                   minutes.format("%02d") + ":" + 
                   seconds.format("%02d");
        } else {
            return formatMinutesSeconds(totalSeconds);
        }
    }

    // Smart format: uses H:MM:SS only when needed
    function formatSmart(totalSeconds as Number) as String {
        if (totalSeconds >= 3600) {
            return formatHoursMinutesSeconds(totalSeconds);
        }
        return formatMinutesSeconds(totalSeconds);
    }
}
