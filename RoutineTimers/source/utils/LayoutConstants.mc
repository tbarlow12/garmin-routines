import Toybox.Lang;
import Toybox.Graphics;

module LayoutConstants {
    // Calculate layout values based on screen dimensions
    // These are percentages of screen height/width
    
    const ROUTINE_NAME_Y_PERCENT = 0.10;      // 10% from top
    const TIME_CENTER_Y_PERCENT = 0.40;       // 40% from top (center of timer)
    const STEP_NAME_Y_PERCENT = 0.58;         // 58% from top
    const PROGRESS_BAR_Y_PERCENT = 0.68;      // 68% from top
    const NEXT_STEP_Y_PERCENT = 0.80;         // 80% from top
    const STEP_INDICATOR_Y_PERCENT = 0.90;    // 90% from top
    
    const PROGRESS_BAR_HEIGHT = 8;            // Fixed height in pixels
    const PROGRESS_BAR_MARGIN_PERCENT = 0.10; // 10% margin on each side
    
    // Get Y position for a given percentage
    function getY(dc as Graphics.Dc, percent as Float) as Number {
        return (dc.getHeight() * percent).toNumber();
    }
    
    // Get progress bar start X
    function getProgressBarStartX(dc as Graphics.Dc) as Number {
        return (dc.getWidth() * PROGRESS_BAR_MARGIN_PERCENT).toNumber();
    }
    
    // Get progress bar width
    function getProgressBarWidth(dc as Graphics.Dc) as Number {
        var margin = getProgressBarStartX(dc);
        return dc.getWidth() - (margin * 2);
    }
}
