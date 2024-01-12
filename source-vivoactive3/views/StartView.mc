import Toybox.Activity;
import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
import MyBarrel.Views;

class StartView extends MyView {
    var text as Text;

    function initialize(delegate as MyViewDelegate) {
        MyView.initialize(delegate);
        text = new WatchUi.Text({
            :text => "test",
            :justification => Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER,
            :color => Graphics.COLOR_BLACK,
        });
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        
        text.locX = w / 2;
        text.locY = 0.6 * h;
    }

    function onUpdate(dc as Dc) as Void{
        var stat = System.getSystemStats();
        var perc = 100 * stat.usedMemory / stat.totalMemory;
        text.setText(perc.toString());

        // draw text "Start"
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_WHITE);
        dc.clear();
        text.draw(dc);
    }
}
