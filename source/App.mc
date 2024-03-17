import Toybox.Application;
import Toybox.Communications;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Timer;
import Toybox.Attention;
import Toybox.Position;
import Toybox.Activity;
import MyBarrel.Layout;

// interfaces for generic function support
typedef SessionStateListener as interface {
    function onSessionState(sender as Object, state as SessionState) as Void;
};

class App extends Application.AppBase {
    var settings as Settings;
    var session as Session;
    (:track)
    var trackManager as TrackManager;
    var fieldManager as FieldManager;
    var data as Data;
//    var history as MyHistoryIterator = new MyHistoryIterator();
    var started as Boolean = false;

    (:noTrack)
    function initialize() {
        AppBase.initialize();
        settings = new Settings();
        session = new Session({
            :sport => settings.get(Settings.ID_SPORT) as Activity.Sport,
            :autoLapEnabled => settings.get(Settings.ID_AUTOLAP) as Boolean,
            :autoLapDistance => settings.get(Settings.ID_AUTOLAP_DISTANCE) as Float,
            :autoPause => settings.get(Settings.ID_AUTOPAUSE) as Boolean,
        });
        data = new Data({});
        fieldManager = new FieldManager();

        // link events
        data.addListener(session);
        data.addListener(self);
        settings.addListener(session);
        session.addListener(self); // modify data interval/start/stop
    }

    (:track)
    function initialize() {
        AppBase.initialize();
        settings = new Settings();

        data = new Data({
            :breadcrumpsEnabled => settings.get(Settings.ID_BREADCRUMPS) as Boolean,
            :breadcrumpsDistance => settings.get(Settings.ID_BREADCRUMPS_MIN_DISTANCE) as Number,
            :breadCrumpsMax => settings.get(Settings.ID_BREADCRUMPS_MAX_COUNT) as Number,
        });

        fieldManager = new FieldManager();
        trackManager = new TrackManager();

        session = new Session({
            :sport => settings.get(Settings.ID_SPORT) as Activity.Sport,
            :autoLapEnabled => settings.get(Settings.ID_AUTOLAP) as Boolean,
            :autoLapDistance => settings.get(Settings.ID_AUTOLAP_DISTANCE) as Float,
            :autoPause => settings.get(Settings.ID_AUTOPAUSE) as Boolean,
        });

        Communications.registerForPhoneAppMessages(method(:onPhone));

        // initial track
        var rawData = settings.get(Settings.ID_TRACK);
        var track = convertToTrack(rawData as Array);
        trackManager.onSetting(self, Settings.ID_TRACK, track);

        data.addListener(session);
        data.addListener(self);
        settings.addListener(session);
        settings.addListener(data); // breadcrumps settings
        settings.addListener(trackManager); // track changes
        session.addListener(trackManager); // modify data interval/start/stop
        session.addListener(data);
        trackManager.addListener(data);
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
        data.startTimer();
        started = true;
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
        data.stopTimer();
        session.stop();
        started = false;
    }

    function onActivityInfo(sender as Data, info as Activity.Info) as Void{
        fieldManager.cleanup();
    }
    
    function onPhone(msg as Communications.Message) as Void{
        // receive track data
        if(msg.data instanceof Array){
            var data = msg.data as Array;

            // vibrate when track is received
            if(Attention has :vibrate){
                Attention.vibrate([new Attention.VibeProfile(25, 1000)] as Array<VibeProfile>);
            }

            // save track data in storage and inform listeners
            settings.set(Settings.ID_TRACK, data as Array<PropertyValueType>);
        }
    }

    // Return the initial view of your application here
    function getInitialView() as Array<Views or InputDelegates>? {
        var delegate = new ViewDelegate();
        var view = new StartView(delegate);
        return [ view, delegate ] as Array<Views or InputDelegates>;
    }
}

function getApp() as App {
    return Application.getApp() as App;
}

function log(msg as String) as Void{
    var stats = Toybox.System.getSystemStats();
    Toybox.System.println(Lang.format("$1$ ($2$%)", [msg, 100f * stats.usedMemory/stats.totalMemory]));
}