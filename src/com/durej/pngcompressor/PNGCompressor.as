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
		public static var eventSprite		: Sprite;
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
		private var jobQueue				: Array;
		private var jobIDX : int = 0;
		private var totalJobs : int;
		private var origSize_str : String;


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
			
			eventSprite				= new Sprite();

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
			dragPrompt_txt.text = "DRAG YOUR PNG FILE(S) OR DIRECTORY HERE\n\n!!!WARNING!!!\n\nDRAGGED FILE(S) WILL BE OVERWRITTEN";
			dragPrompt_txt.y = int((gfx.height - dragPrompt_txt.height)*.6);

			// init dragging
			this.addEventListener(NativeDragEvent.NATIVE_DRAG_ENTER, onFileDragEnter);
			this.addEventListener(NativeDragEvent.NATIVE_DRAG_EXIT, onFileDragExit);
			//this.mouseChildren = false;
			dragPrompt_txt.mouseEnabled = false;
			

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




		private function startJob(files_arr : Array) : void
		{
			log_txt.text = "";
			clearDragBG();
			jobQueue = [];
			jobIDX	= 0;
			
			if (files_arr.length == 1)
			{
				var file : File = File(files_arr[0]);
				if (!file) return;
				
				if (file.isDirectory)
				{
					var dirFiles_arr : Array = file.getDirectoryListing();
					for (var i : int = 0; i < dirFiles_arr.length; i++) 
					{
						file = dirFiles_arr[i];
						var fileType : String = file.type;
						if (fileType == ".png" || fileType == ".PNG") 
						{
							jobQueue.push(file);	
						}
					}					
				}
				else
				{
					fileType = file.type;
					if (fileType == ".png" || fileType == ".PNG")
					{
						jobQueue.push(file);
					}
				}
			}
			else
			{
				for (i  = 0; i < files_arr.length; i++) 
				{
					file = files_arr[i];
					if (file)
					{
						fileType = file.type;
						if (fileType == ".png" || fileType == ".PNG") 
						{
							jobQueue.push(file);	
						}
					}
				}				
			}
			totalJobs = jobQueue.length;
			executeAfterFrames(processJob,2);
		}

		private function processJob() : void
		{
		
			if (jobIDX < totalJobs)
			{
				pngFile = jobQueue[jobIDX];
				compressAppFile();
			}
			else
			{
				log("\n\nAll done\n\nYou can drag'n'drop a new file now.");
			}
			jobIDX++;
		}



		private function compressAppFile() : void
		{
			statusBusyIndicatorAnim.play();
			statusGFX.visible 			= true;
			dragPrompt_txt.visible 		= false;
			origSize					= pngFile.size;
			origSize_str				= readableBytes(origSize); 
			originalFilesize_txt.text 	= origSize_str;
			log("\n"+(jobIDX+1).toString()+"\tCompressing "+pngFile.name+"\n");
			
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
			
			log("\n\tUsing min quality: "+minQuality+", max quality: "+maxQuality+", speed:"+speed+"\n");
			
			pngQuantProcessor.compressPNGFile(pngFile,minQuality, maxQuality,speed, onCompressionComplete);
		}

		private function onCompressionComplete( sucess : Boolean = true) : void
		{
			statusBusyIndicatorAnim.stop();
			
			statusGFX.visible 				= false;
			finalSize						= pngFile.size;
			var finalSize_str	: String 	= readableBytes(finalSize); 
			compressedFilesize_txt.text 	= finalSize_str;
			var ratio 			: int 		= finalSize/origSize * 100;
			ratio_txt.text 					= ratio.toString()+"%";
			
			if (sucess)
			{
				log("\n\t"+pngFile.name+" : converted with ratio: "+ratio+"% | from: "+origSize_str+" to: "+finalSize_str+"\n\n");
			}
			else
			{
				log (pngFile.name+" : conversion failed!");
			}
			executeAfterFrames(processJob,2);
		}



		private function onFileDragEnter(event : NativeDragEvent) : void
		{
			if (event.clipboard.hasFormat(ClipboardFormats.FILE_LIST_FORMAT))
			{
				if (isValidDrop(event.clipboard.getData(ClipboardFormats.FILE_LIST_FORMAT) as Array))
				{
					NativeDragManager.acceptDragDrop(this);
					this.addEventListener(NativeDragEvent.NATIVE_DRAG_DROP, onDragDrop);
					invalidGFX.visible = false;
					validGFX.visible = true;					
				
				}else
				{
					invalidGFX.visible = true;
					validGFX.visible = false;
				}
			}
		}

		private function isValidDrop(files_arr : Array) : Boolean
		{
			if (files_arr.length == 1)
			{
				var file : File = File(files_arr[0]);
				if (!file) return false;
				
				if (file.isDirectory)
				{
					var dirFiles_arr : Array = file.getDirectoryListing();
					for (var i : int = 0; i < dirFiles_arr.length; i++) 
					{
						file = dirFiles_arr[i];
						var fileType : String = file.type;
						if (fileType == ".png" || fileType == ".PNG") return true;	
					}					
				}
				else
				{
					fileType = file.type;
					if (fileType == ".png" || fileType == ".PNG") return true;
				}
			}
			else
			{
				for (i  = 0; i < files_arr.length; i++) 
				{
					file = files_arr[i];
					if (file)
					{
						fileType = file.type;
						if (fileType == ".png" || fileType == ".PNG") return true;	
					}
				}				
			}
			return false;	
		}

		private function onDragDrop(event : NativeDragEvent) : void
		{
			startJob(event.clipboard.getData(ClipboardFormats.FILE_LIST_FORMAT) as Array);
		}

		private function onFileDragExit(event : NativeDragEvent) : void
		{
			clearDragBG();
		}

		private function clearDragBG() : void
		{
			validGFX.visible = invalidGFX.visible = false;
		}

		private function log(log_str : String) : void
		{
			log_txt.text += log_str;
			log_txt.scrollV = 9999;
		}
		
		private function readableBytes(bytes : Number) : String
        {
            var s:Array = ['bytes', 'kb', 'MB', 'GB', 'TB', 'PB'];
            var exp:Number = Math.floor(Math.log(bytes)/Math.log(1024));
            return  (bytes / Math.pow(1024, Math.floor(exp))).toFixed(2) + " " + s[exp];
        }
		
	}
}
