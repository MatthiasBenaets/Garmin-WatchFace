import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class WatchSettingsMenu extends WatchUi.Menu2 {

    function initialize() {
        Menu2.initialize(null);
        Menu2.setTitle("Settings");
		Menu2.addItem(new WatchUi.ToggleMenuItem("Military Time", null, "MT", getProp("UseMilitaryFormat"), null));
    }

}

class WatchSettingsMenuDelegate extends WatchUi.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }

  	function onSelect(item) {
  		var id=item.getId();
        if(id.equals("MT")) {
            Application.Properties.setValue("UseMilitaryFormat", !getProp("UseMilitaryFormat"));
  		}
  	}
  	
  	function onBack() {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        return;
    }
}

function getProp(prop as String) as String or Boolean {
    return Application.Properties.getValue(prop);
}