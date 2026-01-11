import Toybox.Lang;
import Toybox.Time;
import Toybox.System;

// Trigger types for routines
enum TriggerType {
    TRIGGER_MANUAL,
    TRIGGER_SCHEDULED,
    TRIGGER_EVENT
}

class Routine {
    var id as String;
    var name as String;
    var steps as Array<Step>;
    var createdAt as Number;
    var updatedAt as Number;
    var triggerType as TriggerType;
    var scheduledTime as Number?;      // Seconds from midnight
    var scheduledDays as Array<Number>?; // 0=Sun, 1=Mon, ..., 6=Sat

    function initialize(options as Dictionary) {
        id = options.hasKey(:id) ? options[:id] as String : generateId();
        name = options.hasKey(:name) ? options[:name] as String : "New Routine";
        steps = options.hasKey(:steps) ? options[:steps] as Array<Step> : [];
        createdAt = options.hasKey(:createdAt) ? options[:createdAt] as Number : Time.now().value();
        updatedAt = options.hasKey(:updatedAt) ? options[:updatedAt] as Number : Time.now().value();
        triggerType = options.hasKey(:triggerType) ? options[:triggerType] as TriggerType : TRIGGER_MANUAL;
        scheduledTime = options.hasKey(:scheduledTime) ? options[:scheduledTime] as Number? : null;
        scheduledDays = options.hasKey(:scheduledDays) ? options[:scheduledDays] as Array<Number>? : null;
    }

    private function generateId() as String {
        var time = System.getTimer();
        return "routine_" + time.toString();
    }

    // Get total duration of all steps in seconds
    function getTotalDuration() as Number {
        var total = 0;
        for (var i = 0; i < steps.size(); i++) {
            total += steps[i].duration;
        }
        return total;
    }

    // Get step count
    function getStepCount() as Number {
        return steps.size();
    }

    // Get step by index
    function getStep(index as Number) as Step? {
        if (index >= 0 && index < steps.size()) {
            return steps[index];
        }
        return null;
    }

    // Add a step
    function addStep(step as Step) as Void {
        step.order = steps.size();
        steps.add(step);
        updatedAt = Time.now().value();
    }

    // Remove a step by index
    function removeStep(index as Number) as Void {
        if (index >= 0 && index < steps.size()) {
            steps.remove(steps[index]);
            // Reorder remaining steps
            for (var i = 0; i < steps.size(); i++) {
                steps[i].order = i;
            }
            updatedAt = Time.now().value();
        }
    }

    // Serialize to dictionary for storage
    function toDict() as Dictionary {
        var stepsArray = [];
        for (var i = 0; i < steps.size(); i++) {
            stepsArray.add(steps[i].toDict());
        }

        return {
            "id" => id,
            "name" => name,
            "steps" => stepsArray,
            "createdAt" => createdAt,
            "updatedAt" => updatedAt,
            "triggerType" => triggerType,
            "scheduledTime" => scheduledTime,
            "scheduledDays" => scheduledDays
        };
    }

    // Create from dictionary (deserialization)
    static function fromDict(dict as Dictionary) as Routine {
        var stepsData = dict["steps"] as Array;
        var stepObjects = [] as Array<Step>;
        
        for (var i = 0; i < stepsData.size(); i++) {
            stepObjects.add(Step.fromDict(stepsData[i] as Dictionary));
        }

        return new Routine({
            :id => dict["id"] as String,
            :name => dict["name"] as String,
            :steps => stepObjects,
            :createdAt => dict["createdAt"] as Number,
            :updatedAt => dict["updatedAt"] as Number,
            :triggerType => dict["triggerType"] as TriggerType,
            :scheduledTime => dict.hasKey("scheduledTime") ? dict["scheduledTime"] as Number? : null,
            :scheduledDays => dict.hasKey("scheduledDays") ? dict["scheduledDays"] as Array<Number>? : null
        });
    }
}
