import Toybox.Lang;

class ListMenu extends MyMenu{
    function initialize(delegate as MyMenuDelegate, title as String, itemNames as Array<String>){
		MyMenu.initialize(delegate,
		{
		  :title => title
		});

		// add menu items
		for(var id=0; id<itemNames.size(); id++){
			addItem(
				new WatchUi.MenuItem(
					itemNames[id] as String,
					null,
					id,
					{}
				)
			);
		}
    }
}