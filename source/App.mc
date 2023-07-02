import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Timer;

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
    var settings as Settings;
    var session as Session;
    var track as Track?;
    var fieldManager as FieldManager;
    var delegate as ViewDelegate?;


    hidden var timer as Timer.Timer;

    function initialize() {
        AppBase.initialize();

        settings = new Settings({
            :onChanged => method(:onMySettingsChanged)
        });

        session = new Session({
            :onStateChange => method(:onSessionState)
        });

        fieldManager = new FieldManager();

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

    function onMySettingsChanged(screenId as Number?, paramId as String, value as PropertyValueType) as Void {

    }

    function onSessionState(state as SessionState) as Void {
        if(delegate != null && delegate has :onSessionState){
            (delegate as SessionStateListener).onSessionState(state);
        }
    }

    function onTimer() as Void{
        if(delegate != null && delegate has :onTimer){
            (delegate as TimerListener).onTimer();
        }
    }

    // Return the initial view of your application here
    function getInitialView() as Array<Views or InputDelegates>? {
        var view = new StartView();
        delegate = new ViewDelegate(view);
        return [ view, delegate ] as Array<Views or InputDelegates>;
    }

    function getDelegate() as ViewDelegate{
        if(delegate != null){
            return delegate;
        }
        throw new MyTools.MyException("Delegate is not yet available");
    }
}

function getApp() as App {
    return Application.getApp() as App;
}