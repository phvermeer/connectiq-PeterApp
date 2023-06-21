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
}