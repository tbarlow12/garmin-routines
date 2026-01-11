import Toybox.Graphics;
import Toybox.Lang;

module ColorUtils {
    // Color constants matching the spec
    const COLOR_PRIMARY_TEXT = 0xFFFFFF;      // White
    const COLOR_SECONDARY_TEXT = 0xAAAAAA;    // Light gray
    const COLOR_ACCENT = 0x00A0DD;            // Garmin blue
    const COLOR_WARNING = 0xFF8C00;           // Orange (< 30s)
    const COLOR_ALERT = 0xFF4444;             // Red (< 10s)
    const COLOR_BACKGROUND = 0x000000;        // Black
    const COLOR_SUCCESS = 0x00DD00;           // Green
    const COLOR_PAUSED = 0xFFFF00;            // Yellow

    // Thresholds in seconds
    const WARNING_THRESHOLD = 30;
    const ALERT_THRESHOLD = 10;

    // Get timer color based on remaining seconds
    function getTimerColor(remainingSeconds as Number) as Number {
        if (remainingSeconds <= ALERT_THRESHOLD) {
            return COLOR_ALERT;
        } else if (remainingSeconds <= WARNING_THRESHOLD) {
            return COLOR_WARNING;
        }
        return COLOR_PRIMARY_TEXT;
    }

    // Get progress bar color based on remaining seconds
    function getProgressColor(remainingSeconds as Number) as Number {
        if (remainingSeconds <= ALERT_THRESHOLD) {
            return COLOR_ALERT;
        } else if (remainingSeconds <= WARNING_THRESHOLD) {
            return COLOR_WARNING;
        }
        return COLOR_ACCENT;
    }

    // Check if we should pulse (for alert state animation)
    function shouldPulse(remainingSeconds as Number) as Boolean {
        return remainingSeconds <= ALERT_THRESHOLD && remainingSeconds > 0;
    }
}
