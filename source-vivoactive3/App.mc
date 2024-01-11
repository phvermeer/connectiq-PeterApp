import Toybox.Application;
import Toybox.Communications;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Timer;
import Toybox.Attention;
import Toybox.Position;
import Toybox.Activity;

// interfaces for generic function support
class App extends Application.AppBase {
    hidden var started as Boolean = false;

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
        started = true;
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
        started = false;
    }

    // Return the initial view of your application here
    function getInitialView() as Array<Views or InputDelegates>? {
        var view = new StartView();
        var delegate = new ViewDelegate(view);
        return [ view, delegate ] as Array<Views or InputDelegates>;
    }
}

function getApp() as App {
    return Application.getApp() as App;
}