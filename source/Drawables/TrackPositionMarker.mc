using Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Lang;
using Toybox.System;
import MyBarrel.Math2;

class TrackPositionMarker extends WatchUi.Drawable{
	hidden var heading as Float?;
	hidden var radius as Float;
	hidden var penWidth as Number;
	hidden var colorFill as ColorType = Graphics.COLOR_PINK;
	hidden var colorEdge as ColorType = Graphics.COLOR_WHITE;

	function initialize(options as {
		:heading as Float or Null,
		:locX as Number,
		:locY as Number,
		:darkMode as Boolean,
	}){
		Drawable.initialize(options);

		if(options.hasKey(:darkMode)){
			setDarkMode(options.get(:darkMode) as Boolean);
		}
		
		if(options.hasKey(:heading)){
			setHeading(options.get(:heading) as Float?);
		}
		
		// determine the marker size and thickness
		var deviceSettings = System.getDeviceSettings();
		var screenSize = Math2.max([deviceSettings.screenWidth, deviceSettings.screenHeight] as Array<Number>).toFloat();
		radius = screenSize / 10f;
		penWidth = Math.ceil(screenSize / 200f).toNumber();
	}

	function setDarkMode(darkMode as Boolean) as Void{
		colorFill = darkMode ? Graphics.COLOR_DK_BLUE : Graphics.COLOR_BLUE;
		colorEdge = darkMode ? Graphics.COLOR_BLUE : Graphics.COLOR_DK_BLUE;
	}
	
	function draw(dc as Graphics.Dc) as Void{
		dc.setPenWidth(penWidth);
		if(heading == null){
			// Draw no direction marker
			dc.setColor(colorFill, Graphics.COLOR_TRANSPARENT);
			dc.fillCircle(locX, locY, radius*0.5);
			dc.setColor(colorEdge, Graphics.COLOR_TRANSPARENT);
			dc.drawCircle(locX, locY, radius*0.5);
		}else{
			var h = heading as Float;
			// heading:
			// 0.0 * pi => North
			// 0.5 * pi => West
			// 1.0 * pi => South
			// 1.5 * pi => East
			//
			//          .*.  p0
			//         .   .    
			//        .  x  .
			//       . . * . .    
			//      *    p2   *  
			//     p1         p3

			//draw arrow in heading direction
			var r0 = radius; 		// p1
			var r2 = radius * 0.5; 	// p2
			var r13 = radius; 		// p1 & p3
			var angle = 0.5;

			var x0 = locX + r0 * Math.sin(h);
			var y0 = locY - r0 * Math.cos(h);
			var x1 = locX - r13 * Math.sin(h + angle);
			var y1 = locY + r13 * Math.cos(h + angle);
			var x2 = locX - r2 * Math.sin(h);
			var y2 = locY + r2 * Math.cos(h);
			var x3 = locX - r13 * Math.sin(h - angle);
			var y3 = locY + r13 * Math.cos(h - angle);

			// Draw solid marker
			dc.setColor(colorFill, Graphics.COLOR_TRANSPARENT);
			dc.fillPolygon([
				[x0, y0] as Array<Numeric>,
				[x1, y1] as Array<Numeric>,
				[x2, y2] as Array<Numeric>,
				[x3, y3] as Array<Numeric>
			] as Array< Array<Numeric> >);

			// Draw the edge
			dc.setPenWidth(penWidth);
			dc.setColor(colorEdge, Graphics.COLOR_TRANSPARENT);
			dc.drawLine(x0, y0, x1, y1);
			dc.drawLine(x1, y1, x2, y2);
			dc.drawLine(x2, y2, x3, y3);
			dc.drawLine(x3, y3, x0, y0);
		}
	}
	
	function setHeading(heading as Float?) as Void{
		self.heading = heading;
	}
}