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
    var positionManager as Data;
    var delegate as ViewDelegate?;
    var altitudeCalculator as Altitude.Calculator;
    var started as Boolean = false;
    var history as MyHistoryIterator = new MyHistoryIterator();


    hidden var timer as Timer.Timer;

    function initialize() {
        AppBase.initialize();

        fieldManager = new FieldManager();
        settings = new Settings({ :onValueChange => method(:onSetting) });

        var autoLap = (settings.get(SETTING_AUTOLAP) as Boolean)
            ? settings.get(SETTING_AUTOLAP_DISTANCE) as Float 
            : null;
        session = new Session({
            :onStateChange => method(:onSessionState),
            :autoLap => autoLap,
            :autoPause => settings.get(SETTING_AUTOPAUSE) as Boolean,
        });
        positionManager = new Data({
            :loggingEnabled => settings.get(SETTING_BREADCRUMPS) as Boolean,
            :minDistance => settings.get(SETTING_BREADCRUMPS_MIN_DISTANCE) as Number,
            :size => settings.get(SETTING_BREADCRUMPS_MAX_COUNT) as Number,
        });
        positionManager.addListener(self);

        var p0 = settings.get(SETTING_ALTITUDE_P0) as Float;
        var t0 = settings.get(SETTING_ALTITUDE_T0) as Float;
        altitudeCalculator = new Altitude.Calculator(p0, t0);

        timer = new Timer.Timer();
        Communications.registerForPhoneAppMessages(method(:onPhone));

        // initial track
        var trackData = settings.get(SETTING_TRACK);
        if(trackData instanceof Array){
            track = new Track(trackData as Array);
            positionManager.setCenter(track.latlonCenter);
            positionManager.addListener(track as Object);
        }
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
        timer.start(method(:onTimer), 1000, true);
        started = true;
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
        stopEvents();
        timer.stop();
        started = false;
    }

    hidden function startEvents() as Void{
        positionManager.start();
    }

    hidden function stopEvents() as Void{
        positionManager.stop();
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
            positionManager.setLoggingEnabled(value as Boolean);
        }else if(id == SETTING_BREADCRUMPS_MIN_DISTANCE){
            positionManager.setMinDistance(value as Number);
        }else if(id == SETTING_BREADCRUMPS_MAX_COUNT){
            positionManager.setSize(value as Number);
        }else{
            if(id == SETTING_TRACK){
                history.clear();
                if(track != null){
                    positionManager.setCenter(track.latlonCenter);
                    positionManager.addListener(track as Object);
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
	            stopEvents();
                break;
            case SESSION_STATE_BUSY:
                startEvents();
                // start events
                break;
        }
    }

    function onTimer() as Void{
        // update time based info
        var stats = System.getSystemStats();
        if(stats != null){
            fieldManager.onSystemInfo(stats);
        }

        // trigger Datafields.onActivityInfo
        var activityInfo = Activity.getActivityInfo();
        if(activityInfo != null){
            // modify altitude
            var pressure = activityInfo.ambientPressure;
            if(pressure != null){
                activityInfo.altitude = altitudeCalculator.calculateAltitude(pressure);
            }

            session.onActivityInfo(activityInfo);
            fieldManager.onActivityInfo(activityInfo);
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

    function onPosition(xy as Data.XyPoint?, info as Position.Info) as Void{
        // update elapsed distance history
        if(xy != null && info.accuracy >= Position.QUALITY_USABLE){
            // Update elapsed track distance history
            if(track != null){
                var distance = 
                    (info.accuracy < Position.QUALITY_USABLE)
                        ? null
                        : track.isOnTrack()
                            ? (track as Track).distanceElapsed
                            : null;
                history.add(new MySample(distance));
            }
        }
    }
/*
    function onPosition(info as Position.Info) as Void{
        var pos = info.position;
        var activityInfo = Activity.getActivityInfo();

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

        // Update history
        var distance = 
            (info.accuracy < Position.QUALITY_USABLE)
                ? null
                : (track != null)
                    ? track.isOnTrack()
                        ? (track as Track).distanceElapsed
                        : null
                    : (activityInfo != null)
                        ? activityInfo.elapsedDistance
                        : null;

        // override for testing purposes
        distance = (activityInfo != null) ? activityInfo.elapsedDistance : null;
            
        history.add(new MySample(distance));        

        // Inform Datafields
        fieldManager.onPosition(xy, info);
        if(activityInfo != null){
            // modify altitude
            var pressure = activityInfo.ambientPressure;
            if(pressure != null){
                activityInfo.altitude = altitudeCalculator.calculateAltitude(pressure);
            }

            session.onActivityInfo(activityInfo);
            fieldManager.onActivityInfo(activityInfo);
        }
    }
*/
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