import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Timer;

// global objects
var settings as Settings?;
var session as Session?;
var delegate as WeakReference?;

// interfaces for generic function support
typedef SessionStateListener as interface {
    function onSessionState(state as SessionState) as Void;
};
typedef TimerListener as interface {
    function onTimer() as Void;
};
typedef PositionListener as interface {
    function onPosition() as Void;
};

class App extends Application.AppBase {
    var timer as Timer.Timer;

    function initialize() {
        AppBase.initialize();

        $.settings = new Settings({
            :onChanged => method(:onMySettingsChanged)
        });

        $.session = new Session({
            :onStateChange => method(:onSessionState)
        });

        timer = new Timer.Timer();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
        timer.start(method(:onTimer), 1000, true);
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
        timer.stop();
    }

    hidden function getDelegate() as ViewDelegate?{
        var ref = $.delegate;
        if (ref != null){
            if(ref.stillAlive()){
                return ref.get();
            }
        }
        return null;
    }

    function onMySettingsChanged(screenId as Number?, paramId as String, value as PropertyValueType) as Void {

    }

    function onSessionState(state as SessionState) as Void {
        var delegate = getDelegate();
        if(delegate != null && delegate has :onSessionState){
            (delegate as SessionStateListener).onSessionState(state);
        }
    }

    function onTimer() as Void{
        var delegate = getDelegate();
        if(delegate != null && delegate has :onTimer){
            (delegate as TimerListener).onTimer();
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