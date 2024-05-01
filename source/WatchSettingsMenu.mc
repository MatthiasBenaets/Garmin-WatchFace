import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Background;

// Switch WatchUi menu instead of push to auto update menu values (easiest solution)
class WatchSettingsMenu extends WatchUi.Menu2 {

    function initialize() {
        Menu2.initialize(null);
        Menu2.setTitle("Settings");
		Menu2.addItem(new WatchUi.ToggleMenuItem("Military Time", null, "MT", getProp("UseMilitaryFormat"), null));
		Menu2.addItem(new WatchUi.MenuItem("Latitude", getProp("Latitude").toString(), "LAT", null));
		Menu2.addItem(new WatchUi.MenuItem("Longitude", getProp("Longitude").toString(), "LON", null));
		Menu2.addItem(new WatchUi.ToggleMenuItem("Fixed Location", null, "FL", getProp("FixedLocation"), null));
		Menu2.addItem(new WatchUi.MenuItem("OWM API Key", getProp("OpenWeatherMapAPI"), "OWM", null));
		Menu2.addItem(new WatchUi.MenuItem("OWM Refresh Rate", getProp("RefreshRateOWM").toString() + " min.", "RR", null));
    }

}

class WatchSettingsMenuDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

  	function onSelect(item) {
        var picker;
        var delegate;
  		var id=item.getId();
        if (id.equals("MT")) {
            Application.Properties.setValue("UseMilitaryFormat", !getProp("UseMilitaryFormat"));
  		} else if (id.equals("LAT")) {
            picker = new StringPicker("Latitude", "0123456789.-");
            delegate = new StringPickerDelegate(picker, "Latitude");
            WatchUi.switchToView(picker, delegate, WatchUi.SLIDE_IMMEDIATE); 
  		} else if (id.equals("LON")) {
            picker = new StringPicker("Longitude", "0123456789.-");
            delegate = new StringPickerDelegate(picker, "Longitude");
            WatchUi.switchToView(picker, delegate, WatchUi.SLIDE_IMMEDIATE); 
        } else if (id.equals("FL")) {
            Application.Properties.setValue("FixedLocation", !getProp("FixedLocation"));
  		} else if (id.equals("OWM")) {
            picker = new StringPicker("OpenWeatherMapAPI", "0123456789abcdef");
            delegate = new StringPickerDelegate(picker, "OpenWeatherMapAPI");
            WatchUi.switchToView(picker, delegate, WatchUi.SLIDE_IMMEDIATE); 
  		} else if (id.equals("RR")) {
            picker = new NumberPicker("Refresh Rate", "RefreshRateOWM", [5, 10, 15, 30, 60, 120, 240, 720, 1440]);
            delegate = new NumberPickerDelegate("RefreshRateOWM");
            WatchUi.switchToView(picker, delegate, WatchUi.SLIDE_IMMEDIATE); 
        }
  	}
  	
  	function onBack() {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        return;
    }

}

class StringPicker extends WatchUi.Picker {

    var updatableTitle as String;
    var title as Text;
    var factory as CharacterFactory;

    function initialize(property as String, characterSet as String) {
        factory = new CharacterFactory(characterSet, true) as CharacterFactory;
        updatableTitle = "" as String;

        var propValue =  Application.Properties.getValue(property).toString();
        var pickerOptions = {
            :pattern => [factory]
        };

        if (propValue instanceof String && !"".equals(propValue)) {
            updatableTitle = propValue;
            var startValue = propValue.substring(propValue.length() - 1, propValue.length());
            if (startValue != null) {
                var index = factory.getIndex(startValue);
                if (index != null) {
                    pickerOptions[:defaults] = [index];
                }
            }
        }

        title = new WatchUi.Text({
            :text => updatableTitle,
            :font => Graphics.FONT_TINY,
            :color => Graphics.COLOR_WHITE,
            :justification => Graphics.TEXT_JUSTIFY_RIGHT,
            :locX => WatchUi.LAYOUT_HALIGN_CENTER,
            :locX => System.getDeviceSettings().screenWidth/2+5,
            :locY => WatchUi.LAYOUT_VALIGN_BOTTOM,
        });

        pickerOptions[:title] = title;
        Picker.initialize(pickerOptions);
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        Picker.onUpdate(dc);
    }

    function addCharacter(character as String) as Void {
        updatableTitle += character as String;
        title.setText(updatableTitle) as String;
    }

    function removeCharacter() as Void {
        updatableTitle = updatableTitle.substring(0, updatableTitle.length() - 1) as String;
        title.setText(updatableTitle) as String;
    }

    function getTitle() as String {
        return updatableTitle;
    }

    function getTitleLength() as Number {
        return updatableTitle.length();
    }

    function isDone(value as String or Number) as Boolean {
        return factory.isDone(value);
    }

}

class StringPickerDelegate extends WatchUi.PickerDelegate {

    var picker as StringPicker;
    var property as String;

    function initialize(stringPicker as StringPicker, prop as String) {
        PickerDelegate.initialize();
        picker = stringPicker as StringPicker;
        property = prop as String;
    }

    function onCancel() as Boolean {
        if (picker.getTitleLength() == 0) {
            WatchUi.switchToView(new WatchSettingsMenu(), new WatchSettingsMenuDelegate(), WatchUi.SLIDE_IMMEDIATE);
        } else {
            picker.removeCharacter();
        }
        return true;
    }

