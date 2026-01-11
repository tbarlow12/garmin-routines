import Toybox.Lang;
import Toybox.Timer;
import Toybox.System;

// Timer states
enum TimerState {
    TIMER_IDLE,
    TIMER_RUNNING,
    TIMER_PAUSED,
    TIMER_COMPLETE
}

// Callback interface for timer events
typedef TimerCallback as Method() as Void;

class TimerService {
    private var _timer as Timer.Timer?;
    private var _remainingSeconds as Number;
    private var _totalSeconds as Number;
    private var _state as TimerState;
    private var _onTickCallback as TimerCallback?;
    private var _onCompleteCallback as TimerCallback?;

    function initialize() {
        _timer = null;
        _remainingSeconds = 0;
        _totalSeconds = 0;
        _state = TIMER_IDLE;
        _onTickCallback = null;
        _onCompleteCallback = null;
    }

    // Configure the timer with a duration in seconds
    function setDuration(seconds as Number) as Void {
        if (_state == TIMER_RUNNING) {
            throw new Lang.InvalidValueException("Cannot set duration while running");
        }
        _totalSeconds = seconds;
        _remainingSeconds = seconds;
        _state = TIMER_IDLE;
    }

    // Start or resume the timer
    function start() as Void {
        if (_state == TIMER_RUNNING) {
            return; // Already running
        }
        if (_remainingSeconds <= 0) {
            return; // Nothing to count
        }
        
        _state = TIMER_RUNNING;
        _timer = new Timer.Timer();
        _timer.start(method(:onTimerTick), 1000, true); // 1 second interval
    }

    // Pause the timer
    function pause() as Void {
        if (_state != TIMER_RUNNING) {
            return;
        }
        _state = TIMER_PAUSED;
        if (_timer != null) {
            _timer.stop();
            _timer = null;
        }
    }

    // Resume from pause
    function resume() as Void {
        if (_state != TIMER_PAUSED) {
            return;
        }
        start();
    }

    // Stop and reset the timer
    function stop() as Void {
        if (_timer != null) {
            _timer.stop();
            _timer = null;
        }
        _remainingSeconds = _totalSeconds;
        _state = TIMER_IDLE;
    }

    // Reset to initial duration
    function reset() as Void {
        stop();
    }

    // Timer tick handler (called every second)
    function onTimerTick() as Void {
        if (_state != TIMER_RUNNING) {
            return;
        }

        _remainingSeconds -= 1;

        // Notify tick listener
        if (_onTickCallback != null) {
            _onTickCallback.invoke();
        }

        // Check for completion
        if (_remainingSeconds <= 0) {
            _remainingSeconds = 0;
            _state = TIMER_COMPLETE;
            
            if (_timer != null) {
                _timer.stop();
                _timer = null;
            }

            if (_onCompleteCallback != null) {
                _onCompleteCallback.invoke();
            }
        }
    }

    // Register callback for each tick
    function setOnTickCallback(callback as TimerCallback?) as Void {
        _onTickCallback = callback;
    }

    // Register callback for timer completion
    function setOnCompleteCallback(callback as TimerCallback?) as Void {
        _onCompleteCallback = callback;
    }

    // Getters
    function getRemainingSeconds() as Number {
        return _remainingSeconds;
    }

    function getTotalSeconds() as Number {
        return _totalSeconds;
    }

    function getElapsedSeconds() as Number {
        return _totalSeconds - _remainingSeconds;
    }

    function getState() as TimerState {
        return _state;
    }

    function isRunning() as Boolean {
        return _state == TIMER_RUNNING;
    }

    function isPaused() as Boolean {
        return _state == TIMER_PAUSED;
    }

    function isComplete() as Boolean {
        return _state == TIMER_COMPLETE;
    }

    function getProgressPercent() as Float {
        if (_totalSeconds == 0) {
            return 0.0f;
        }
        return (_totalSeconds - _remainingSeconds).toFloat() / _totalSeconds.toFloat();
    }
}
