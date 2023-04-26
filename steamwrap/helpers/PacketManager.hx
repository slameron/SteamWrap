package steamwrap.helpers;

import steamwrap.api.Steam;

@:allow(steamwrap.api.Steam) class PacketManager extends SteamBase {
	public var events:Map<String, Dynamic->Void> = [];
	public var eventPersistence:Map<String, Bool> = [];

	private function new(appId:Int, customTrace:String->Void) {
		init(appId, customTrace);
	}

	public function onEnterFrame() {
		if (Steam.active) {
			while (Steam.networking.receivePacket()) {
				var src = Steam.networking.getPacketSender();
				var str = Steam.networking.getPacketData().toString();
				var json = haxe.Json.parse(str);

				var type = json.type;
				var data:Dynamic = {sender: {name: Steam.getFriendPersonaName(src), id: src}, data: json.data};

				if (events.exists(type))
					events.get(type)(data);
				else
					customTrace('There is no event for $type');
			}
		}
	}
}
