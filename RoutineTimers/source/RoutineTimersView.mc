import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.System;

class RoutineTimersView extends WatchUi.View {
    private var _routineService as RoutineService;
    private var _pulseState as Boolean;  // For pulsing animation

    function initialize() {
        View.initialize();
        _routineService = new RoutineService();
        _pulseState = false;
        
        // Load test routine
        var testRoutine = TestDataFactory.createQuickTestRoutine();
        _routineService.loadRoutine(testRoutine);
        
        // Set up callbacks
        _routineService.setOnTickCallback(method(:onTick));
        _routineService.setOnStepChangeCallback(method(:onStepChange));
        _routineService.setOnRoutineCompleteCallback(method(:onRoutineComplete));
    }

    function onTick() as Void {
        _pulseState = !_pulseState; // Toggle pulse state each second
        WatchUi.requestUpdate();
    }

    function onStepChange(stepIndex as Number, step as Step) as Void {
        WatchUi.requestUpdate();
    }

    function onRoutineComplete() as Void {
        WatchUi.requestUpdate();
    }

    function getRoutineService() as RoutineService {
        return _routineService;
    }

    function onLayout(dc as Dc) as Void {
    }

    function onShow() as Void {
    }

    function onUpdate(dc as Dc) as Void {
        // Clear background
        dc.setColor(ColorUtils.COLOR_PRIMARY_TEXT, ColorUtils.COLOR_BACKGROUND);
        dc.clear();

        var routine = _routineService.getRoutine();
        if (routine == null) {
            drawNoRoutine(dc);
            return;
        }

        if (_routineService.isComplete()) {
            drawCompleteScreen(dc, routine);
            return;
        }

        drawActiveRoutine(dc, routine);
    }

