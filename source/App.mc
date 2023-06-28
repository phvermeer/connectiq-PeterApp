import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

// global objects
var settings as Settings?;
var session as Session?;
var delegate as WeakReference?;

// interfaces for generic function support
typedef UseSessionState as interface {
    function onSessionStateChange(state as SessionState) as Void;
};


class App extends Application.AppBase {

    function initialize() {
        AppBase.initialize();

        $.settings = new Settings({
            :onChanged => method(:onMySettingsChanged)
        });

        $.session = new Session({
            :onStateChange => method(:onSessionStateChange)
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

    function onSessionStateChange(state as SessionState) as Void {
        var ref = $.delegate;
        if (ref != null){
            if(ref.stillAlive()){
                var delegate = ref.get();
                if(delegate has :onSessionStateChange){
                    (delegate as UseSessionState).onSessionStateChange(state);
                }
            }
        }
    }

    // Return the initial view of your application here
    function getInitialView() as Array<Views or InputDelegates>? {
        var view = new StartView();
        var delegate = new ViewDelegate(view);
        $.delegate = delegate.weak();
        return [ view, delegate ] as Array<Views or InputDelegates>;
    }

}

function getApp() as App {
    return Application.getApp() as App;
}