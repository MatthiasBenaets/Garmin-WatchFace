import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Time.Gregorian;
import Toybox.ActivityMonitor;
import Toybox.SensorHistory;
import Toybox.Weather;

class WatchView extends WatchUi.WatchFace {

    var arrowIcon = null;
    var arrowSize = 25;

    function initialize() {
        WatchFace.initialize();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        arrowIcon = WatchUi.loadResource(Rez.Drawables.Arrow) as Graphics.BitmapType;
        setLayout(Rez.Layouts.WatchFace(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        var width = dc.getWidth().toFloat() as Float;
        var clockTime = System.getClockTime() as System.ClockTime;
        var timeShort = Gregorian.info(Time.now(), Time.FORMAT_SHORT) as Gregorian.Info;
        var timeMedium = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM) as Gregorian.Info;
        var activityInfo = ActivityMonitor.getInfo() as ActivityMonitor.Info;
        var weatherInfo = Weather.getCurrentConditions() as Weather.CurrentConditions;

        drawTime(clockTime);
        drawDate(timeShort, timeMedium);
        drawSteps(activityInfo);
        drawCalories(activityInfo);
        drawHeartRate();
        drawBodyBattery();
        drawTemperature(weatherInfo);
        drawWind(weatherInfo);
        
        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);

        // Draw bitmap after onUpdate
        drawWindArrow(dc, width, weatherInfo, arrowIcon);
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() as Void {
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
    }

    private function drawTime(clockTime as System.ClockTime) as Void {
        var timeFormat = "$1$:$2$";
        var hours = clockTime.hour;
        if (!System.getDeviceSettings().is24Hour) {
            if (hours > 12) {
                hours = hours - 12;
            }
        } else {
            if (Application.Properties.getValue("UseMilitaryFormat")) {
                timeFormat = "$1$$2$";
                hours = hours.format("%02d");
            }
        }
        var timeString = Lang.format(timeFormat, [hours, clockTime.min.format("%02d")]);

        var view = View.findDrawableById("TimeLabel") as Text;
        view.setText(timeString);
    }

    private function drawDate(timeShort as Gregorian.Info, timeMedium as Gregorian.Info) as Void {
        drawLabel("DateLabel").setText(Lang.format("$1$ $2$ $3$ $4$", [timeMedium.day_of_week.toUpper(), timeShort.day, timeMedium.month.toUpper(), timeShort.year % 100]));        
    }

    private function drawSteps(activityInfo as ActivityMonitor.Info) as Void {
        drawLabel("StepsLabel").setText(activityInfo.steps.format("%d"));
    }

    private function drawCalories(activityInfo as ActivityMonitor.Info) as Void {
        drawLabel("CaloriesLabel").setText(activityInfo.calories.format("%d"));
    }
    
    private function drawHeartRate() as Void {
        var value = "-" as String;
        if (ActivityMonitor has :getHeartRateHistory) {
            var sample = Activity.getActivityInfo().currentHeartRate as Number or Null;
            if (sample != null) {
                value = sample.format("%d") as String;
            } else {
                sample = ActivityMonitor.getHeartRateHistory(1, true).next() as ActivityMonitor.HeartRateSample;
                if ((sample != null) && (sample.heartRate != ActivityMonitor.INVALID_HR_SAMPLE)) {
                    value = sample.heartRate.format("%d") as String;
                }
            }
        }
        drawLabel("HeartRateLabel").setText(value);
    }

    private function drawBodyBattery() as Void {
        var value = "-" as String;
        if ((Toybox has :SensorHistory) && (SensorHistory has :getBodyBatteryHistory)) {
            var sample = Toybox.SensorHistory.getBodyBatteryHistory({}).next() as SensorHistory.SensorSample or Null;
            if (sample != null) {
                value = sample.data.format("%d") as String;
            }
        }
        drawLabel("BodyLabel").setText(value);
    }

    private function drawTemperature(weatherInfo as Weather.CurrentConditions) as Void {
        var value = "-" as String;
        if ((Toybox has :Weather) && (Weather has :CurrentConditions)) {
            var condition = weatherInfo as Weather.CurrentConditions;
            if (condition != null) {
                drawLabel("TempLabel").setText(condition.temperature.format("%d") + "°");
                drawLabel("TempFeelLabel").setText(condition.feelsLikeTemperature.format("%d") + "°"); 
            }
        } else {
            drawLabel("TempLabel").setText(value + "°");
            drawLabel("TempFeelLabel").setText(value + "°");
        }
    }

    private function drawWind(weatherInfo as Weather.CurrentConditions) as Void {
        var value = "-" as String;
        if ((Toybox has :Weather) && (Weather has :CurrentConditions)) {
            var condition = weatherInfo as Weather.CurrentConditions;
            if (condition != null) {
                drawCardinalDirection(condition);
                drawLabel("WindSpeedLabel").setText((condition.windSpeed * 3.6).format("%d"));
            }
        } else {
            drawLabel("WindDirLabel").setText(value);
            drawLabel("WindSpeedLabel").setText(value);
        }
    }

    private function drawCardinalDirection(condition as Weather.CurrentConditions) as Void {
        var direction = condition.windBearing as Number;
        var windDirection = "-";
        if ( direction >= 335 && direction <= 360 || direction >= 0 && direction < 25 ) {
            windDirection = "N";
        } else if ( direction >= 25 && direction < 65 ) {
            windDirection = "NE";
        } else if ( direction >= 65 && direction < 115 ) {
            windDirection = "E";
        } else if ( direction >= 115 && direction < 155 ) {
            windDirection = "SE";
        } else if ( direction >= 155 && direction < 205 ) {
            windDirection = "S";
        } else if ( direction >= 205 && direction < 245 ) {
            windDirection = "SW";
        } else if ( direction >= 245 && direction < 295 ) {
            windDirection = "W";
        } else if ( direction >= 295 && direction < 335 ) {
            windDirection = "NW";
        } else {
            windDirection = "?";
        }
        drawLabel("WindDirLabel").setText(windDirection);
    }

    private function drawLabel(name as String) as Toybox.WatchUi.Text {
        return (View.findDrawableById(name) as Toybox.WatchUi.Text);
    }

    private function drawWindArrow(dc as Dc, width as Float, weatherInfo as Weather.CurrentConditions, arrowIcon as Graphics.BitmapType) as Void {
        if ((Toybox has :Weather) && (Weather has :CurrentConditions)) {
            var transform = new Graphics.AffineTransform();
            var direction = weatherInfo.windBearing as Number;
            var rotation = 0.0174305556 * direction;
            transform.rotate(rotation);
            transform.translate(-arrowSize/2, -arrowSize/2);
            dc.drawBitmap2(0.59*width, 0.23*width, arrowIcon, { :transform => transform });
        }
    }
}