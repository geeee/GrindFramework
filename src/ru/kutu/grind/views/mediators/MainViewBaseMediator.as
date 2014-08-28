package ru.kutu.grind.views.mediators  {
	
	import flash.display.LoaderInfo;
	import flash.events.ErrorEvent;
	import flash.events.UncaughtErrorEvent;
    import flash.utils.setTimeout;

    import org.osmf.events.MediaErrorEvent;
	import org.osmf.events.MediaPlayerStateChangeEvent;
	import org.osmf.media.MediaPlayer;
	import org.osmf.media.MediaPlayerState;
	
	import robotlegs.bender.bundles.mvcs.Mediator;
	import robotlegs.bender.extensions.contextView.ContextView;
	import robotlegs.bender.framework.api.ILogger;
    import ru.kutu.grind.events.LoadMediaEvent;

	import ru.kutu.grind.views.api.IMainView;
	
	public class MainViewBaseMediator extends Mediator {
		
		[Inject] public var logger:ILogger;
		[Inject] public var contextView:ContextView;
		[Inject] public var view:IMainView;
		[Inject] public var player:MediaPlayer;

        private const RELOAD_TIME:int = 5;
        private var reloadTimeLeft:int = RELOAD_TIME;
		
		override public function initialize():void {
			var loaderInfo:LoaderInfo = contextView.view.loaderInfo;
			
			// Register the global error handler.
			if (loaderInfo && "uncaughtErrorEvents" in loaderInfo) {
				loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onUncaughtError);
			}
			
			player.addEventListener(MediaPlayerStateChangeEvent.MEDIA_PLAYER_STATE_CHANGE, onMediaPlayerStateChange);
			player.addEventListener(MediaErrorEvent.MEDIA_ERROR, onMediaError);
		}

		protected function onMediaPlayerStateChange(event:MediaPlayerStateChangeEvent):void {
			switch (event.state) {
				case MediaPlayerState.UNINITIALIZED:
					view.initializing();
					break;
				case MediaPlayerState.PLAYBACK_ERROR:
					view.error();
					break;
				case MediaPlayerState.PLAYING:
				case MediaPlayerState.READY:
					view.ready();
					break;
			}
		}

        protected function onMediaError(event:MediaErrorEvent):void {
            var arr:Array = [];
            if (event.error) {
                if (event.error.message) {
                    arr.push("Message: " + event.error.message);
                }
                if (event.error.detail) {
                    arr.push("Detail: " + event.error.detail);
                }
            }

            var message:String = arr.join("\n");

            _reloadTick(message);

            CONFIG::LOGGING {
                logger.error("onMediaError:\n{0}", [message]);
            }
        }

        private function _reloadTick(message:String):void {
            view.errorText = "Reloading stream in " + reloadTimeLeft + " second" + (reloadTimeLeft == 1 ? "" : "s") +
                    "\n\n" + message;
            if (reloadTimeLeft == 0) {
                reloadTimeLeft = RELOAD_TIME;
                eventDispatcher.dispatchEvent(new LoadMediaEvent(LoadMediaEvent.LOAD_MEDIA));
            } else {
                setTimeout(_reloadTick, 1000, message);
            }
            reloadTimeLeft -= 1;
        }
		
		protected function onUncaughtError(event:UncaughtErrorEvent):void {
			event.preventDefault();
			
			var message:String;
			if (event.error is Error) {
				message = Error(event.error).message;
			} else if (event.error is ErrorEvent) {
				message = ErrorEvent(event.error).text;
			} else {
				message = event.error.toString();
			}
			
			CONFIG::LOGGING {
				logger.error("onUncaughtError: {0}", [message]);
			}
		}
		
	}
	
}
