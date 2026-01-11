import Toybox.Lang;
import Toybox.System;

class Step {
    var id as String;
    var name as String;
    var duration as Number;  // Duration in seconds
    var order as Number;
    var alertSound as Boolean;
    var alertVibrate as Boolean;

    function initialize(options as Dictionary) {
        id = options.hasKey(:id) ? options[:id] as String : generateId();
        name = options.hasKey(:name) ? options[:name] as String : "Step";
        duration = options.hasKey(:duration) ? options[:duration] as Number : 60;
        order = options.hasKey(:order) ? options[:order] as Number : 0;
        alertSound = options.hasKey(:alertSound) ? options[:alertSound] as Boolean : false;
        alertVibrate = options.hasKey(:alertVibrate) ? options[:alertVibrate] as Boolean : true;
    }

    // Generate a simple unique ID
    private function generateId() as String {
        var time = System.getTimer();
        return "step_" + time.toString();
    }

    // Serialize to dictionary for storage
    function toDict() as Dictionary {
        return {
            "id" => id,
            "name" => name,
            "duration" => duration,
            "order" => order,
            "alertSound" => alertSound,
            "alertVibrate" => alertVibrate
        };
    }

    // Create from dictionary (deserialization)
    static function fromDict(dict as Dictionary) as Step {
        return new Step({
            :id => dict["id"] as String,
            :name => dict["name"] as String,
            :duration => dict["duration"] as Number,
            :order => dict["order"] as Number,
            :alertSound => dict["alertSound"] as Boolean,
            :alertVibrate => dict["alertVibrate"] as Boolean
        });
    }
}
