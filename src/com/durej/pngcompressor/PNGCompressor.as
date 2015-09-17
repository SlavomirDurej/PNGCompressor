package com.durej.pngcompressor
{
	import flash.text.TextFieldAutoSize;
	import com.bwhiting.utilities.events.addListener;

	import flash.desktop.ClipboardFormats;
	import flash.desktop.NativeApplication;
	import flash.desktop.NativeDragManager;
	import flash.display.MovieClip;
	import flash.display.NativeWindow;
	import flash.display.NativeWindowInitOptions;
	import flash.display.NativeWindowSystemChrome;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.NativeDragEvent;
	import flash.filesystem.File;
	import flash.text.TextField;

	[SWF(backgroundColor="#FFFFFF", frameRate="31", width="640", height="700")]
	public class PNGCompressor extends Sprite
	{
		public var log_txt 					: TextField;
		public var minBtnGFX 				: Sprite;
		public var closeBtnGFX 				: Sprite;
		public var statusGFX 				: StatusGFX;
		public var dragPrompt_txt 			: TextField;
		public var originalFilesize_txt		: TextField;
		public var compressedFilesize_txt	: TextField;
		public var headerGFX 				: Sprite;
		public var bgGFX 					: Sprite;
		private var gfx 					: MainGFX;
		private var ratio_txt 				: TextField;
		private var statusBusyIndicatorAnim : MovieClip;
		private var pngFile 				: File;
		private var pngQuantProcessor 		: PNGQuantProcessor;
		private var origSize				: int;
		private var finalSize				: int;
		public var minQuality_txt 			: TextField;
		public var maxQuality_txt 			: TextField;
		public var speed_txt 				: TextField;
		public var validGFX 				: Sprite;
		public var invalidGFX 				: Sprite;

		public function PNGCompressor()
		{
			init();
		}

		private function init() : void
		{
			// window options
			var options : NativeWindowInitOptions = new NativeWindowInitOptions();
			options.resizable = false;
			options.systemChrome = NativeWindowSystemChrome.NONE;

			// create window
			var win : NativeWindow = new NativeWindow(options);
			win.width = 640;
			win.height = 700;
			win.activate();
			win.stage.addChild(this);

			// stage setup
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;

			// init graphics
			gfx 					= new MainGFX();
			bgGFX 					= gfx.bgGFX;
			statusGFX 				= gfx.statusGFX;
			statusBusyIndicatorAnim = statusGFX.statusBusyIndicatorAnim;
			dragPrompt_txt 			= gfx.dragPrompt_txt;
			originalFilesize_txt	= gfx.originalFilesize_txt;
			compressedFilesize_txt	= gfx.compressedFilesize_txt;
			log_txt					= gfx.log_txt;
			ratio_txt				= gfx.ratio_txt;
			minQuality_txt			= gfx.minQuality_txt;
			maxQuality_txt			= gfx.maxQuality_txt;
			speed_txt				= gfx.speed_txt;
			validGFX				= gfx.bgGFX.validGFX;
			invalidGFX				= gfx.bgGFX.invalidGFX;

			this.addChild(gfx);
			
			//init default values
			minQuality_txt.text = "5";
			maxQuality_txt.text = "95";
			speed_txt.text 		= "1";
			dragPrompt_txt.autoSize = TextFieldAutoSize.CENTER;
			dragPrompt_txt.text = "DRAG YOUR PNG FILE HERE\n\n!!!WARNING!!!\n\nDRAGGED FILE WILL BE OVERWRITTEN";
			dragPrompt_txt.y = int((gfx.height - dragPrompt_txt.height)*.6);

			// init dragging
			bgGFX.addEventListener(NativeDragEvent.NATIVE_DRAG_ENTER, onFileDragEnter);
			bgGFX.addEventListener(NativeDragEvent.NATIVE_DRAG_EXIT, onFileDragExit);
			bgGFX.mouseChildren = false;
			dragPrompt_txt.mouseEnabled = false;
			log_txt.mouseEnabled = false;

			// listeners
			addListener(win, Event.CLOSE, NativeApplication.nativeApplication.exit, 0);
			addListener(gfx.headerGFX, MouseEvent.MOUSE_DOWN, stage.nativeWindow.startMove);
			addListener(gfx.closeBtnGFX, MouseEvent.CLICK, NativeApplication.nativeApplication.exit, 0);
			addListener(gfx.minBtnGFX, MouseEvent.CLICK, win.minimize);

			statusGFX.visible = false;
			
			pngQuantProcessor 		= PNGQuantProcessor.getInstance();
			pngQuantProcessor.log 	= log;
			
			clearDragBG();
		}

		private function onFileDragExit(event : NativeDragEvent) : void
		{
			clearDragBG();
		}

		private function clearDragBG() : void
		{
			validGFX.visible = invalidGFX.visible = false;
		}

		private function onFileDragEnter(event : NativeDragEvent) : void
		{
			if (event.clipboard.hasFormat(ClipboardFormats.FILE_LIST_FORMAT))
			{
				var files : Array = event.clipboard.getData(ClipboardFormats.FILE_LIST_FORMAT) as Array;
				var fileType : String = File(files[0]).type;
				// check to see if the list contains a .jpg or .png file
				if (fileType == ".png" || fileType == ".PNG")
				{
					NativeDragManager.acceptDragDrop(bgGFX);
					bgGFX.addEventListener(NativeDragEvent.NATIVE_DRAG_DROP, onDragDrop);
					invalidGFX.visible = false;
					validGFX.visible = true;
				}
				else
				{
					invalidGFX.visible = true;
					validGFX.visible = false;
				}
			}
		}

		private function onDragDrop(event : NativeDragEvent) : void
		{
			var files : Array = event.clipboard.getData(ClipboardFormats.FILE_LIST_FORMAT) as Array;
			var file : File = File(files[0]);

			if (file.type == ".png" || file.type == ".PNG")
			{
				pngFile = file;
				clearDragBG();
				compressAppFile();
			}
		}
		
		 private function readableBytes(bytes:Number):String
        {
            var s:Array = ['bytes', 'kb', 'MB', 'GB', 'TB', 'PB'];
            var exp:Number = Math.floor(Math.log(bytes)/Math.log(1024));
            return  (bytes / Math.pow(1024, Math.floor(exp))).toFixed(2) + " " + s[exp];
        }

		private function compressAppFile() : void
		{
			log_txt.text = "";
			statusBusyIndicatorAnim.play();
			statusGFX.visible 			= true;
			dragPrompt_txt.visible 		= false;
			origSize					= pngFile.size;
			originalFilesize_txt.text = readableBytes(origSize);
			log("Compressing "+pngFile.name+"\n");
			
			//min quality
			var minQuality:int = parseInt(minQuality_txt.text);
			if (!minQuality)
			{
				minQuality = 0;
			}
			if (minQuality < 0) minQuality = 0;
			if (minQuality > 100) minQuality = 100;
			
			//max quality
			var maxQuality:int = parseInt(maxQuality_txt.text);
			if (!maxQuality)
			{
				maxQuality = 95;
			}
			if (maxQuality < 5) maxQuality = 5;
			if (maxQuality > 100) maxQuality = 100;
			
			//speed
			var speed:int = parseInt(speed_txt.text);
			if (speed_txt.text == "0") speed = 1; 
			if (!speed)
			{
				speed = 3;
			}
			if (speed < 1) speed = 1;
			if (speed > 10) speed = 10;
			
			log("\nUsing min quality: "+minQuality+", max quality: "+maxQuality+", speed:"+speed+"\n\n");
			
			pngQuantProcessor.compressPNGFile(pngFile,minQuality, maxQuality,speed, onCompressionComplete);
		}

		private function onCompressionComplete( sucess : Boolean = true) : void
		{
			statusBusyIndicatorAnim.stop();
			
			statusGFX.visible 			= false;
			finalSize					= pngFile.size;
			compressedFilesize_txt.text = readableBytes(finalSize);
			ratio_txt.text = (int(finalSize/origSize * 100)).toString()+"%";
			
			if (sucess)
			{
				log("Png file converted successfuly\n\nYou can drag'n'drop a new file now.");
			}
		}

		private function log(log_str : String) : void
		{
			log_txt.text += log_str;
		}
	}
}
