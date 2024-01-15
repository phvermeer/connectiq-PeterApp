import Toybox.Lang;

class Listeners{
    hidden var weakListeners as Array<WeakReference> = [] as Array<WeakReference>;
    hidden var method as Symbol;

    function initialize(method as Symbol){
        self.method = method;
    }
    function add(listener as Object) as Void{
        if(listener has method){
            var weakListener = listener.weak();
            if(weakListeners.indexOf(weakListener)<0){
                weakListeners.add(listener.weak());
            }
        }
    }
    function notify(info as Object) as Void{
        for(var i=0; i<weakListeners.size(); i++){
            var weaklistener = weakListeners[i] as WeakReference;
            var listener = weaklistener.get() as Object|Null;
            if(listener != null){
                listener.method(method).invoke(info);
            }else{
                weakListeners.remove(weaklistener);
                i--;
            }
        }
    }
}
