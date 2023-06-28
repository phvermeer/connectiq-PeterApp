import Toybox.Lang;
import Toybox.WatchUi;
import MyViews;

class ViewDelegate extends MyViews.MyViewDelegate {

    function initialize(view as MyView) {
        MyViewDelegate.initialize(view);
    }

    function onMenu() as Boolean {
        WatchUi.pushView(new Rez.Menus.MainMenu(), new MenuDelegate(), WatchUi.SLIDE_UP);
        return true;
    }

    function onSessionState(state as SessionState) as Void{
        if(mView has :onSessionState){
            (mView as SessionStateListener).onSessionState(state);
        }
    }

    function onTimer() as Void{
        if(mView has :onTimer){
            (mView as TimerListener).onTimer();
        }
    }
}