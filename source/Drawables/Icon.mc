import Toybox.Lang;
import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Activity;

class Icon extends WatchUi.Drawable{
  var bitmap as BitmapType?;

  public function initialize(options as {
    :identifier as String,
    :locX as Number, 
    :locY as Number,
    :width as Number, 
    :height as Number,
  }){
    Drawable.initialize(options);
  }

  function setBitmap(bitmap as BitmapType) as Void{
    self.bitmap = bitmap;
  }

  function draw(dc as Dc) as Void{
    // draw a circle as background
    dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
    var x = locX + width/2;
    var y = locY + height/2;
    var radius = (width>height) ? height/2 : width/2;
    dc.fillCircle(x, y, radius);

    if(self.bitmap != null){
      var bitmap = self.bitmap as BitmapType;
      // draw centered in the area of the drawable
      var h = bitmap.getHeight();
      var w = bitmap.getWidth();
      x -= w/2;
      y -= h/2;
      dc.drawBitmap(x, y, bitmap);
    }
  }
}