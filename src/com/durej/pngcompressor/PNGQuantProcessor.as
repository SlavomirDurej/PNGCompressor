package com.durej.pngcompressor
{
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.events.NativeProcessExitEvent;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	/**
	 * @author slavd
	 */
	public class PNGQuantProcessor
	{
		private static var instance 			: PNGQuantProcessor;
		private var process 					: NativeProcess;
		public var log 							: Function;
		private var processArgs 				: Vector.<String>;
		private var nativeProcessStartupInfo 	: NativeProcessStartupInfo;
		private var onComplete 					: Function;


		public function PNGQuantProcessor(blocker : Blocker, fromSingleton : Boolean)
		{
			if (!fromSingleton || blocker == null) throw new Error("use getInstance");
		}

		public static function getInstance() : PNGQuantProcessor
		{
			if (instance == null)
			{
				instance = new PNGQuantProcessor(new Blocker, true);
				instance.init();
			}
			return instance;
		}


		private function init() : void
		{

		}
		
		
		public function compressPNGFile(pngFile : File, minQuality:int, maxQuality:int, speed:int, onComplete : Function) : void
		{
			this.onComplete = onComplete;

			nativeProcessStartupInfo = new NativeProcessStartupInfo();
			var app : File = File.applicationDirectory.resolvePath("pngquant.exe");
			nativeProcessStartupInfo.executable = app;
			nativeProcessStartupInfo.workingDirectory = File.applicationDirectory;
			processArgs = new Vector.<String>();

			//processArgs.push("--verbose");
			processArgs.push("--quality="+minQuality+"-"+maxQuality);
			processArgs.push("--speed="+speed);
			processArgs.push("--force");
			processArgs.push(pngFile.nativePath);

			// get destination file
			// output
			processArgs.push("-o");
			processArgs.push(pngFile.nativePath);
			
			nativeProcessStartupInfo.arguments = processArgs;

			process = new NativeProcess();
			process.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onProcessOutput);
			process.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, onProcessError);
			process.addEventListener(ProgressEvent.STANDARD_INPUT_PROGRESS, onProcess);
			process.addEventListener(NativeProcessExitEvent.EXIT, onExit);

			try
			{
				process.start(nativeProcessStartupInfo);
			}
			catch (e : Error)
			{
				log("ONG compression failed: " + e.message);
			}
		}
		
		
		protected function onExit(event : NativeProcessExitEvent) : void 
		{
			if (event.exitCode == 99)
			{
				log("WARNING : \n\nConversion resulted in quality below the min quality. Please decrease the min quality value and try again.");
			}
			if(onComplete) onComplete(event.exitCode == 0);
		}
		
		
		private function onProcessOutput(event : ProgressEvent) : void
		{
			var result:String = process.standardOutput.readUTFBytes(process.standardOutput.bytesAvailable);
			 log(result);
		}
		
		
		private function onProcess(event : ProgressEvent) : void
		{
			if (process.running)
			{
				var result:String = process.standardOutput.readUTFBytes(process.standardOutput.bytesAvailable);
				log("PROCESS : "+result);
			}
		}

		private function onProcessError(event : ProgressEvent) : void
		{
			var result:String = process.standardError.readUTFBytes(process.standardError.bytesAvailable);
			log(result);
		}
	}
}

class Blocker
{
}