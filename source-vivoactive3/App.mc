import Toybox.Application;
import Toybox.Communications;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Timer;
import Toybox.Attention;
import Toybox.Position;
import Toybox.Activity;
import MyBarrel.Views;

// interfaces for generic function support
class App extends Application.AppBase {
    hidden var started as Boolean = false;
    public var settings as Settings;
    public var session as Session;
    public var data as Data;

    function initialize() {
        AppBase.initialize();
        log("1");
        session = new Session({});
        log("2");
        settings = new Settings();
        log("3");
        data = new Data({});
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
        started = true;
        log("started");
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
        started = false;
        log("stopped");
    }

    function onSetting(id as Settings.Id, value as Settings.ValueType) as Void{

    }

    // Return the initial view of your application here
    function getInitialView() as Array<WatchUi.Views or WatchUi.InputDelegates>? {
        var delegate = new Views.MyViewDelegate();
        var view = new StartView(delegate);
        return [ view, delegate ] as Array<WatchUi.Views or WatchUi.InputDelegates>;
    }
}

function getApp() as App {
    return Application.getApp() as App;
}

function log(msg as String) as Void{
    var stats = Toybox.System.getSystemStats();
    Toybox.System.println(Lang.format("$1$ ($2$%)", [msg, 100f * stats.usedMemory/stats.totalMemory]));
}