import Toybox.System;
import Toybox.Lang;
import Toybox.Background;
import Toybox.Communications;

(:background)
class WatchServiceDelegate extends Toybox.System.ServiceDelegate {

    (:background_method)
    function initialize() {
        System.ServiceDelegate.initialize();
    }

    (:background_method)
    function onTemporalEvent() {
        var location = Application.Storage.getValue("location") as [Double, Double];

        var url = "https://api.openweathermap.org/data/2.5/weather" as String;
        var params = {
            "lat" => location[0].toString(),
            "lon" => location[1].toString(),
            "units" => "metric",
            "appid" => "8bec16072fb2b0ab50af39ac1bed4cfc"
        } as Dictionary;
        var options = {
           :method => Communications.HTTP_REQUEST_METHOD_GET,
           :headers => {
                "Content-Type" => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED
            },
           :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        } as Dictionary;
        var responseCallback = method(:onReceive) as Method;

        Communications.makeWebRequest(url as String, params as Dictionary, options as Dictionary, responseCallback as Method);
    }

    function onReceive(responseCode as Number, data as Dictionary) {
        if (responseCode == 200) {
            Background.exit(data);
        } else {
            Background.exit(null);
        }
    }

}