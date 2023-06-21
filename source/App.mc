import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

// global objects
var settings as Settings?;
var session as Session?;

class App extends Application.AppBase {

    function initialize() {
        AppBase.initialize();

        $.settings = new Settings({
            :onChanged => method(:onMySettingsChanged)
        });

        $.session = new Session({
            :onChanged => method(:onSessionStateChanged)
        });
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    function onMySettingsChanged(screenId as Number?, paramId as String, value as PropertyValueType) as Void {

    }

    function onSessionStateChanged(state as Session.SessionState) as Void {

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