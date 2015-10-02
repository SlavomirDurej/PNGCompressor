package com.durej.pngcompressor
{
	
	import flash.events.Event;

	public function executeAfterFrames(callback : Function, numTimes : int = 0) : void
	{
		var idx : int = 0;
		PNGCompressor.eventSprite.addEventListener(Event.ENTER_FRAME, function(e:Event):void
		{
			if (numTimes == idx)
			{
				PNGCompressor.eventSprite.removeEventListener(Event.ENTER_FRAME, arguments["callee"]);
				callback();
			}
			idx++;
		});
	}
}

