import Toybox.Lang;
import Toybox.System;
import Toybox.Math;

enum LayoutIdentifier {
	LAYOUT_FIRST = 0x1,
	LAYOUT_LAST = 0x7,
	LAYOUT_ONE_FIELD = 0x1,
	LAYOUT_TWO_FIELDS = 0x2,
	LAYOUT_THREE_FIELDS = 0x3,
	LAYOUT_FOUR_FIELDS = 0x4,
	LAYOUT_SIX_FIELDS = 0x5,
	LAYOUT_CUSTOM1 = 0x6,
	LAYOUT_CUSTOM2 = 0x7,
}

typedef Layout as Array<{
    :locX as Number,
    :locY as Number,
    :width as Number,
    :height as Number
}>;

function getLayout(id as LayoutIdentifier) as Layout{
    var deviceSettings = System.getDeviceSettings();
    var width = deviceSettings.screenWidth;
    var height = deviceSettings.screenHeight;
	var margin = Math.ceil(width / 150.0f);
	
    var data = [];
    if(id == LAYOUT_ONE_FIELD){
        data.add({
            :locX => 0,
            :locY => 0,
            :width => width,
            :height => height
        });
    }else if(id == LAYOUT_TWO_FIELDS){
        var h = (height-margin) / 2;
        data.add({
            :locX => 0,
            :locY => 0,
            :width => width,
            :height => h
        });
        var y = h + margin;
        data.add({
            :locX => 0,
            :locY => y,
            :width => width,
            :height => h
        });
    }else if(id == LAYOUT_THREE_FIELDS){
        var h = (height-2*margin) / 3;
        data.add({
            :locX => 0,
            :locY => 0,
            :width => width,
            :height => h
        });
        var y = h + margin;
        data.add({
            :locX => 0,
            :locY => y,
            :width => width,
            :height => h
        });
        y += h + margin;
        data.add({
            :locX => 0,
            :locY => y,
            :width => width,
            :height => h
        });
    }else if(id == LAYOUT_FOUR_FIELDS){
        var h = (height-2*margin) / 3.0;
        var w = (width-margin) / 2.0;
        data.add({
            :locX => 0,
            :locY => 0,
            :width => width,
            :height => h
        });
        var y = h + margin;
        data.add({
            :locX => 0,
            :locY => y,
            :width => w,
            :height => h
        });
        var x = w + margin;
        data.add({
            :locX => x,
            :locY => y,
            :width => w,
            :height => h
        });
        y += h + margin;
        data.add({
            :locX => 0,
            :locY => y,
            :width => width,
            :height => h
        });
    }else if(id == LAYOUT_SIX_FIELDS){
        var h = (height-2*margin) / 4.0;
        var w = (width-margin) / 2.0;
        data.add({
            :locX => 0,
            :locY => 0,
            :width => width,
            :height => h
        });
        var y = h + margin;
        var x = w + margin;
        data.add({
            :locX => 0,
            :locY => y,
            :width => w,
            :height => h
        });
        data.add({
            :locX => x,
            :locY => y,
            :width => w,
            :height => h
        });
        y += h + margin;
        data.add({
            :locX => 0,
            :locY => y,
            :width => w,
            :height => h
        });
        data.add({
            :locX => x,
            :locY => y,
            :width => w,
            :height => h
        });
        y += h + margin;
        data.add({
            :locX => 0,
            :locY => y,
            :width => width,
            :height => h
        });
    }else if(id == LAYOUT_CUSTOM1){
        var h = 0.25 * height - 0.5 * margin;
        data.add({
            :locX => 0,
            :locY => 0,
            :width => width,
            :height => h
        });
        var y = h + margin;
        h = 0.5 * height - margin;
        var w = 0.5 * width - 0.5 * margin;
        data.add({
            :locX => 0,
            :locY => y,
            :width => w,
            :height => h
        });
        var x = w + margin;
        var h1 = 0.5 * h - 0.5 * margin;
        w = width - w - margin;
        data.add({
            :locX => x,
            :locY => y,
            :width => w,
            :height => h1
        });
        y += h1 + margin;
        h1 = h - h1 - margin;
        data.add({
            :locX => x,
            :locY => y,
            :width => w,
            :height => h1
        });
        y += h1 + margin;
        h = height - y;
        data.add({
            :locX => 0,
            :locY => y,
            :width => width,
            :height => h
        });
    }else if(id == LAYOUT_CUSTOM2){
        // Two transparent fields on top and a big field (without margins)
        var x = 0;
        var y = 0;
        var h = 0.2f * height;
        var w = 0.5f * width;
        data.add({
            :locX => x,
            :locY => y,
            :width => w,
            :height => h
        });
        x = w;
        data.add({
            :locX => x,
            :locY => y,
            :width => w,
            :height => h
        });
        x = 0;
        y = h;
        w = width;
        h = height - h;
        data.add({
            :locX => x,
            :locY => y,
            :width => w,
            :height => h
        });
    }else{
        var w2 = 0.5 * width;
        var h2 = 0.5 * height;
        data.add({
            :locX => w2,
            :locY => h2,
            :width => w2,
            :height => h2
        });
    }
    return data as Layout;            
}