using Toybox.ActivityRecording;
import Toybox.Lang;
import Toybox.WatchUi;
using Toybox.Timer;
import Toybox.Activity;
using Toybox.Time;
import MyTools;

enum SessionState {
	SESSION_STATE_IDLE,
	SESSION_STATE_BUSY,
	SESSION_STATE_PAUSED,
	SESSION_STATE_STOPPED,
}

class LapInfo{
	public var speed as Float?; // [m/s]
	public var time as Number = 0; // [ms]
	public var distance as Float = 0f; // [m]
	public var ascent as Number = 0; // [m]
	public var descent as Number = 0; // [m]

	hidden var startDistance as Float; // [m]
	hidden var startTime as Number; // [ms]
	hidden var startAscent as Number; // [m]
	hidden var startDescent as Number; // [m]

	function initialize(info as Activity.Info){
		startDistance = (info.elapsedDistance != null) ? info.elapsedDistance as Float : 0.0f;
		startTime = (info.timerTime != null) ? info.timerTime as Number : 0;
		startAscent = (info.totalAscent != null) ? info.totalAscent as Number : 0;
		startDescent = (info.totalDescent != null) ? info.totalDescent as Number : 0;
	}

	function update(info as Activity.Info) as Void{
		time = (info.timerTime != null) ? (info.timerTime as Number) - startTime : 0;
		distance = (info.elapsedDistance != null) ? (info.elapsedDistance as Float) - startDistance : 0.0f;
		speed = (time as Number > 0) ? distance / time : null;
		ascent = (info.totalAscent != null) ? (info.totalAscent as Number) - startAscent : 0;
		descent = (info.totalDescent != null) ? (info.totalDescent as Number) - startDescent : 0;
	}
}

class Session{
    typedef IListener as interface{
        function onSessionState(state as SessionState) as Void;
    };

	public var currentLapInfo as LapInfo?;
	public var previousLapInfo as LapInfo?;

    hidden var mListeners as Array<WeakReference> = [] as Array<WeakReference>;
	hidden var mState as SessionState = SESSION_STATE_IDLE;
	hidden var mSession as ActivityRecording.Session? = null;
	hidden var mOptions as { 
		:sport as Activity.Sport, 
		:name as Lang.String
	};
	hidden var mStateDelayCounter as Number = 0;

	// Auto lap variables
	hidden var mAutoLapEnabled as Boolean = true;
	hidden var mAutoLapDistance as Float = 1000f;
	hidden var mAutoPause as Boolean = true;
	hidden var mLastLapDistance as Float = 0f;

	function initialize(options as { 
		:sport as Activity.Sport|ActivityRecording.Sport, 
		:onStateChange as Method(state as SessionState) as Void,
		:autoLapEnabled as Boolean,
		:autoLapDistance as Float,
		:autoPause as Boolean,
	}){
		// default values
		mOptions = {
			:sport => Activity.SPORT_WALKING,
			:name => WatchUi.loadResource(Rez.Strings.walking) as String,
		};

		// options for session creation
		if(options.hasKey(:sport)){
			setSport(options.get(:sport) as Sport);
		}
		if(options.hasKey(:autoLap)){
			setAutoLapEnabled(options.get(:autoLapEnabled) as Boolean);
		}
		if(options.hasKey(:autoLap)){
			setAutoLapDistance(options.get(:autoLapDistance) as Float);
		}
		if(options.hasKey(:autoPause)){
			setAutoPause(options.get(:autoPause) as Boolean);
		}
	}

	hidden function setState(state as SessionState) as Void{
		if(mState != state){
			mState = state;
			notifyListeners(state);
		}
	}
	public function getState() as SessionState{
		return mState;
	}
	public function start() as Void{
		switch(mState){
			case SESSION_STATE_IDLE:
			case SESSION_STATE_STOPPED:
				if(mSession == null){
					mSession = ActivityRecording.createSession(mOptions);
					mSession.setTimerEventListener(method(:onEvents));
				}
				if(mSession != null){
					mSession.start();
				}
				setState(SESSION_STATE_BUSY);
				break;
		}
	}
	public function stop() as Void{
		switch(mState){
			case SESSION_STATE_BUSY:
			case SESSION_STATE_PAUSED:{
				if(mState == SESSION_STATE_BUSY){
					if(mSession != null){
						mSession.stop();
					}
				}
				setState(SESSION_STATE_STOPPED);
				break;
			}
		}
	}
	public function save() as Void{
		stop();
		if(mSession != null){
			mSession.save();
			mSession = null;
		}
		setState(SESSION_STATE_IDLE);
	}
	public function discard() as Void{
		stop();
		if(mSession != null){
			(mSession as ActivityRecording.Session).discard();
			mSession = null;
		}
		setState(SESSION_STATE_IDLE);
	}

	static public function getIcon(sport as Activity.Sport) as BitmapResource{
		switch(sport){
		case Activity.SPORT_WALKING:
			return WatchUi.loadResource(Rez.Drawables.walking) as WatchUi.BitmapResource;
		case Activity.SPORT_RUNNING:
			return WatchUi.loadResource(Rez.Drawables.running) as WatchUi.BitmapResource;
		case Activity.SPORT_CYCLING:
			return WatchUi.loadResource(Rez.Drawables.cycling) as WatchUi.BitmapResource;
		case Activity.SPORT_HIKING:
			return WatchUi.loadResource(Rez.Drawables.hiking) as WatchUi.BitmapResource;
		default:
			return WatchUi.loadResource(Rez.Drawables.unknown) as WatchUi.BitmapResource;
		}
	}

