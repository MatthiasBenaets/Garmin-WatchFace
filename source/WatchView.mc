import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Time.Gregorian;
import Toybox.ActivityMonitor;
import Toybox.SensorHistory;

class WatchView extends WatchUi.WatchFace {

    function initialize() {
        WatchFace.initialize();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
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

        drawTime(clockTime);
        drawDate(timeShort, timeMedium);
        drawSteps(activityInfo);
        drawCalories(activityInfo);
        drawHeartRate();
        drawBodyBattery();
        
        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);
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

    private function drawBodyBattery() as Void{
        var value = "-" as String;
        if ((Toybox has :SensorHistory) && (SensorHistory has :getBodyBatteryHistory)) {
            var sample = Toybox.SensorHistory.getBodyBatteryHistory({}).next() as SensorHistory.SensorSample or Null;
            if (sample != null) {
                value = sample.data.format("%d") as String;
            }
        }
        drawLabel("BodyLabel").setText(value);
    }

    private function drawLabel(name as String) as Toybox.WatchUi.Text {
        return (View.findDrawableById(name) as Toybox.WatchUi.Text);
    }
}