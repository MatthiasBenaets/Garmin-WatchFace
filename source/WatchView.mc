import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.ActivityMonitor;
import Toybox.SensorHistory;
import Toybox.Weather;
import Toybox.Position;

class WatchView extends WatchUi.WatchFace {

    var custom32 = null;
    var arrowIcon = null;
    var weatherIcon = null;
    var arrowSize = 25;

    function initialize() {
        var location = Activity.getActivityInfo().currentLocation as Position.Location;
        if (location != null) {
            Application.Storage.setValue("location", location.toDegrees() as [Double, Double]);
        }
        WatchFace.initialize();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        custom32 = WatchUi.loadResource(Rez.Fonts.custom32);
        weatherIcon = WatchUi.loadResource(Rez.Drawables.Weather) as Graphics.BitmapType;
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
        var location = new Position.Location({
            :latitude => 50.929391,
            :longitude => 5.337577,
            :format => :degrees
        }) as Position.Location;
        var locationData = Application.Storage.getValue("location") as [Double, Double];
        if (locationData != null) {
            location = new Position.Location({
                :latitude => locationData[0],
                :longitude => locationData[1],
                :format => :degrees
            }) as Position.Location;
        }
        var currentTime = new Time.Moment(Time.now().value()) as Time.Moment;
        var sunriseTime = Weather.getSunrise(location, currentTime) as Time.Moment;
        var sunsetTime = Weather.getSunset(location, currentTime) as Time.Moment;

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
        drawWeather(dc, width, weatherInfo, currentTime, sunriseTime, sunsetTime, weatherIcon);
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

    private function drawCardinalDirection(weatherInfo as Weather.CurrentConditions) as Void {
        var direction = weatherInfo.windBearing as Number;
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

    private function drawWeather(dc as Dc, width as Float, weatherInfo as Weather.CurrentConditions, currentTime as Time.Moment, sunriseTime as Time.Moment, sunsetTime as Time.Moment, icon as Graphics.BitmapType) {
        if ((Toybox has :Weather) && (Weather has :CurrentConditions)) {
            var currentCondition = weatherInfo.condition as Number;
            var shift = 30;
            if (sunriseTime.lessThan(currentTime) && sunsetTime.greaterThan(currentTime)) {
                shift = 0;
            }
            switch (currentCondition) {
                // Sun & Moon
                case 0: case 23: case 40: case 52: case 53:
                    drawWeatherIcon(dc, width, 0+shift, 0, icon);
                    break;
                // Cloud
                case 20:
                    drawWeatherIcon(dc, width, 0, 90, icon);
                    break;
                // Partial Cloud
                case 1: case 2: case 22:
                    drawWeatherIcon(dc, width, 0+shift, 30, icon);
                    break;
                // Mist
                case 8: case 9: case 29: case 30: case 31: case 33: case 35: case 37: case 38: case 39:
                    drawWeatherIcon(dc, width, 0, 180, icon);
                    break;
                // Hail
                case 10: case 49: case 50:
                    drawWeatherIcon(dc, width, 30, 120, icon);
                    break;
                // Rain
                case 3: case 11: case 13: case 14: case 15: case 24: case 25: case 26: case 31: case 45:
                    drawWeatherIcon(dc, width, 30, 90, icon);
                    break;
                // Partial Rain
                case 27: case 28:
                    drawWeatherIcon(dc, width, 0+shift, 60, icon);
                    break;
                // Snow
                case 4: case 7: case 16: case 17: case 18: case 19: case 21: case 34: case 43: case 44: case 46: case 47: case 48: case 51:
                    drawWeatherIcon(dc, width, 0, 150, icon);
                    break;
                // Thunder
                case 6: case 12: case 32: case 41: case 42:
                    drawWeatherIcon(dc, width, 0, 120, icon);
                    break;
                // Wind
                case 5: case 36:
                    drawWeatherIcon(dc, width, 30, 180, icon);
                    break;
                // Default
                default:
                    drawWeatherIcon(dc, width, 0, 0, icon);
                    break;
            }
        } else {
            dc.drawText(0.29*width, 0.18*width, custom32, "?", 1);
        }
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

    private function drawWeatherIcon(dc as Dc, width as Float, x as Number, y as Number, icon as BitmapResource) {
        var transform = new Graphics.AffineTransform();
        transform.translate(-x.toFloat(), -y.toFloat());
        dc.drawBitmap2(0.23*width, 0.18*width, icon, {
            :bitmapX => x,
            :bitmapY => y,
            :bitmapWidth => 30,
            :bitmapHeight => 30,
            :transform => transform,
        });
    }
}