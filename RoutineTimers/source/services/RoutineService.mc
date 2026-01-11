import Toybox.Lang;
import Toybox.WatchUi;

// Routine execution states
enum RoutineState {
    ROUTINE_IDLE,
    ROUTINE_RUNNING,
    ROUTINE_PAUSED,
    ROUTINE_COMPLETE
}

typedef RoutineCallback as Method() as Void;
typedef StepChangeCallback as Method(stepIndex as Number, step as Step) as Void;

class RoutineService {
    private var _routine as Routine?;
    private var _timerService as TimerService;
    private var _currentStepIndex as Number;
    private var _state as RoutineState;
    private var _autoAdvance as Boolean;

    // Callbacks
    private var _onStepChangeCallback as StepChangeCallback?;
    private var _onRoutineCompleteCallback as RoutineCallback?;
    private var _onTickCallback as RoutineCallback?;

    function initialize() {
        _timerService = new TimerService();
        _timerService.setOnTickCallback(method(:onTimerTick));
        _timerService.setOnCompleteCallback(method(:onStepComplete));
        
        _routine = null;
        _currentStepIndex = 0;
        _state = ROUTINE_IDLE;
        _autoAdvance = true;

        _onStepChangeCallback = null;
        _onRoutineCompleteCallback = null;
        _onTickCallback = null;
    }

    // Load a routine for execution
    function loadRoutine(routine as Routine) as Void {
        if (_state == ROUTINE_RUNNING) {
            stop();
        }
        
        _routine = routine;
        _currentStepIndex = 0;
        _state = ROUTINE_IDLE;
        
        // Load first step into timer
        var firstStep = _routine.getStep(0);
        if (firstStep != null) {
            _timerService.setDuration(firstStep.duration);
        }
    }

    // Start the routine
    function start() as Void {
        if (_routine == null || _routine.getStepCount() == 0) {
            return;
        }

        if (_state == ROUTINE_PAUSED) {
            _timerService.resume();
            _state = ROUTINE_RUNNING;
            return;
        }

        if (_state != ROUTINE_IDLE) {
            return;
        }

        _state = ROUTINE_RUNNING;
        _currentStepIndex = 0;
        
        startCurrentStep();
    }

    // Pause the routine
    function pause() as Void {
        if (_state != ROUTINE_RUNNING) {
            return;
        }
        _timerService.pause();
        _state = ROUTINE_PAUSED;
    }

    // Resume the routine
    function resume() as Void {
        if (_state != ROUTINE_PAUSED) {
            return;
        }
        _timerService.resume();
        _state = ROUTINE_RUNNING;
    }

    // Stop and reset the routine
    function stop() as Void {
        _timerService.stop();
        _currentStepIndex = 0;
        _state = ROUTINE_IDLE;
        
        // Reload first step
        if (_routine != null) {
            var firstStep = _routine.getStep(0);
            if (firstStep != null) {
                _timerService.setDuration(firstStep.duration);
            }
        }
    }

    // Skip to next step
    function nextStep() as Void {
        if (_routine == null) {
            return;
        }

        if (_currentStepIndex < _routine.getStepCount() - 1) {
            _currentStepIndex++;
            startCurrentStep();
        } else {
            // Already on last step, complete the routine
            completeRoutine();
        }
    }

    // Go to previous step
    function previousStep() as Void {
        if (_routine == null) {
            return;
        }

        if (_currentStepIndex > 0) {
            _currentStepIndex--;
            startCurrentStep();
        } else {
            // If on first step, just restart it
            startCurrentStep();
        }
    }

    // Jump to a specific step
    function goToStep(index as Number) as Void {
        if (_routine == null) {
            return;
        }

        if (index >= 0 && index < _routine.getStepCount()) {
            _currentStepIndex = index;
            startCurrentStep();
        }
    }

    // Start the current step
    private function startCurrentStep() as Void {
        if (_routine == null) {
            return;
        }

        var step = _routine.getStep(_currentStepIndex);
        if (step == null) {
            return;
        }

        _timerService.stop();
        _timerService.setDuration(step.duration);
        
        if (_state == ROUTINE_RUNNING) {
            _timerService.start();
        }

        // Notify step change
        if (_onStepChangeCallback != null) {
            _onStepChangeCallback.invoke(_currentStepIndex, step);
        }
    }

    // Called when a step's timer completes
    function onStepComplete() as Void {
        if (_routine == null) {
            return;
        }

        // Check if there are more steps
        if (_currentStepIndex < _routine.getStepCount() - 1) {
            if (_autoAdvance) {
                nextStep();
            } else {
                _state = ROUTINE_PAUSED;
            }
        } else {
            // Last step completed
            completeRoutine();
        }
    }

    // Complete the routine
    private function completeRoutine() as Void {
        _state = ROUTINE_COMPLETE;
        _timerService.stop();

        if (_onRoutineCompleteCallback != null) {
            _onRoutineCompleteCallback.invoke();
        }
    }

    // Called on each timer tick
    function onTimerTick() as Void {
        if (_onTickCallback != null) {
            _onTickCallback.invoke();
        }
    }

    // Setters for callbacks
    function setOnStepChangeCallback(callback as StepChangeCallback?) as Void {
        _onStepChangeCallback = callback;
    }

    function setOnRoutineCompleteCallback(callback as RoutineCallback?) as Void {
        _onRoutineCompleteCallback = callback;
    }

    function setOnTickCallback(callback as RoutineCallback?) as Void {
        _onTickCallback = callback;
    }

    function setAutoAdvance(autoAdvance as Boolean) as Void {
        _autoAdvance = autoAdvance;
    }

    // Getters
    function getRoutine() as Routine? {
        return _routine;
    }

    function getCurrentStepIndex() as Number {
        return _currentStepIndex;
    }

    function getCurrentStep() as Step? {
        if (_routine != null) {
            return _routine.getStep(_currentStepIndex);
        }
        return null;
    }

    function getNextStep() as Step? {
        if (_routine != null && _currentStepIndex < _routine.getStepCount() - 1) {
            return _routine.getStep(_currentStepIndex + 1);
        }
        return null;
    }

    function getRemainingSeconds() as Number {
        return _timerService.getRemainingSeconds();
    }

    function getCurrentStepProgress() as Float {
        return _timerService.getProgressPercent();
    }

    function getState() as RoutineState {
        return _state;
    }

    function isRunning() as Boolean {
        return _state == ROUTINE_RUNNING;
    }

    function isPaused() as Boolean {
        return _state == ROUTINE_PAUSED;
    }

    function isComplete() as Boolean {
        return _state == ROUTINE_COMPLETE;
    }

    function isIdle() as Boolean {
        return _state == ROUTINE_IDLE;
    }

    // Calculate total elapsed time across all completed steps + current step progress
    function getTotalElapsedSeconds() as Number {
        if (_routine == null) {
            return 0;
        }

        var elapsed = 0;
        
        // Add durations of completed steps
        for (var i = 0; i < _currentStepIndex; i++) {
            var step = _routine.getStep(i);
            if (step != null) {
                elapsed += step.duration;
            }
        }

        // Add elapsed time in current step
        var currentStep = getCurrentStep();
        if (currentStep != null) {
            elapsed += currentStep.duration - _timerService.getRemainingSeconds();
        }

        return elapsed;
    }

    // Get overall routine progress (0.0 to 1.0)
    function getOverallProgress() as Float {
        if (_routine == null) {
            return 0.0f;
        }

        var total = _routine.getTotalDuration();
        if (total == 0) {
            return 0.0f;
        }

        return getTotalElapsedSeconds().toFloat() / total.toFloat();
    }
}
