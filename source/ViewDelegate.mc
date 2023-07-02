import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Graphics;
import MyViews;

class ViewDelegate extends MyViews.MyViewDelegate {
    // current dataView index
    hidden var dataViewIndex as Number = 0;

    function initialize(view as MyView) {
        MyViewDelegate.initialize(view);
    }

    function onMenu() as Boolean {
        var menu = new MainMenu();
        WatchUi.pushView(menu, menu.getDelegate(), WatchUi.SLIDE_UP);
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

    function onSwipe(event as SwipeEvent) as Boolean{
        if(mView instanceof DataView){
            // swipe up or down to next dataview
            switch(event.getDirection()){
                case WatchUi.SWIPE_DOWN:
                    break;
                case WatchUi.SWIPE_UP:
                    break;
            }
            return true;
        }
        return false;
    }

    function createDataView(dataViewSettings as Array) as DataView{
        // create layout from settings
        var layout = DataView.getLayoutById(dataViewSettings[0] as LayoutId);
        var fieldIds = dataViewSettings[1] as Array<DataFieldId>;
        
        // get fields for fieldIds
        var count = MyMath.min([layout.size(), fieldIds.size()] as Array<Number>);
        var fields = new Array<MyDataField>[count];
        var fieldManager = getApp().fieldManager;
        for(var i=0; i<count; i++){
            fields[i] = fieldManager.getField(fieldIds[i]);
        }

        // create the dataView
        var view = new DataView({
            :layout => layout,
            :fields => fields
        });
        return view;
    }
}