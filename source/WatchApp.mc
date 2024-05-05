import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Background;
import Toybox.Position;
import Toybox.Time;

(:background)
class WatchApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
        if (!Application.Properties.getValue("FixedLocation")) {
            var location = Activity.getActivityInfo().currentLocation as Position.Location;
            if (location != null) {
                if (!(location.toDegrees()[0].format("%.5f").equals("0.00000") && location.toDegrees()[1].format("%.5f").equals("0.00000"))) {
                    Application.Properties.setValue("Latitude", location.toDegrees()[0] as Double);
                    Application.Properties.setValue("Longitude", location.toDegrees()[1] as Double);
                }
            }
        }
        if (Toybox.System has :ServiceDelegate) {
            Background.registerForTemporalEvent(new Time.Duration(Application.Properties.getValue("RefreshRateOWM")*60));
        }
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    // Return the initial view of your application here
    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [ new WatchView(), new WatchDelegate() ];
    }

    // New app settings have been received so trigger a UI update
    function onSettingsChanged() as Void {
        WatchUi.requestUpdate();
    }

    function getSettingsView() {
        return [new WatchSettingsMenu(),new WatchSettingsMenuDelegate()];
    }

    function getServiceDelegate() {
        return [new WatchServiceDelegate()];
    }

    function onBackgroundData(data) {
        var weather = data as Dictionary?;
        var condition = weather["weather"] as Array<Dictionary>;
        var temperature = weather["main"] as Dictionary;
        var wind = weather["wind"] as Dictionary;
        var sun = weather["sys"] as Dictionary;
        if (data != null) {
            Application.Storage.setValue("owm", true as Boolean);
            Application.Storage.setValue("weatherCode", condition[0]["id"] as Number);
            Application.Storage.setValue("temperature", temperature["temp"] as Numeric);
            Application.Storage.setValue("temperatureFeel", temperature["feels_like"] as Number);
            Application.Storage.setValue("windSpeed", wind["speed"] as Float);
            Application.Storage.setValue("windBearing", wind["deg"] as Number);
            Application.Storage.setValue("sunset", sun["sunset"] as Number);
            Application.Storage.setValue("sunrise", sun["sunrise"] as Number);
        } else {
            Application.Storage.setValue("owm", false as Boolean);
        }
    }

}

function getApp() as WatchApp {
    return Application.getApp() as WatchApp;
}