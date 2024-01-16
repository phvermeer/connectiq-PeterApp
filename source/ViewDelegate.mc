import Toybox.Lang;
import Toybox.WatchUi;
import MyBarrel.Views;

class ViewDelegate extends Views.MyViewDelegate {

    function initialize() {
        MyViewDelegate.initialize();
    }

    function onMenu() as Boolean {
        var delegate = new MyMenuDelegate();
        var settings = $.getApp().settings;
        var menu = new MainMenu(delegate, settings);
        WatchUi.pushView(menu, menu.getDelegate(), WatchUi.SLIDE_UP);
        return true;
    }
}