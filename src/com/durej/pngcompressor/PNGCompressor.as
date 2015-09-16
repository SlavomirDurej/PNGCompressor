package com.durej.pngcompressor
{
	import flash.globalization.LocaleID;
	import flash.globalization.NumberFormatter;
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
	import flash.utils.ByteArray;

	[SWF(backgroundColor="#FFFFFF", frameRate="31", width="320", height="650")]
	public class PNGCompressor extends Sprite
	{
		public var log_txt 					: TextField;
		public var minBtnGFX 				: Sprite;
		public var closeBtnGFX 				: Sprite;
		public var statusGFX 				: StatusGFX;
		public var ipaLabel_txt 			: TextField;
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
			win.width = 320;
			win.height = 650;
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
			ipaLabel_txt 			= gfx.ipaLabel_txt;
			originalFilesize_txt	= gfx.originalFilesize_txt;
			compressedFilesize_txt	= gfx.compressedFilesize_txt;
			log_txt					= gfx.log_txt;
			ratio_txt				= gfx.ratio_txt;
			this.addChild(gfx);

			// init dragging
			bgGFX.addEventListener(NativeDragEvent.NATIVE_DRAG_ENTER, onFileDragEnter);
			bgGFX.mouseChildren = false;
			ipaLabel_txt.mouseEnabled = false;

			log_txt.mouseEnabled = false;

			// listeners
			addListener(win, Event.CLOSE, NativeApplication.nativeApplication.exit, 0);
			addListener(gfx.headerGFX, MouseEvent.MOUSE_DOWN, stage.nativeWindow.startMove);
			addListener(gfx.closeBtnGFX, MouseEvent.CLICK, NativeApplication.nativeApplication.exit, 0);
			addListener(gfx.minBtnGFX, MouseEvent.CLICK, win.minimize);

			statusGFX.visible = false;
			
			pngQuantProcessor 		= PNGQuantProcessor.getInstance();
			pngQuantProcessor.log 	= log;

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
			ipaLabel_txt.visible 		= false;
			origSize					= pngFile.size;
			originalFilesize_txt.text = readableBytes(origSize);
			log("Compressing "+pngFile.name);
			pngQuantProcessor.compressPNGFile(pngFile,onCompressionComplete);
		}

		private function onCompressionComplete() : void
		{
			statusBusyIndicatorAnim.stop();
			
			statusGFX.visible 			= false;
			finalSize					= pngFile.size;
			compressedFilesize_txt.text = readableBytes(finalSize);
			ratio_txt.text = (int(finalSize/origSize * 100)).toString()+"%";
			
			log("Compression done sucessfuly..\nYou can drag'n'drop a new file now.");
		}

		private function log(log_str : String) : void
		{
			log_txt.text += log_str;
		}
	}
}
