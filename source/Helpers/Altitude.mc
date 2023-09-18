import Toybox.Lang;
import Toybox.Position;
import Toybox.Communications;
import Toybox.Activity;
import Toybox.Math;
import Toybox.Timer;

module Altitude{
    function validPosition(position as Location?) as Boolean{
        if(position != null){
            var latlon = position.toDegrees();
            if(
                latlon[0] >= -90d && latlon[0] <= 90d &&
                latlon[1] >= -90d && latlon[1] <= 90d)
            {
                return true;
            }else{
                Toybox.System.println(Lang.format("latlon = $1$, $2$", [latlon]));
            }
        }
        return false;
    }

    class Calculator{
        const G = 9.80665f; // [m/s²]
        const M	= 0.0289644f; // [g/mol]
        const R = 8.31432f; // [(N·m)/(mol·°K)]
        const Lb = -0.0065f; // [°K/m]
        const Tkelvin = 273.15f;


        var t0 as Float;  // temperature [°C] at sealevel
        var p0 as Float;  // pressure [Pa] at sealevel

        function initialize(sealevelPressure as Float, sealevelTemperature as Float){
            p0 = sealevelPressure;
            t0 = sealevelTemperature;
        }

        function getAltitude(pressure as Float) as Float{
            var t0_kelvin = t0 + Tkelvin;
            var h = ((t0_kelvin/Lb)*(Math.pow(pressure/p0, (-R*Lb)/(G*M))-1)).toFloat();
            return h;
        }
    }

    class Calibration extends Calculator{

        enum State{
            STATE_IDLE = 0,
            STATE_BUSY = 1,
            STATE_READY = 2,
            STATE_ERROR = 3,
        }

        var gpsState as State = STATE_IDLE;
        var gpsAccuracy as Position.Quality = Position.QUALITY_NOT_AVAILABLE;
        var onlineState as State = STATE_IDLE;

        var onGpsStateChange as Null|Method(state as State) as Void;
        var onGpsAccuracyChange as Null|Method(accuracy as Position.Quality) as Void;
        var onOnlineStateChange as Null|Method(state as State) as Void;

        var gpsData as Null|Position.Info;
        var onlineData as Null|{
            :altitude as Float, // altitude
            :pressure as Float, // pressure
            :sealevelPressure as Float, // pressure at sealevel
            :sealevelTemperature as Float, // temperature at sealevel
        };

        hidden var retryTimer as Timer.Timer = new Timer.Timer();

        function initialize(sealevelPressure as Float, sealevelTemperature as Float){
            Calculator.initialize(sealevelPressure, sealevelTemperature);
        }

        function start() as Void{
            setGpsState(STATE_IDLE);
            setOnlineState(STATE_IDLE);

            gpsData = null;
            onlineData = null;

            requestGpsData();
        }

        function stop() as Void{
            // abort pending operations
            Position.enableLocationEvents(
                {
                    :acquisitionType => Position.LOCATION_DISABLE,
                }, method(:onGpsData)
            );
            Communications.cancelAllRequests();
            retryTimer.stop();
        }

        hidden function setGpsState(state as State) as Void{
            if(gpsState != state){
                gpsState = state;

                if(state == STATE_IDLE){
                    // reset gps data
                    gpsData = null;
                    setGpsAccuracy(Position.QUALITY_NOT_AVAILABLE);
                }

                if(onGpsStateChange != null){
                    onGpsStateChange.invoke(state);
                }
                // additional actions
                switch(state){
                    case STATE_READY:
                        // start new gps action?
                        if(gpsData == null || gpsData.accuracy < Position.QUALITY_GOOD){
                            // retry after 1 second to get more acurate position
                            retryTimer.start(method(:requestGpsData), 1000, false);
                        }
                        break;
                }
            }
        }
        hidden function setGpsAccuracy(accuracy as Position.Quality) as Void{
            if(accuracy != gpsAccuracy){
                gpsAccuracy = accuracy;
                if(onGpsAccuracyChange != null){
                    onGpsAccuracyChange.invoke(accuracy);
                }
            }
        }
        hidden function setOnlineState(state as State) as Void{
            if(onlineState != state){
                onlineState = state;

                if(state == STATE_IDLE){
                    // reset online data
                    onlineData = null;
                }

                if(onOnlineStateChange != null){
                    onOnlineStateChange.invoke(state);
                }
            }
        }

