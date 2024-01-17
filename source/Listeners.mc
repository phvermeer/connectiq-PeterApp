import Toybox.Lang;

class Listeners{
    hidden var weakListeners as Array<WeakReference> = [] as Array<WeakReference>;
    hidden var method as Symbol;

    function initialize(method as Symbol){
        self.method = method;
    }
    function add(listener as Object, initialInfo as Object|Null) as Void{
        if(listener has method){
            var weakListener = listener.weak();
            if(weakListeners.indexOf(weakListener)<0){
                weakListeners.add(listener.weak());
                if(initialInfo != null){
                    invoke(listener, initialInfo);
                }
            }
        }
    }
    function notify(info as Object|Null) as Void{
        for(var i=0; i<weakListeners.size(); i++){
            var weaklistener = weakListeners[i] as WeakReference;
            var listener = weaklistener.get() as Object|Null;
            if(listener != null){
                invoke(listener, info);
            }else{
                weakListeners.remove(weaklistener);
                i--;
            }
        }
    }
    hidden function invoke(listener as Object, info as Object|Null) as Void{
        listener.method(method).invoke(info);
    }
}