    private function drawNoRoutine(dc as Dc) as Void {
        dc.setColor(ColorUtils.COLOR_SECONDARY_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            dc.getWidth() / 2,
            dc.getHeight() / 2,
            Graphics.FONT_MEDIUM,
            "No Routine Loaded",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    private function drawActiveRoutine(dc as Dc, routine as Routine) as Void {
        var centerX = dc.getWidth() / 2;
        var remainingSeconds = _routineService.getRemainingSeconds();

        // 1. Routine name (top, small, gray)
        dc.setColor(ColorUtils.COLOR_SECONDARY_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            centerX,
            LayoutConstants.getY(dc, LayoutConstants.ROUTINE_NAME_Y_PERCENT),
            Graphics.FONT_XTINY,
            routine.name.toUpper(),
            Graphics.TEXT_JUSTIFY_CENTER
        );

        // 2. Paused indicator (if paused)
        if (_routineService.isPaused()) {
            dc.setColor(ColorUtils.COLOR_PAUSED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                centerX,
                LayoutConstants.getY(dc, LayoutConstants.ROUTINE_NAME_Y_PERCENT) + 18,
                Graphics.FONT_XTINY,
                "⏸ PAUSED",
                Graphics.TEXT_JUSTIFY_CENTER
            );
        }

        // 3. Time remaining (large, center, colored by state)
        var timerColor = ColorUtils.getTimerColor(remainingSeconds);
        
        // Apply pulse effect in alert state
        if (ColorUtils.shouldPulse(remainingSeconds) && _pulseState) {
            timerColor = ColorUtils.COLOR_PRIMARY_TEXT; // Flash between red and white
        }
        
        dc.setColor(timerColor, Graphics.COLOR_TRANSPARENT);
        var timeText = TimeFormatter.formatSmart(remainingSeconds);
        dc.drawText(
            centerX,
            LayoutConstants.getY(dc, LayoutConstants.TIME_CENTER_Y_PERCENT),
            Graphics.FONT_NUMBER_HOT,
            timeText,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // 4. Current step name
        var currentStep = _routineService.getCurrentStep();
        if (currentStep != null) {
            dc.setColor(ColorUtils.COLOR_PRIMARY_TEXT, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                centerX,
                LayoutConstants.getY(dc, LayoutConstants.STEP_NAME_Y_PERCENT),
                Graphics.FONT_SMALL,
                currentStep.name,
                Graphics.TEXT_JUSTIFY_CENTER
            );
        }

        // 5. Progress bar
        drawProgressBar(dc, remainingSeconds);

        // 6. Next step info
        drawNextStepInfo(dc, routine);

        // 7. Step indicator
        drawStepIndicator(dc, routine);

        // 8. Idle state hint
        if (_routineService.isIdle()) {
            dc.setColor(ColorUtils.COLOR_SECONDARY_TEXT, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                centerX,
                LayoutConstants.getY(dc, LayoutConstants.NEXT_STEP_Y_PERCENT),
                Graphics.FONT_XTINY,
                "Press START to begin",
                Graphics.TEXT_JUSTIFY_CENTER
            );
        }
    }

    private function drawProgressBar(dc as Dc, remainingSeconds as Number) as Void {
        var startX = LayoutConstants.getProgressBarStartX(dc);
        var barWidth = LayoutConstants.getProgressBarWidth(dc);
        var barY = LayoutConstants.getY(dc, LayoutConstants.PROGRESS_BAR_Y_PERCENT);
        var barHeight = LayoutConstants.PROGRESS_BAR_HEIGHT;

        // Background track (dark gray)
        dc.setColor(0x333333, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(startX, barY, barWidth, barHeight);

        // Progress fill
        var progress = _routineService.getCurrentStepProgress();
        var fillWidth = (barWidth * progress).toNumber();
        
        if (fillWidth > 0) {
            var progressColor = ColorUtils.getProgressColor(remainingSeconds);
            dc.setColor(progressColor, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(startX, barY, fillWidth, barHeight);
        }
    }

    private function drawNextStepInfo(dc as Dc, routine as Routine) as Void {
        if (_routineService.isIdle()) {
            return; // Don't show next step hint in idle state
        }

        var nextStep = _routineService.getNextStep();
        if (nextStep != null) {
            var centerX = dc.getWidth() / 2;
            var nextY = LayoutConstants.getY(dc, LayoutConstants.NEXT_STEP_Y_PERCENT);

            // Separator line
            var lineWidth = dc.getWidth() * 0.6;
            var lineStartX = (dc.getWidth() - lineWidth) / 2;
            dc.setColor(0x444444, Graphics.COLOR_TRANSPARENT);
            dc.drawLine(lineStartX, nextY - 10, lineStartX + lineWidth, nextY - 10);

            // Next step text
            dc.setColor(ColorUtils.COLOR_SECONDARY_TEXT, Graphics.COLOR_TRANSPARENT);
            var nextText = "NEXT: " + nextStep.name + "  " + 
                          TimeFormatter.formatSmart(nextStep.duration);
            dc.drawText(
                centerX,
                nextY,
                Graphics.FONT_XTINY,
                nextText,
                Graphics.TEXT_JUSTIFY_CENTER
            );
        }
    }

    private function drawStepIndicator(dc as Dc, routine as Routine) as Void {
        var centerX = dc.getWidth() / 2;
        var indicatorY = LayoutConstants.getY(dc, LayoutConstants.STEP_INDICATOR_Y_PERCENT);

        dc.setColor(ColorUtils.COLOR_SECONDARY_TEXT, Graphics.COLOR_TRANSPARENT);
        var stepText = "Step " + (_routineService.getCurrentStepIndex() + 1) + 
                      " of " + routine.getStepCount();
        dc.drawText(
            centerX,
            indicatorY,
            Graphics.FONT_XTINY,
            stepText,
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }

    private function drawCompleteScreen(dc as Dc, routine as Routine) as Void {
        var centerX = dc.getWidth() / 2;
        var centerY = dc.getHeight() / 2;

        // Large checkmark
        dc.setColor(ColorUtils.COLOR_SUCCESS, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            centerX,
            centerY - 50,
            Graphics.FONT_NUMBER_THAI_HOT,
            "✓",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // "ROUTINE COMPLETE" text
        dc.setColor(ColorUtils.COLOR_PRIMARY_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            centerX,
            centerY,
            Graphics.FONT_MEDIUM,
            "ROUTINE COMPLETE",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // Routine name
        dc.setColor(ColorUtils.COLOR_SECONDARY_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            centerX,
            centerY + 30,
            Graphics.FONT_SMALL,
            routine.name,
            Graphics.TEXT_JUSTIFY_CENTER
        );

        // Total time info
        var totalTime = routine.getTotalDuration();
        dc.drawText(
            centerX,
            centerY + 60,
            Graphics.FONT_XTINY,
            "Target: " + TimeFormatter.formatSmart(totalTime),
            Graphics.TEXT_JUSTIFY_CENTER
        );

        // Exit hint
        dc.drawText(
            centerX,
            dc.getHeight() - 30,
            Graphics.FONT_XTINY,
            "Press any button to exit",
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }

    function onHide() as Void {
    }

}