        function calibrate(p as Float,  h as Float?) as { :t0 as Float, :p0 as Float } {
            h = (h == null) ? getAltitude(p) : h;

            // redefine the p0 to compensate P deviations
            var t0_kelvin = t0 + Tkelvin;
            p0 = (p / Math.pow(1 + (Lb/t0_kelvin) * h, (-G*M)/(R*Lb))).toFloat();

            return {
                :t0 => t0,
                :p0 => p0,
            };
        }

        function requestGpsData() as Void{
            setGpsState(STATE_BUSY);
            Position.enableLocationEvents(
                {
                    :acquisitionType => Position.LOCATION_ONE_SHOT,
                },
                method(:onGpsData)
            );
        }
        function onGpsData(info as Position.Info) as Void{
            // check if new position is valid
            if(!validPosition(info.position)){
                info.accuracy = Position.QUALITY_NOT_AVAILABLE;
            }

            // keep most accurate data
            if(info.accuracy > gpsAccuracy){
                gpsData = info;
                setGpsAccuracy(info.accuracy);

                // update online data
                requestOnlineData(info.position as Location);
            }
            setGpsState(STATE_READY);
        }

        function requestOnlineData(position as Location) as Void{
            Communications.cancelAllRequests();

            var latlon = position.toDegrees();
            var url = "https://api.open-meteo.com/v1/forecast";                         // set the url
            var params = {                                              // set the parameters
                    "latitude" => latlon[0],
                    "longitude" => latlon[1],
                    "hourly" => "temperature_2m,pressure_msl,surface_pressure",
                    "current_weather" => true,
                    "forecast_days" => 1,
            };

            var options = {                                             // set the options
                :method => Communications.HTTP_REQUEST_METHOD_GET,      // set HTTP method
                :headers => {                                           // set headers
                    "Content-Type" => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED,
                },
                                                                        
                :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON // set response type
            };

            // Make the Communications.makeWebRequest() call
            Communications.makeWebRequest(url, params, options, method(:onOnlineData));
        }
        function onOnlineData(responseCode as Number, data as Dictionary|String|Null) as Void{
            if (responseCode == 200) {
                // successfull response -> decode data
                if(data instanceof Dictionary){
                    var h = data.get("elevation") as Float?;
                    var hourly = data.get("hourly");
                    if(hourly instanceof Dictionary){
                        // var time_hourly = hourly.get("time");
                        var t_hourly = hourly.get("temperature_2m");
                        var p0_hourly = hourly.get("pressure_msl");
                        var p_hourly = hourly.get("surface_pressure");

                        if(h instanceof Float && t_hourly instanceof Array && p0_hourly instanceof Array && p_hourly instanceof Array){

                            // use average values for now
                            var t = Math.mean(t_hourly as Array<Numeric>).toFloat(); // temperature 2m above surface
                            var p = Math.mean(p_hourly as Array<Numeric>).toFloat(); // pressure at surface
                            var p0 = Math.mean(p0_hourly as Array<Numeric>).toFloat(); // pressure at sealevel

                            // calculate temperature at sealevel
                            t0 = t + Lb * -(h+2);

                            onlineData = {
                                :altitude => h,
                                :pressure => p,
                                :sealevelPressure => p0,
                                :sealevelTemperature => t0,
                            };

                            setOnlineState(STATE_READY);
                            return;
                        }
                    }
                }
            }
            // internet call failed -> use old values
            setOnlineState(STATE_ERROR);
        }

        function basicCalibration() as Boolean{
            var info = Activity.getActivityInfo();
            if(info != null){
                var h = info.altitude;
                var p = info.ambientPressure;
                if(h != null && p != null){
                    calibrate(p, h);
                    return true;
                }
            }
            return false;
        }

        hidden function stateToString(state as State) as String{
            switch(state){
                case STATE_IDLE:            return "-";
                case STATE_BUSY:            return "...";
                case STATE_READY:           return "OK";
                case STATE_ERROR:           return "ERR";
                default:                    return "?";
            }
        }
        function getStateText() as String{

            return Lang.format("GPS $1$, WEB $2$", [gpsState, onlineState]);
        }

        function getAltitude2() as Float{
            // get the most accurate altitude for current state
            // 1 - altitude from web
            if(onlineData != null){
                return onlineData.get(:altitude) as Float;
            }else{
                // 2 - gps altitude
                if(gpsAccuracy >= Position.QUALITY_USABLE && gpsData != null && gpsData.altitude != null){
                    return gpsData.altitude as Float;
                }else{
                    // 3 - activity altitude (not calibrated)
                    var info = Activity.getActivityInfo();
                    if(info != null && info.altitude != null){
                        return info.altitude as Float;
                    }else{
                        return 0f;
                    }
                }
            }
        }
    }
}