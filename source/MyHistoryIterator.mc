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
    hidden var index as Number or Null;

    function initialize(){
        SensorHistoryIterator.initialize();
    }

    function add(sample as SensorSample) as Void{
        if(mData != null){
            (mData as Array<SensorSample>).add(sample);
        }else{
            mData = [sample];
        }

        // update min/max
        var data = sample.data;
        if(data != null){
            if(mMax == null || mMax < data){
                mMax = data;
            }
            if(mMin == null || mMin > data){
                mMin = data;
            }
        }

        // update newest/oldest
        var when = sample.when;
        var value = when.value();
        if(mOldestSampleTime == null || value < mOldestSampleTime.value()){
            mOldestSampleTime = when;
        }
        if(mNewestSampleTime == null || value > mNewestSampleTime.value()){
            mNewestSampleTime = when;
        }
    }

    function clear() as Void{
        mData = null;
    }

    function getOldestSampleTime() as Time.Moment or Null{
        return SensorHistoryIterator.getOldestSampleTime();
    }
    function next() as SensorSample|Null{
        if(mData != null){
            if(index != null){
                index++;
            }else{
                index = 0;
            }

            // return sample
            if(index != null){
                var arr = mData as Array<SensorSample>;
                if(index < arr.size()){
                    return arr[index];
                }
            }
        }
        index = null;
        return null;
    }
}