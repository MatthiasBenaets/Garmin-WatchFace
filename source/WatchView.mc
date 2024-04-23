import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Time.Gregorian;

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

        drawTime(clockTime);
        drawDate(timeShort, timeMedium);
        
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

    private function drawLabel(name as String) as Toybox.WatchUi.Text {
        return (View.findDrawableById(name) as Toybox.WatchUi.Text);
    }
}