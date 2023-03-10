package steamwrap.api;

import steamwrap.helpers.SteamBase;

typedef Friend = {
	var SteamID:String;
	var PersonaName:String;
	var PersonaState:String;
	var AvatarHandle:String;
}

@:allow(steamwrap.api.Steam) class Friends extends SteamBase {
	public var friendsList:Map<SteamID, Friend> = [];

	override function init(appId:Int, customTrace:String->Void):Bool {
		super.init(appId, customTrace);

		return active;
	}
}
