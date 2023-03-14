package steamwrap.helpers;

import steamwrap.api.Steam;
import steamwrap.api.SteamID;

class Friend {
	public var personaName(get, never):String;
	public var personaState(get, never):String;
	public var inGame(get, never):Bool;
	public var gamePlayed(get, never):String;
	public var steamID(get, never):SteamID;

	function get_personaName():String
		return _name;

	function get_personaState():String
		return _state;

	function get_inGame():Bool
		return _inGame;

	function get_gamePlayed():String
		return _gamePlayed;

	function get_steamID():SteamID
		return _id;

	var _name:String;
	var _state:String;
	var _inGame:Bool;
	var _gamePlayed:String;
	var _id:SteamID;

	public function new(steamID:SteamID) {
		_id = steamID;
		#if steam
		updateInfo();
		#end
	}

	public function updateInfo() {#if steam _name = Steam.getFriendPersonaName(_id);
		_state = Steam.getFriendPersonaState(_id); #end
	}
}
