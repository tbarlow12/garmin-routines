import Toybox.Lang;

module TestDataFactory {
    // Create a sample morning routine for testing
    function createMorningRoutine() as Routine {
        var routine = new Routine({
            :id => "test_morning",
            :name => "Morning Routine"
        });

        routine.addStep(new Step({
            :name => "Scripture Study",
            :duration => 20  // 20 seconds for testing (normally 20 * 60)
        }));

        routine.addStep(new Step({
            :name => "Tidy up office",
            :duration => 5   // 5 seconds for testing (normally 5 * 60)
        }));

        routine.addStep(new Step({
            :name => "Fill water bottle",
            :duration => 2   // 2 seconds for testing (normally 2 * 60)
        }));

        return routine;
    }

    // Create a quick test routine with short durations
    function createQuickTestRoutine() as Routine {
        var routine = new Routine({
            :id => "test_quick",
            :name => "Quick Test"
        });

        routine.addStep(new Step({
            :name => "Step One",
            :duration => 5  // 5 seconds
        }));

        routine.addStep(new Step({
            :name => "Step Two",
            :duration => 5  // 5 seconds
        }));

        routine.addStep(new Step({
            :name => "Step Three",
            :duration => 5  // 5 seconds
        }));

        return routine;
    }

    // Create a single-step routine
    function createSingleStepRoutine() as Routine {
        var routine = new Routine({
            :id => "test_single",
            :name => "Single Step"
        });

        routine.addStep(new Step({
            :name => "Only Step",
            :duration => 10
        }));

        return routine;
    }
}
