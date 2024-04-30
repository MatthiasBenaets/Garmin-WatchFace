import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Complications;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.ActivityMonitor;
import Toybox.SensorHistory;
import Toybox.Weather;
import Toybox.Position;
import Toybox.Background;

class WatchView extends WatchUi.WatchFace {
    
    var custom16 = null;
    var custom32 = null;
    var arrowIcon = null;
    var weatherIcon = null;
    var arrowSize = 25;

    function initialize() {
        if (!Application.Properties.getValue("FixedLocation")) {
            var location = Activity.getActivityInfo().currentLocation as Position.Location;
            if (location != null) {
                Application.Properties.setValue("Latitude", location.toDegrees()[0] as Double);
                Application.Properties.setValue("Longitude", location.toDegrees()[1] as Double);
            }
        }
        WatchFace.initialize();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        custom16 = WatchUi.loadResource(Rez.Fonts.custom16);
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
        var system = System.getSystemStats() as System.Stats;
        var clockTime = System.getClockTime() as System.ClockTime;
        var timeShort = Gregorian.info(Time.now(), Time.FORMAT_SHORT) as Gregorian.Info;
        var timeMedium = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM) as Gregorian.Info;
        var activityInfo = ActivityMonitor.getInfo() as ActivityMonitor.Info;
        var locationCoords = [Application.Properties.getValue("Latitude"), Application.Properties.getValue("Longitude")] as [Double, Double];
        var location = new Position.Location({
            :latitude => locationCoords[0],
            :longitude => locationCoords[1],
            :format => :degrees
        }) as Position.Location;
        var weatherInfo = Weather.getCurrentConditions() as Weather.CurrentConditions;
        var sunriseTime;
        var sunsetTime;
        var currentTime = new Time.Moment(Time.now().value()) as Time.Moment;
        if (Application.Storage.getValue("owm") == true && "".equals(Application.Properties.getValue("OpenWeatherMapAPI")) == false) {
            weatherInfo.temperature = Application.Storage.getValue("temperature") as Numeric;
            weatherInfo.feelsLikeTemperature = Application.Storage.getValue("temperatureFeel") as Float;
            weatherInfo.windSpeed = Application.Storage.getValue("windSpeed") as Float;
            weatherInfo.windBearing = Application.Storage.getValue("windBearing") as Number;
            weatherInfo.condition = Application.Storage.getValue("weatherCode") as Number;
            sunriseTime = new Time.Moment(Application.Storage.getValue("sunrise")) as Moment;
            sunsetTime = new Time.Moment(Application.Storage.getValue("sunset")) as Moment;
        } else {
            sunriseTime = Weather.getSunrise(location, currentTime) as Time.Moment;
            sunsetTime = Weather.getSunset(location, currentTime) as Time.Moment;
        }

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
        drawSunEvent(dc, width, currentTime, sunriseTime, sunsetTime);
        drawBattery(dc, width, system);
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
                case 800:
                    drawWeatherIcon(dc, width, 0+shift, 0, icon);
                    break;
                // Cloud
                case 20:
                case 803: case 804:
                    drawWeatherIcon(dc, width, 0, 90, icon);
                    break;
                // Partial Cloud
                case 1: case 2: case 22:
                case 801: case 802:
                    drawWeatherIcon(dc, width, 0+shift, 30, icon);
                    break;
                // Mist
                case 8: case 9: case 29: case 30: case 31: case 33: case 35: case 37: case 38: case 39:
                case 701: case 711: case 721: case 731: case 741: case 751: case 761: case 762: case 771: case 781:
                    drawWeatherIcon(dc, width, 0, 180, icon);
                    break;
                // Hail
                case 10: case 49: case 50:
                case 511:
                    drawWeatherIcon(dc, width, 30, 120, icon);
                    break;
                // Rain
                case 3: case 11: case 13: case 14: case 15: case 24: case 25: case 26: case 31: case 45:
                case 301: case 302: case 311: case 312: case 313: case 314: case 321: case 501: case 502: case 503: case 504: case 521: case 522: case 531:
                    drawWeatherIcon(dc, width, 30, 90, icon);
                    break;
                // Partial Rain
                case 27: case 28:
                case 300: case 310: case 500: case 520:
                    drawWeatherIcon(dc, width, 0+shift, 60, icon);
                    break;
                // Snow
                case 4: case 7: case 16: case 17: case 18: case 19: case 21: case 34: case 43: case 44: case 46: case 47: case 48: case 51:
                case 600: case 601: case 602: case 611: case 612: case 613: case 615: case 616: case 620: case 621: case 622:
                    drawWeatherIcon(dc, width, 0, 150, icon);
                    break;
                // Thunder
                case 6: case 12: case 32: case 41: case 42:
                case 200: case 201: case 202: case 210: case 211: case 212: case 221: case 230: case 231: case 232:
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

