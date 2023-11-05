import Toybox.SensorHistory;
import Toybox.Lang;
import Toybox.Time;

class MySample extends SensorSample{
    function initialize(data as Float|Number|Null){
        SensorSample.initialize();
        self.when = Time.now();
        self.data = data;
    }
}

class MyHistoryIterator extends SensorHistoryIterator{
    function initialize(){
        SensorHistoryIterator.initialize();
    }

    function add(sample as SensorSample) as Void{
        if(mData != null){
            (mData as Array<SensorSample>).add(sample);
        }else{
            mData = [sample];
        }

        var data = sample.data;
        if(data != null){
            if(mMax == null || mMax < data){
                mMax = data;
            }
            if(mMin == null || mMin > data){
                mMin = data;
            }
        }
    }
}