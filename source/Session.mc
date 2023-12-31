using Toybox.ActivityRecording;
import Toybox.Lang;
import Toybox.WatchUi;
using Toybox.Timer;
using Toybox.Activity;
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
	public var currentLapInfo as LapInfo?;
	public var previousLapInfo as LapInfo?;

	hidden var mState as SessionState = SESSION_STATE_IDLE;
	hidden var mSession as ActivityRecording.Session? = null;
	hidden var mOptions as { 
		:sport as ActivityRecording.Sport, 
		:name as Lang.String
	};
	hidden var mStateDelayCounter as Number = 0;

	// Auto lap variables
	hidden var mAutoLap as Boolean = true;
	hidden var mAutoLapDistance as Float? = null;
	hidden var mAutoPause as Boolean = true;
	hidden var mLastLapDistance as Float = 0f;

	// Listeners
	hidden var mOnStateChange as Null|Method(state as SessionState) as Void;

	function initialize(options as { 
		:sport as Activity.Sport|ActivityRecording.Sport, 
		:name as Lang.String,
		:onStateChange as Method(state as SessionState) as Void,
		:autoLap as Float|Null,
		:autoPause as Boolean,
	}){
		mOnStateChange = options.get(:onStateChange);

		// options for session creation
		mOptions = {};
		if(options.hasKey(:name)){
			mOptions.put(:name, options.get(:name));
		}
		if(options.hasKey(:sport)){
			mOptions.put(:sport, options.get(:sport) as Object);
		}
		if(options.hasKey(:autoLap)){
			setAutoLap(options.get(:autoLap));
		}
		if(options.hasKey(:autoPause)){
			setAutoPause(options.get(:autoPause) as Boolean);
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

	hidden function setState(state as SessionState) as Void{
		if(mState != state){
			mState = state;
			if(mOnStateChange != null){
				mOnStateChange.invoke(state);
			}
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

	public function setAutoLap(distance as Float or Null) as Void{
		mAutoLapDistance = distance;
		mAutoLap = (distance != null);
	}

	public function setAutoPause(enabled as Boolean) as Void{
		if(mAutoPause != enabled){
			mAutoPause = enabled;
			if(!mAutoPause && mState == SESSION_STATE_PAUSED){
				setPaused(false);
			}			
		}
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

//***** Protected functions **************

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

	function onActivityInfo(info as Activity.Info) as Void{
		if(currentLapInfo != null){
			currentLapInfo.update(info);
		}
		if(mAutoPause){
			checkPaused(info);
		}
		if(mAutoLap){
			checkAutoLap(info);
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
		if((mSession != null) && (mAutoLapDistance != null)  && (mAutoLapDistance as Float > 0) && (info.elapsedDistance != null)){
			var distance = info.elapsedDistance as Float;
			var autoLapDistance = mAutoLapDistance as Float;
			var nextDistance = mLastLapDistance + autoLapDistance;
			if(nextDistance <= distance){
				mSession.addLap();
				
				var lapDistance = (distance - self.mLastLapDistance);
				var lapCount = Math.floor(lapDistance / autoLapDistance).toNumber();
				mLastLapDistance += lapCount * autoLapDistance;
			}
		}
	}
}
