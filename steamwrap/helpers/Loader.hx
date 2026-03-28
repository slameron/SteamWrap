package steamwrap.helpers;

#if macro
import haxe.macro.Expr;
#elseif sys
import haxe.io.Path;
import sys.FileSystem;
#end


class Loader
{
	#if cpp
	public static function __init__()
	{
		cpp.Lib.pushDllSearchPath( "" + cpp.Lib.getBinDirectory() );
		cpp.Lib.pushDllSearchPath( "ndll/" + cpp.Lib.getBinDirectory() );
		cpp.Lib.pushDllSearchPath( "project/ndll/" + cpp.Lib.getBinDirectory() );
	}
	#end

	public static inline macro function load(inName2:Expr, inSig:Expr)
	{
		return macro cpp.Prime.load("steamwrap", $inName2, $inSig, false);
	}

	public static var loadErrors:Array<String> = [];
	#if !macro
	private static function fallback() { }
	private static var modulePath:String = null;

	private static function getModulePath():String {
		if (modulePath == null) {
			var programPath = Sys.programPath();
			try {
				programPath = FileSystem.fullPath(programPath);
			} catch (e:Dynamic) {}
			modulePath = Path.join([Path.directory(programPath), "steamwrap"]);
		}
		return modulePath;
	}
	/**
	 * Attempts to load a function from SteamWrap C++ library.
	 * If that fails, logs the error and returns a fallback function to reduce the odds of hard crashing on call to a broken function.
	 */
	public static function loadRaw(name:String, argc:Int):Dynamic {
		for (library in [getModulePath(), "steamwrap"]) {
			try {
				var r = cpp.Lib.load(library, name, argc);
				if (r != null) return r;
			} catch (e:Dynamic) {
				loadErrors.push(Std.string(e));
			}
		}
		return function() {
			trace('Error: $name is not loaded.');
			return null;
		};
	}
	#end
}
