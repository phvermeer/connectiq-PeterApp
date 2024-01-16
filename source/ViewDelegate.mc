import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Application;
import Toybox.Activity;
import MyBarrel.Views;

class ViewDelegate extends Views.MyViewDelegate {
    // current dataView index
    hidden var dataViewIndex as Number = 0;

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