	// **** Settings *****
	function onSetting(id as SettingId, value as Settings.ValueType) as Void{
        if(id == SETTING_AUTOPAUSE){
            setAutoPause(value as Boolean);
        }else if(id == SETTING_AUTOLAP){
            setAutoLapEnabled(value as Boolean);
		}else if(id == SETTING_AUTOLAP_DISTANCE){
			setAutoLapDistance(value as Float);
		}else if(id == SETTING_SPORT){
			setSport(value as Sport);
		}
	}

	public function setSport(sport as Activity.Sport) as Void{
		if(mSession != null){
			throw new MyTools.MyException("Session options can only be set if the session is not started before");
		}
		var name =
			(sport == Activity.SPORT_WALKING) ? WatchUi.loadResource(Rez.Strings.walking) :
			(sport == Activity.SPORT_RUNNING) ? WatchUi.loadResource(Rez.Strings.running) :
			(sport == Activity.SPORT_HIKING) ? WatchUi.loadResource(Rez.Strings.hiking) :
			(sport == Activity.SPORT_CYCLING) ? WatchUi.loadResource(Rez.Strings.cycling) :
			WatchUi.loadResource(Rez.Strings.unknownActivity);
		
		mOptions.put(:name, name);
		mOptions.put(:sport, sport as Number);
	}
	public function getSport() as Activity.Sport{
		var sport = mOptions.get(:sport) as Activity.Sport?;
		var settings = $.getApp().settings;
		if(sport == null){
			sport = settings.get(SETTING_SPORT) as Activity.Sport;  
		}
		return sport;
	}
	public function setAutoLapEnabled(enabled as Boolean) as Void{
		mAutoLapEnabled = enabled;
	}
	public function setAutoLapDistance(distance as Float) as Void{
		mAutoLapDistance = distance;
	}

	public function setAutoPause(enabled as Boolean) as Void{
		if(mAutoPause != enabled){
			mAutoPause = enabled;
			if(!mAutoPause && mState == SESSION_STATE_PAUSED){
				setPaused(false);
			}			
		}
	}

	//***** Events and State functions ******

	protected function setPaused(paused as Boolean) as Void{
		// will be initiated by a low speed (auto stop)
		if(mSession != null){
			var s = mSession;
			if(paused){
				s.stop();
				setState(SESSION_STATE_PAUSED);
			}else{
				s.start();
				setState(SESSION_STATE_BUSY);
			}
		}
	}

	function onEvents(eventType as ActivityRecording.TimerEventType, eventData as Dictionary) as Void{
		var info = Activity.getActivityInfo() as Activity.Info;
		switch(eventType){
			case ActivityRecording.TIMER_EVENT_START:{
				if(currentLapInfo == null){
					currentLapInfo = new LapInfo(info);
				}
				break;
			}
			case ActivityRecording.TIMER_EVENT_LAP:{
				if(currentLapInfo != null){
					currentLapInfo.update(info);
					previousLapInfo = currentLapInfo;
				}
				currentLapInfo = new LapInfo(info);
				break;
			}
		}
	}

	function onData(data as Data) as Void{
		var info = data.activityInfo;
		if(info != null){
			if(currentLapInfo != null){
				currentLapInfo.update(info);
			}
			if(mAutoPause){
				checkPaused(info);
			}
			if(mAutoLapEnabled){
				checkAutoLap(info);
			}
		}
	}

	function checkPaused(info as Activity.Info) as Void{
		// increase delay counter if the pause state is invalid for currentspeed
		var speed = info.currentSpeed != null ? info.currentSpeed as Float : 0;
		if(
			((mState == SESSION_STATE_PAUSED) && (speed > 0)) ||
			((mState == SESSION_STATE_BUSY) && (speed == 0))
		){
			mStateDelayCounter++;
		}else{
			mStateDelayCounter=0;
		}

		// 3 measurements in a row indicates that the pause state should be activated or deactivated
		if(mStateDelayCounter > 2){
			mStateDelayCounter = 0;
			
			if(mState == SESSION_STATE_PAUSED){
				setPaused(false);
			}else{
				setPaused(true);
			}
		}
	}

	function checkAutoLap(info as Activity.Info) as Void{
		if((mSession != null) && mAutoLapEnabled && (mAutoLapDistance as Number > 0) && (info.elapsedDistance != null)){
			var distance = info.elapsedDistance as Float;
			var nextDistance = mLastLapDistance + mAutoLapDistance;
			if(nextDistance <= distance){
				mSession.addLap();
				
				var lapDistance = (distance - self.mLastLapDistance);
				var lapCount = Math.floor(lapDistance / mAutoLapDistance).toNumber();
				mLastLapDistance += lapCount * mAutoLapDistance;
			}
		}
	}

    // Listeners
    function addListener(listener as Object) as Void{
        if((listener as IListener) has :onSessionState){
            mListeners.add(listener.weak());
        }
    }
    function removeListener(listener as Object) as Void{
        // loop through array to look for listener
        for(var i=mListeners.size()-1; i>=0; i--){
            var ref = mListeners[i];
            var l = ref.get();
            if(l == null || l.equals(listener)){
                mListeners.remove(ref);
            }
        }
    }
    hidden function notifyListeners(state as SessionState) as Void{
        for(var i=mListeners.size()-1; i>=0; i--){
            var ref = mListeners[i];
            var l = ref.get();
            if(l != null){
                (l as IListener).onSessionState(state);
            }else{
                mListeners.remove(ref);
            }
        }
    }
}
