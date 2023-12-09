import Toybox.Lang;
import Toybox.Position;
import Toybox.Communications;
import Toybox.Activity;
import Toybox.Math;
import Toybox.Timer;

module Altitude{
    function validatePositionInfo(positionInfo as Position.Info) as Void{
        var position = positionInfo.position;
        if(position != null){
            var latlon = position.toDegrees();
            if(
                latlon[0] < -90d || latlon[0] > 90d ||
                latlon[1] < -90d || latlon[1] > 90d)
            {
                positionInfo.accuracy = Position.QUALITY_NOT_AVAILABLE;
                positionInfo.position = null;
            }
        }
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

        function calculateAltitude(pressure as Float) as Float{
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

        enum WebQuality{
            WEB_QUALITY_NOT_AVAILABLE = 0,
            WEB_QUALITY_GOOD = 16,
        }
        typedef Quality as WebQuality|Position.Quality|Number;

        typedef IListener as interface{
            function onAltitude(altitude as Float, accuracy as Quality) as Void;
            function test() as Void;
        };

        hidden var gpsState as State = STATE_IDLE;
        hidden var onlineState as State = STATE_IDLE;
        hidden var listener as WeakReference|Null;

        var altitude as Float?;
        var accuracy as Quality = Position.QUALITY_NOT_AVAILABLE|WEB_QUALITY_NOT_AVAILABLE;
        hidden var gpsData as Null|Position.Info;

        hidden var retryTimer as Timer.Timer = new Timer.Timer();

        function initialize(options as {
                :p0 as Float, 
                :t0 as Float,
                :listener as Object,
            })
        {
            var p0 = options.hasKey(:p0) ? options.get(:p0) as Float : 10000f;
            var t0 = options.hasKey(:t0) ? options.get(:t0) as Float : 15f;
            if(options.hasKey(:listener)){
                var l = options.get(:listener);
                if(l != null && (l as IListener) has :onAltitude){
                    self.listener = l.weak();
                }
            }
            Calculator.initialize(p0, t0);
        }

        function start() as Void{
            setGpsState(STATE_IDLE);
            setOnlineState(STATE_IDLE);
            requestGpsData();
        }

        function stop() as Void{
            // abort pending operations
            if(gpsState == STATE_BUSY){
                Position.enableLocationEvents({ :acquisitionType => Position.LOCATION_DISABLE }, method(:onGpsData));
            }

            if(onlineState == STATE_BUSY){
                Communications.cancelAllRequests();
            }
            retryTimer.stop();
        }

        hidden function setGpsState(state as State) as Void{
            if(gpsState != state){
                gpsState = state;

                // additional actions
                if(state == STATE_READY){
                    // start retrieving web data
                    if(gpsData != null && gpsData.accuracy >= Position.QUALITY_POOR){
                        requestOnlineData(gpsData.position as Location);
                    }

                    // start new gps action?
                    if(gpsData == null || gpsData.accuracy < Position.QUALITY_GOOD){
                        // retry after 1 second to get more acurate position
                        retryTimer.start(method(:requestGpsData), 1000, false);
                    }
                }
            }
        }
        hidden function setOnlineState(state as State) as Void{
            if(onlineState != state){
                onlineState = state;
            }
        }

        function calibrate(p as Float,  h as Float) as Void {
            // redefine the p0 to compensate P deviations
            var t0_kelvin = t0 + Tkelvin;
            p0 = (p / Math.pow(1 + (Lb/t0_kelvin) * h, (-G*M)/(R*Lb))).toFloat();
        }

        function requestGpsData() as Void{
            // let the positionManager handle the gps request, otherwise the positionManager is overruled and will stop
            setGpsState(STATE_BUSY);
            Position.enableLocationEvents({:acquisitionType => Position.LOCATION_ONE_SHOT}, method(:onGpsData));
        }

        function onGpsData(info as Position.Info) as Void{
            validatePositionInfo(info);

            // keep most accurate data
            var prevAccuracy = (gpsData != null) ? gpsData.accuracy : Position.QUALITY_NOT_AVAILABLE;
            if(info.accuracy > prevAccuracy){
                gpsData = info;
            }
            setGpsState(STATE_READY);
        }

        function requestOnlineData(position as Location) as Void{
            Communications.cancelAllRequests();
            setOnlineState(STATE_BUSY);

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

                        if(h instanceof Float && t_hourly instanceof Array){

                            // use average values for now
                            var t = Math.mean(t_hourly as Array<Numeric>).toFloat(); // temperature 2m above surface

                            // calculate temperature at sealevel
                            t0 = t + Lb * -(h+2);

                            // determine accuracy (combination of gps quality and web availability)
                            var accuracy = (gpsData != null) ? gpsData.accuracy : Position.QUALITY_NOT_AVAILABLE;
                            accuracy |= WEB_QUALITY_GOOD;

                            setAltitude(h, accuracy);
                            setOnlineState(STATE_READY);
                            return;
                        }
                    }
                }
            }
            // internet call failed -> use gps altitude
            if(gpsData != null){
                var altitude = gpsData.altitude;
                if(altitude != null){
                    var accuracy = gpsData.accuracy | WEB_QUALITY_NOT_AVAILABLE;
                    setAltitude(altitude, accuracy);
                }
            }

            setOnlineState(STATE_ERROR);
        }

        function setAltitude(altitude as Float, accuracy as Quality) as Void{
            // only keep altitude with highest accuracy
            if(accuracy >= self.accuracy){
                self.altitude = altitude;
                self.accuracy = accuracy;
        
                // set event to listener
                if(listener != null){
                    var l = listener.get();
                    if(l != null && (l as IListener) has :onAltitude){
                        (l as IListener).onAltitude(altitude, accuracy);
                    }
                }
            }
        }
    }
}