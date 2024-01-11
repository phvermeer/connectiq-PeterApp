import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Application;
import Toybox.Activity;

class ViewDelegate extends WatchUi.InputDelegate {
    hidden var view as View;
    function initialize(view as View) {
        InputDelegate.initialize();
        self.view = view;
    }
}