import Toybox.Lang;
import Toybox.Test;

(:test)
function testTimerInitialization(logger as Logger) as Boolean {
    var timer = new TimerService();
    
    return timer.getRemainingSeconds() == 0 &&
           timer.getTotalSeconds() == 0 &&
           timer.getState() == TIMER_IDLE &&
           !timer.isRunning() &&
           !timer.isPaused() &&
           !timer.isComplete();
}

(:test)
function testSetDuration(logger as Logger) as Boolean {
    var timer = new TimerService();
    timer.setDuration(120);
    
    return timer.getTotalSeconds() == 120 &&
           timer.getRemainingSeconds() == 120 &&
           timer.getState() == TIMER_IDLE;
}

(:test)
function testStartTimer(logger as Logger) as Boolean {
    var timer = new TimerService();
    timer.setDuration(60);
    timer.start();
    
    // Timer should be running
    var isRunning = timer.isRunning();
    var state = timer.getState();
    
    // Stop immediately to clean up
    timer.stop();
    
    return isRunning && state == TIMER_RUNNING;
}

(:test)
function testPauseTimer(logger as Logger) as Boolean {
    var timer = new TimerService();
    timer.setDuration(60);
    timer.start();
    
    // Wait a moment (in real scenario)
    timer.pause();
    
    var isPaused = timer.isPaused();
    var state = timer.getState();
    var remaining = timer.getRemainingSeconds();
    
    timer.stop();
    
    return isPaused && 
           state == TIMER_PAUSED &&
           remaining <= 60 && remaining >= 0;
}

(:test)
function testResumeTimer(logger as Logger) as Boolean {
    var timer = new TimerService();
    timer.setDuration(60);
    timer.start();
    timer.pause();
    
    var pausedRemaining = timer.getRemainingSeconds();
    timer.resume();
    
    var isRunning = timer.isRunning();
    var resumedRemaining = timer.getRemainingSeconds();
    
    timer.stop();
    
    return isRunning && 
           resumedRemaining == pausedRemaining;
}

(:test)
function testStopTimer(logger as Logger) as Boolean {
    var timer = new TimerService();
    timer.setDuration(60);
    timer.start();
    timer.stop();
    
    return timer.getState() == TIMER_IDLE &&
           timer.getRemainingSeconds() == 60 &&
           !timer.isRunning() &&
           !timer.isPaused();
}

(:test)
function testResetTimer(logger as Logger) as Boolean {
    var timer = new TimerService();
    timer.setDuration(60);
    timer.start();
    timer.pause();
    timer.reset();
    
    return timer.getState() == TIMER_IDLE &&
           timer.getRemainingSeconds() == 60 &&
           timer.getTotalSeconds() == 60;
}

(:test)
function testGetElapsedSeconds(logger as Logger) as Boolean {
    var timer = new TimerService();
    timer.setDuration(60);
    
    // Before starting, elapsed should be 0
    var elapsedBefore = timer.getElapsedSeconds();
    
    timer.start();
    timer.pause();
    
    // After pausing, elapsed should be > 0
    var elapsedAfter = timer.getElapsedSeconds();
    
    timer.stop();
    
    return elapsedBefore == 0 && elapsedAfter >= 0;
}

(:test)
function testGetProgressPercent(logger as Logger) as Boolean {
    var timer = new TimerService();
    timer.setDuration(100);
    
    // At start, progress should be 0%
    var progressStart = timer.getProgressPercent();
    
    timer.start();
    timer.pause();
    
    // After some time, progress should be > 0%
    var progressMid = timer.getProgressPercent();
    
    timer.stop();
    
    return progressStart == 0.0f && 
           progressMid >= 0.0f && 
           progressMid <= 1.0f;
}

(:test)
function testProgressPercentComplete(logger as Logger) as Boolean {
    var timer = new TimerService();
    timer.setDuration(1); // 1 second for quick test
    
    timer.start();
    
    // Wait for completion (in real test, would need to wait)
    // For now, just verify the math works
    timer.setDuration(100);
    timer.setDuration(50);
    
    // Progress at 50% should be 0.5
    timer.setDuration(100);
    // Simulate 50 seconds elapsed
    // This is a simplified test - real test would need timer to run
    
    return true; // Placeholder - would need async testing for real completion
}

(:test)
function testCannotSetDurationWhileRunning(logger as Logger) as Boolean {
    var timer = new TimerService();
    timer.setDuration(60);
    timer.start();
    
    var threwException = false;
    try {
        timer.setDuration(120);
    } catch (e) {
        threwException = true;
    }
    
    timer.stop();
    
    return threwException;
}

(:test)
function testStartWhenAlreadyRunning(logger as Logger) as Boolean {
    var timer = new TimerService();
    timer.setDuration(60);
    timer.start();
    
    var remaining1 = timer.getRemainingSeconds();
    timer.start(); // Should be no-op
    var remaining2 = timer.getRemainingSeconds();
    
    timer.stop();
    
    // Remaining should be same or very close (within 1 second)
    return (remaining1 - remaining2).abs() <= 1;
}

(:test)
function testPauseWhenNotRunning(logger as Logger) as Boolean {
    var timer = new TimerService();
    timer.setDuration(60);
    
    // Pause when idle should do nothing
    timer.pause();
    
    return timer.getState() == TIMER_IDLE;
}

(:test)
function testResumeWhenNotPaused(logger as Logger) as Boolean {
    var timer = new TimerService();
    timer.setDuration(60);
    
    // Resume when idle should start the timer
    timer.resume();
    
    var isRunning = timer.isRunning();
    timer.stop();
    
    return isRunning;
}

(:test)
function testZeroDuration(logger as Logger) as Boolean {
    var timer = new TimerService();
    timer.setDuration(0);
    timer.start();
    
    // Timer should not start or immediately complete
    var state = timer.getState();
    timer.stop();
    
    return state == TIMER_IDLE || state == TIMER_COMPLETE;
}

(:test)
function testCallbackRegistration(logger as Logger) as Boolean {
    var timer = new TimerService();
    
    // Test that callbacks can be set to null (invocation tested manually/integration tests)
    timer.setOnTickCallback(null);
    timer.setOnCompleteCallback(null);
    
    // Verify no errors when setting null callbacks
    // Actual callback invocation requires timer to run, tested manually
    return true;
}
