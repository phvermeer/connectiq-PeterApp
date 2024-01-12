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
    function onSessionState(state as SessionState) as Void;
};

class App extends Application.AppBase {
    var settings as Settings;
    var session as Session;
    var track as Track?;
    var fieldManager as FieldManager;
    var data as Data;
//    var history as MyHistoryIterator = new MyHistoryIterator();
    var started as Boolean = false;

    function initialize() {
        AppBase.initialize();
        settings = new Settings();

        data = new Data({
            :breadcrumpsEnabled => settings.get(SETTING_BREADCRUMPS) as Boolean,
            :breadcrumpsDistance => settings.get(SETTING_BREADCRUMPS_MIN_DISTANCE) as Number,
            :breadCrumpsMax => settings.get(SETTING_BREADCRUMPS_MAX_COUNT) as Number,
        });

        fieldManager = new FieldManager();

        session = new Session({
            :sport => settings.get(SETTING_SPORT) as Activity.Sport,
            :autoLapEnabled => settings.get(SETTING_AUTOLAP) as Boolean,
            :autoLapDistance => settings.get(SETTING_AUTOLAP_DISTANCE) as Float,
            :autoPause => settings.get(SETTING_AUTOPAUSE) as Boolean,
        });


        Communications.registerForPhoneAppMessages(method(:onPhone));

        // initial track
        var trackData = settings.get(SETTING_TRACK);
        if(trackData instanceof Array){
            track = new Track(trackData as Array);
            data.setTrack(track);
        }

        data.addListener(session);
        settings.addListener(session);
        settings.addListener(data); // breadcrumps settings
        session.addListener(self); // modify data interval/start/stop
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
        data.startTimer();
        started = true;
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
        data.stopTimer();
        data.stopPositioning();
        session.stop();
        started = false;
    }

    function onSessionState(state as SessionState) as Void {
        // start/stop positioning events
        switch(state){
            case SESSION_STATE_IDLE:
            case SESSION_STATE_STOPPED:
                // stop events
	            data.stopPositioning();
                break;
            case SESSION_STATE_BUSY:
                // start events
                data.startPositioning();
                break;
        }
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
            settings.set(SETTING_TRACK, data as Array<PropertyValueType>);
        }
    }

    // Return the initial view of your application here
    function getInitialView() as Array<Views or InputDelegates>? {
        var view = new StartView({});
        var delegate = new ViewDelegate({:view => view});
        view.setDelegate(delegate);
        return [ view, delegate ] as Array<Views or InputDelegates>;
    }
}

function getApp() as App {
    return Application.getApp() as App;
}