    private function drawSunEvent(dc as Dc, width as Float, currentTime as Time.Moment, sunriseTime as Time.Moment, sunsetTime as Time.Moment) {
        var sunriseText = Gregorian.info(sunriseTime, Time.FORMAT_SHORT) as Gregorian.Info;
        var sunsetText = Gregorian.info(sunsetTime, Time.FORMAT_SHORT) as Gregorian.Info;

        sunriseText = Lang.format("$1$$2$", [sunriseText.hour.format("%02d"), sunriseText.min.format("%02d")]) as String;
        sunsetText = Lang.format("$1$$2$", [sunsetText.hour.format("%02d"), sunsetText.min.format("%02d")]) as String;

        if (sunriseTime.lessThan(currentTime) && sunsetTime.greaterThan(currentTime)) {
            drawGauge(dc, width, 10, 4, 1, sunriseTime.value().toFloat(), sunsetTime.value().toFloat(), currentTime.value().toFloat(), [sunriseText, sunsetText, ""]);
        } else if ( sunsetTime.lessThan(currentTime)) {
            drawGauge(dc, width, 10, 4, 1, sunsetTime.value().toFloat(), sunriseTime.value().toFloat() + 86400, currentTime.value().toFloat(), [sunsetText, sunriseText, ""]);
        } else {
            drawGauge(dc, width, 10, 4, 1, sunsetTime.value().toFloat() - 86400, sunriseTime.value().toFloat(), currentTime.value().toFloat(), [sunsetText, sunriseText, ""]);
        }
    }

    private function drawBattery(dc as Dc, width as Float, system as System.Stats) {
        var batteryStatus = Lang.format( "$1$% $2$", [ system.battery.format("%2d"), system.batteryInDays.format("%d") + "D" ] );
        drawGauge(dc, width, 8, 4, 0, 0.0, 100.0, system.battery, ["0", "100", batteryStatus]);
    }

