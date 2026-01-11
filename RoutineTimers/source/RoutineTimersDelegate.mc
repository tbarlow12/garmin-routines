import Toybox.Lang;
import Toybox.WatchUi;

class RoutineTimersDelegate extends WatchUi.BehaviorDelegate {
    private var _view as RoutineTimersView;

    function initialize(view as RoutineTimersView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    // START/SELECT button
    function onSelect() as Boolean {
        var service = _view.getRoutineService();
        
        // If complete, allow exit (as per spec: "Press any button to exit")
        if (service.isComplete()) {
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
            return true;
        }
        
        if (service.isRunning()) {
            service.pause();
        } else if (service.isPaused()) {
            service.resume();
        } else {
            service.start();
        }
        
        WatchUi.requestUpdate();
        return true;
    }

    // UP button - previous step
    function onPreviousPage() as Boolean {
        var service = _view.getRoutineService();
        if (service.isRunning() || service.isPaused()) {
            service.previousStep();
            WatchUi.requestUpdate();
            return true;
        }
        return false;
    }

    // DOWN button - next step
    function onNextPage() as Boolean {
        var service = _view.getRoutineService();
        if (service.isRunning() || service.isPaused()) {
            service.nextStep();
            WatchUi.requestUpdate();
            return true;
        }
        return false;
    }

    // BACK button
    function onBack() as Boolean {
        var service = _view.getRoutineService();
        
        // If complete, allow exit
        if (service.isComplete()) {
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
            return true;
        }
        
        if (service.isRunning() || service.isPaused()) {
            service.stop();
            WatchUi.requestUpdate();
            return true;
        }
        
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }

}