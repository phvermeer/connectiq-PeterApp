import Toybox.Application;
import Toybox.Communications;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Timer;
import Toybox.Attention;
import Toybox.Position;
import Toybox.Activity;
import MyViews;

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
    var delegate as ViewDelegate?;
    var history as MyHistoryIterator = new MyHistoryIterator();
    var started as Boolean = false;

    function initialize() {
        AppBase.initialize();

        fieldManager = new FieldManager();
        settings = new Settings({ :onValueChange => method(:onSetting) });

        var autoLap = (settings.get(SETTING_AUTOLAP) as Boolean)
            ? settings.get(SETTING_AUTOLAP_DISTANCE) as Float 
            : null;
        data = new Data({
            :loggingEnabled => settings.get(SETTING_BREADCRUMPS) as Boolean,
            :minDistance => settings.get(SETTING_BREADCRUMPS_MIN_DISTANCE) as Number,
            :size => settings.get(SETTING_BREADCRUMPS_MAX_COUNT) as Number,
        });
        session = new Session({
            :onStateChange => method(:onSessionState),
            :autoLap => autoLap,
            :autoPause => settings.get(SETTING_AUTOPAUSE) as Boolean,
        });
        data.addListener(session);

        Communications.registerForPhoneAppMessages(method(:onPhone));

        // initial track
        var trackData = settings.get(SETTING_TRACK);
        if(trackData instanceof Array){
            track = new Track(trackData as Array);
            data.setCenter(track.latlonCenter);
            data.addListener(track as Object);
        }

    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
        data.start();
        started = true;
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
        data.stop();
        started = false;
    }

    function onSetting(id as SettingId, value as PropertyValueType) as Void {
        if(!started){
            return;
        }
        if(id == SETTING_AUTOPAUSE){
            session.setAutoPause(value as Boolean);
        }else if(id == SETTING_AUTOLAP || id == SETTING_AUTOLAP_DISTANCE){
            var autoLap = (settings.get(SETTING_AUTOLAP) as Boolean)
                ? settings.get(SETTING_AUTOLAP_DISTANCE) as Float
                : null;
            session.setAutoLap(autoLap);
        }else if(id == SETTING_BREADCRUMPS){
            data.setLoggingEnabled(value as Boolean);
        }else if(id == SETTING_BREADCRUMPS_MIN_DISTANCE){
            data.setMinDistance(value as Number);
        }else if(id == SETTING_BREADCRUMPS_MAX_COUNT){
            data.setSize(value as Number);
        }else{
            if(id == SETTING_TRACK){
                history.clear();
                if(track != null){
                    data.setCenter(track.latlonCenter);
                    data.addListener(track as Object);
                }
            }

            fieldManager.onSetting(id, value);
            if(delegate != null){
                delegate.onSettingChange(id, value);
            }
        }
    }

    function onSessionState(state as SessionState) as Void {
        if(delegate != null && delegate has :onSessionState){
            (delegate as SessionStateListener).onSessionState(state);
        }

        // start/stop positioning events
        switch(state){
            case SESSION_STATE_IDLE:
            case SESSION_STATE_STOPPED:
                // stop events
	            data.stop();
                break;
            case SESSION_STATE_BUSY:
                // start events
                data.start();
                break;
        }
    }

    function onPhone(msg as Communications.Message) as Void{
        System.println("onPhone message received");

        // receive track data
        if(msg.data instanceof Array){
            var data = msg.data as Array;
            track = new Track(data);

            // vibrate when track is received
            if(Attention has :vibrate){
                Attention.vibrate([new Attention.VibeProfile(25, 1000)] as Array<VibeProfile>);
            }

            // save track data in storage
            settings.set(SETTING_TRACK, data as Array<PropertyValueType>);
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