    private function drawGauge(dc as Dc, width as Float, startHour as Number, hourDuration as Number, direction as Number, startValue as Float, endValue as Float, currValue as Float, labels as Array<String>) as Void {
        // Direction
        var arcDirection = null as Graphics.ArcDirection;
        if (direction == 1) {
            arcDirection = Graphics.ARC_CLOCKWISE;
        } else if (direction == 0) {
            arcDirection = Graphics.ARC_COUNTER_CLOCKWISE;
        }

        // Overflow
        if (currValue >= endValue) {
            currValue = endValue;
        } else if (currValue <= startValue) {
            currValue = startValue;
        }

        // Convert values to arc start and end
        var arcStart = 90.0 - startHour * 30.0;
        arcStart = arcStart + 0.001;
        var arcEnd;
        if (direction == 0) {
            arcEnd = arcStart + 30.0 * hourDuration;
        } else {
            arcEnd = arcStart - 30.0 * hourDuration;
        }

        // Compute arc length
        var arcLengthInDegrees = arcEnd - arcStart;
        if (arcLengthInDegrees > 180) {
            if (direction == 1) {
                arcLengthInDegrees = arcLengthInDegrees-90;
            } else {
                arcLengthInDegrees = arcLengthInDegrees;
            }
        }

        // Computing end of arc
        var proportion = (currValue - startValue)/(endValue - startValue);
        if (proportion == 0) {
            proportion = 0.01;
        }
        var arcEndActual = arcStart + proportion * arcLengthInDegrees;
        var arcCenter = (arcStart + arcEnd)/2;

        // Compute arc x, y and radius (same for a circular watch)
        var arcCenterX = width/2;
        var arcCenterY = arcCenterX;
        var arcRadius = arcCenterX;

        // Gauge arc
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var thickness = 1;
        var thicknessSecond = 4;
        for (var i = thickness; i <= thickness+thicknessSecond; i += 1) {
            dc.drawArc(arcCenterX-1, arcCenterY, arcRadius-i, arcDirection, arcStart, arcEndActual+0.001);
        }

        // Gauge value label
        if (labels[2] != ""){
            var outerRadius = width / 2;
            var innerRadius = outerRadius - 9;
            var textInnerRadius = innerRadius - 12;
            var angle = arcCenter / 360 * 2 * Math.PI + Math.PI / 2;
            var x = outerRadius + textInnerRadius * Math.sin(angle);
            var y = outerRadius + textInnerRadius * Math.cos(angle);
            dc.drawText(x, y, custom16, labels[2], Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        // Background arc
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        for (var i = 0; i <= thickness; i += 1) {
            dc.drawArc(arcCenterX-1, arcCenterY, arcRadius-i, arcDirection, arcStart, arcEnd);
        }

        // Gauge stoppers/labels
        drawGaugeStopper(dc, width, [arcStart + 1, arcEnd], [labels[0], labels[1]]);
    }

    private function drawGaugeStopper(dc as Dc, width as Float, hours as Array<Float>, labels as Array<String>) as Void {
        var thickness = 9;
        var outerRadius = width / 2;
        var innerRadius = outerRadius - 10;
        var textInnerRadius = innerRadius - 15;

        for (var i = 0; i < hours.size(); i += 1) {
            var angle = (hours[i]/360.0) * 2 * Math.PI + Math.PI / 2.0;
            var aX = outerRadius + innerRadius * Math.sin(angle);
            var aY = outerRadius + innerRadius * Math.cos(angle);
            var bX = outerRadius + (outerRadius + 10) * Math.sin(angle) + thickness * Math.cos(angle);
            var bY = outerRadius + (outerRadius + 10) * Math.cos(angle) + thickness * Math.sin(angle);
            var cX = outerRadius + (outerRadius + 10) * Math.sin(angle) - thickness * Math.cos(angle);
            var cY = outerRadius + (outerRadius + 10) * Math.cos(angle) - thickness * Math.sin(angle);

            dc.fillPolygon([[aX, aY],[bX, bY],[cX, cY]]);

            var x = outerRadius + textInnerRadius * Math.sin(angle);
            var y = outerRadius + textInnerRadius * Math.cos(angle);
            dc.drawText(x, y, custom16, labels[i], Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

}

class WatchDelegate extends WatchUi.WatchFaceDelegate {
  
  function initialize() {
    WatchFaceDelegate.initialize();
  }

  public function onPress(clickEvent) {
    var coords = clickEvent.getCoordinates();

    if (coords[1] < 90) {
        Complications.exitTo(new Id(Complications.COMPLICATION_TYPE_CURRENT_WEATHER));
    } else if (coords[1] > 215 && coords[0] < 140) {
        Complications.exitTo(new Id(Complications.COMPLICATION_TYPE_BODY_BATTERY));
    } else if (coords[1] > 215 && coords[0] > 140) {
        Complications.exitTo(new Id(Complications.COMPLICATION_TYPE_HEART_RATE));
    } else if (coords[1] > 185 && coords[0] < 140) {
        Complications.exitTo(new Id(Complications.COMPLICATION_TYPE_CALORIES));
    } else if (coords[1] > 185 && coords[0] > 140) {
        Complications.exitTo(new Id(Complications.COMPLICATION_TYPE_STEPS));
    }

    return true;
  }

}