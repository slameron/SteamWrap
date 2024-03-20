package steamwrap.api;

import steamwrap.helpers.Friend;
import steamwrap.api.SteamID;
import steamwrap.helpers.SteamBase;

@:allow(steamwrap.api.Steam) class Friends extends SteamBase {
	override function init(appId:Int, customTrace:String->Void):Bool {
		super.init(appId, customTrace);

		#if steam
		for (i in 0...Steam.getFriendCount(4)) {
			addFriend(Steam.getFriendByIndex(i, 4));
		}
		#end

		return active;
	}

	var friends:Map<SteamID, Friend> = [];

	public function getFriend(steamID:SteamID):Friend
		return friends.exists(steamID) ? friends.get(steamID) : addFriend(steamID);

	public function getFriends():Array<Friend> {
		var f:Array<Friend> = [];

		for (friend in friends)
			f.push(friend);

		return f;
	}

	public function addFriend(steamID:SteamID):Friend {
		var friend = new Friend(steamID);
		friends.set(steamID, friend);
		return friend;
	}

	private function new(appId:Int, customTrace:String->Void) {
		if (active)
			return;
		init(appId, customTrace);
	}
}
