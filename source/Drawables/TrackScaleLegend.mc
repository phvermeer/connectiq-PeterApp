import Toybox.Lang;
using Toybox.WatchUi;
import Toybox.Graphics;
import MyBarrel.Math2;

class TrackScaleLegend extends WatchUi.Drawable{
	hidden var zoomFactor as Float = 1f; // [pixels/m]
	hidden var indicatorWidth as Numeric = 2;
	hidden var text as String = "";
	hidden var font as FontDefinition = Graphics.FONT_XTINY;
	hidden var updatedSize as Boolean = false;
	hidden var margin as Lang.Number = 2;

	function initialize(parameters as { 
		:zoomFactor as Lang.Float,
		:font as Graphics.FontDefinition,
		:locX as Lang.Number, 
		:locY as Lang.Number, 
	}){
		Drawable.initialize(parameters);
		if(parameters.hasKey(:zoomFactor)){
			zoomFactor = (parameters.get(:zoomFactor) as Float);
		}
	}

	function updateSize(dc as Graphics.Dc) as Void{
		updatedSize = true;

		// determine the maximum size by font size and step size 
		var dimensions = dc.getTextDimensions("100km", font);
		margin = Math.ceil(dimensions[1] * 0.25f).toNumber(); 
		var h = margin + dimensions[1];
		var w = 2.5 * dimensions[0]; // The biggest step between 1, 2, 5, 10 is  2½ (2→5)
		setSize(w, h);
		
		// update the marker size
		setZoomFactor(self.zoomFactor);
	}

	function draw(dc as Graphics.Dc){
		if(!updatedSize){
			throw new MyException("first call updateSize() before calling draw()");	
		}
		
		var w2 = self.width/2.0f;
		var h2 = self.height/2.0f;

		dc.drawText(locX + w2, locY, font, text, Graphics.TEXT_JUSTIFY_CENTER);

		var w = Math.round(self.indicatorWidth).toNumber();
		var dx = Math.round(w2-w/2).toNumber();

		dc.setPenWidth(1);
		dc.drawLine(locX + dx,      locY + h2,     locX + dx,      locY + height - margin); // left
		dc.drawLine(locX + dx + w, 	locY + h2,     locX + dx + w,  locY + height - margin); // right
		dc.drawLine(locX + dx,      locY + height - margin, locX + dx + w,  locY + height - margin); // bottom
	}

	protected function setText(text as Lang.String) as Void{
		self.text = text;
	}

	function setZoomFactor(zoomFactor as Lang.Float) as Void{
		self.zoomFactor = zoomFactor;
		if(width > 0){
			// zoomLevel [pixel/m]
			// Determine max meters that fits in the area
			// => meters = pixels / zoomFactor = maxWidth / zoomFactor
			var metersMax = width / zoomFactor;
	
			// round to simple number
			var log = Math.floor(Math.log(metersMax, 10));
			var meters = Math.pow(10, log);
			var size = meters / metersMax;
	
			if(size * 5 <= 1){
				size *= 5;
				meters *= 5;
			}else if(size * 2 <= 1){
				size *= 2;
				meters *= 2;
			}
	
			self.indicatorWidth = width * size;
	
			if(log < 0){
				// 1 signicant number
				var n = Math2.abs(log.toNumber());
				setText(meters.format(Lang.format("%.$1$f", [n]))+"m");
			}else if(log < 3){
				setText(meters.format("%.0f") + "m");
			}else{
				setText((meters/1000).format("%.0f") + "km");
			}
		}
	}
}