    function onAccept(values as Array) as Boolean {
        var chosenValue = values[0] as String;
        if (!picker.isDone(chosenValue)) {
            picker.addCharacter(chosenValue);
        } else {
            if (picker.getTitle().length() == 0) {
                if (property.equals("Latitude") || property.equals("Longitude")) {
                    Application.Properties.setValue(property, 0 as Double);
                } else if (property.equals("OpenWeatherMapAPI")) {
                    Application.Properties.setValue(property, "");
                } else if (property.equals("RefreshRateOWM")) {
                    Application.Properties.setValue(property, 5 as Number);
                }
            } else {
                if (property.equals("Latitude")) {
                    if (picker.getTitle().toDouble() instanceof Double && picker.getTitle().toDouble() >= -90 && picker.getTitle().toDouble() <= 90) {
                        Application.Properties.setValue(property, picker.getTitle().toDouble() as Double);
                    } else {
                        Application.Properties.setValue(property, 0 as Double);
                    }
                } else if (property.equals("Longitude")) {
                    if (picker.getTitle().toDouble() instanceof Double && picker.getTitle().toDouble() >= -180 && picker.getTitle().toDouble() <= 180) {
                        Application.Properties.setValue(property, picker.getTitle().toDouble() as Double);
                    } else {
                        Application.Properties.setValue(property, 0 as Double);
                    }
                } else if (property.equals("OpenWeatherMapAPI")) {
                    Application.Properties.setValue(property, picker.getTitle());
                }
            }
            WatchUi.switchToView(new WatchSettingsMenu(), new WatchSettingsMenuDelegate(), WatchUi.SLIDE_IMMEDIATE);
        }
        return true;
    }

}

class CharacterFactory extends WatchUi.PickerFactory {

    var characterSet as String;
    var addSave as Boolean;
    const DONE = -1;

    function initialize(characters as String, ok as Boolean) {
        PickerFactory.initialize();
        characterSet = characters;
        addSave = ok;
    }

    function getIndex(value as String) as Number? {
        return characterSet.find(value);
    }

    function getSize() as Number {
        return characterSet.length() + (addSave ? 1 : 0);
    }

    function getValue(index as Number) as Object? {
        if (index == characterSet.length()) {
            return DONE;
        }
        return characterSet.substring(index, index + 1);
    }

    function getDrawable(index as Number, selected as Boolean) as Drawable? {
        if (index == characterSet.length()) {
            return new WatchUi.Text({
                :text => "Save",
                :color => Graphics.COLOR_WHITE,
                :font => Graphics.FONT_LARGE,
                :locX => WatchUi.LAYOUT_HALIGN_CENTER,
                :locY => WatchUi.LAYOUT_VALIGN_CENTER
            });
        }
        return new WatchUi.Text({
            :text => getValue(index) as String,
            :color => Graphics.COLOR_WHITE,
            :font => Graphics.FONT_LARGE,
            :locX => WatchUi.LAYOUT_HALIGN_CENTER,
            :locY => WatchUi.LAYOUT_VALIGN_CENTER
        });
    }

    function isDone(value as String or Number) as Boolean {
        return addSave and (value == DONE);
    }

}

class NumberPicker extends WatchUi.Picker {

    function initialize(label as String, property as String, optionValues as Array<Number>) {
        var options = optionValues as Array<Number>;
        var factory = new NumberFactory(options) as NumberFactory;

        var title = new WatchUi.Text({
            :text => label,
            :color => Graphics.COLOR_WHITE,
            :locX => WatchUi.LAYOUT_HALIGN_CENTER,
            :locY => WatchUi.LAYOUT_VALIGN_BOTTOM
        });

        Picker.initialize({
            :title => title,
            :pattern => [factory],
            :defaults => [0]
        });
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        Picker.onUpdate(dc);
    }

}

class NumberPickerDelegate extends WatchUi.PickerDelegate {

    var property as String;

    function initialize(prop as String) {
        PickerDelegate.initialize();
        property = prop as String;
    }

    function onCancel() as Boolean {
        WatchUi.switchToView(new WatchSettingsMenu(), new WatchSettingsMenuDelegate(), WatchUi.SLIDE_IMMEDIATE);
        return true;
    }

    function onAccept(values) {
        var selectedValue = values[0] as Number;
        Application.Properties.setValue(property, selectedValue);
        if (property.equals("RefreshRateOWM")) {
            Background.registerForTemporalEvent(new Time.Duration(selectedValue*60));
        }
        WatchUi.switchToView(new WatchSettingsMenu(), new WatchSettingsMenuDelegate(), WatchUi.SLIDE_IMMEDIATE);
        return true;
    }

}

class NumberFactory extends WatchUi.PickerFactory {

    var options as Array<Number>;

    function initialize(optionValues as Array<Number>) {
        PickerFactory.initialize();
        options = optionValues as Array<Number>;
    }

    function getIndex(value as Number) as Number {
        var index = options.indexOf(value) as Number;
        if (index == -1) {
            return 0;
        }
        return index;
    }

    public function getSize() as Number {
        return options.size();
    }

    function getValue(index as Number) as Object? {
        return options[index % options.size()];
    }

    function getDrawable(index as Number, selected as Boolean) as Drawable? {
        var adjustedIndex = index % options.size() as Number;
        var text = options[adjustedIndex].toString() as String;

        return new WatchUi.Text({
            :text => text,
            :color => Graphics.COLOR_WHITE,
            :font => Graphics.FONT_LARGE,
            :locX => WatchUi.LAYOUT_HALIGN_CENTER,
            :locY => WatchUi.LAYOUT_VALIGN_CENTER,
            :width => System.getDeviceSettings().screenWidth - 1,
        });
    }

}

function getProp(prop as String) as String or Boolean {
    return Application.Properties.getValue(prop);
}