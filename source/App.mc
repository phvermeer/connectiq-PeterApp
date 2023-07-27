import Toybox.Application;
import Toybox.Communications;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Timer;
import Toybox.Attention;
import Toybox.Position;
import MyViews;

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
    var positionManager as PositionManager;
    var delegate as ViewDelegate?;


    hidden var timer as Timer.Timer;

    function initialize() {
        AppBase.initialize();

        fieldManager = new FieldManager();
        session = new Session({ :onStateChange => method(:onSessionState) });
        settings = new Settings({ :onValueChange => method(:onSetting) });
        positionManager = new PositionManager({
            :loggingEnabled => settings.get(SETTING_BREADCRUMPS) as Boolean,
            :minDistance => settings.get(SETTING_BREADCRUMPS_MIN_DISTANCE) as Number,
            :size => settings.get(SETTING_BREADCRUMPS_MAX_COUNT) as Number,
        });

        timer = new Timer.Timer();
        Communications.registerForPhoneAppMessages(method(:onPhone));

        // initial track
        var trackData = settings.get(SETTING_TRACK);
        if(trackData instanceof Array){
            track = new Track(trackData as Array);
            positionManager.setCenter(track.latlonCenter);
        }
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
        timer.start(method(:onTimer), 1000, true);
   	    Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));   
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
        Position.enableLocationEvents(Position.LOCATION_DISABLE, method(:onPosition));
        timer.stop();
    }

    function onSetting(id as SettingId, value as PropertyValueType) as Void {
        if(id == SETTING_BREADCRUMPS){
            positionManager.setLoggingEnabled(value as Boolean);
        }else if(id == SETTING_BREADCRUMPS_MIN_DISTANCE){
            positionManager.setMinDistance(value as Number);
        }else if(id == SETTING_BREADCRUMPS_MAX_COUNT){
            positionManager.setSize(value as Number);
        }else{
            if(id == SETTING_TRACK){
                if(track != null){
                    positionManager.setCenter(track.latlonCenter);
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
    }

    function onTimer() as Void{
        if(delegate != null && delegate has :onTimer){
            (delegate as TimerListener).onTimer();
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

    function onPosition(info as Position.Info) as Void{
        var pos = info.position;

        var xy = null;
        if(pos != null && info.accuracy >= Position.QUALITY_USABLE){
            // Update Breadcrump
            var latlon = pos.toRadians();
            xy = positionManager.addPosition(latlon);
        }else{
            positionManager.addPosition(null);
        }

        if(track != null){
            // Update Track
            track.onPosition(xy, info.accuracy);
        }

        // Inform Datafields
        fieldManager.onPosition(xy, info.heading, info.accuracy);
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