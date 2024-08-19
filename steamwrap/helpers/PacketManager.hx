package steamwrap.helpers;

import steamwrap.api.Steam;

@:allow(steamwrap.api.Steam) class PacketManager extends SteamBase {
	public var events:Map<String, Dynamic->Void> = [];
	public var eventPersistence:Map<String, Bool> = [];

	private function new(appId:Int, customTrace:String->Void) {
		init(appId, customTrace);
	}

	var sequencer:Map<String, Map<String, Int>> = [];

	public var selfMessages:Array<{src:String, json:Dynamic}> = [];

	public function onEnterFrame() {
		if (Steam.active) {
			while (selfMessages.length > 0) {
				var msg = selfMessages.shift();
				var src = msg.src;

				var json = msg.json;

				var type = json.type;

				var sequence = json.sequence;

				var data:Dynamic = {
					sender: {id: src, name: Steam.getFriendPersonaName(src)},
					data: json.data
				};

				if (isOldPacket(src, type, sequence))
					return;

				if (events.exists(type))
					events.get(type)(data);
			}
			while (Steam.networking.receiveMessage()) {
				var src = Steam.networking.getMessageSender();

				var str = Steam.networking.getMessageBytes().toString();
				var json = haxe.Json.parse(str);

				var type = json.type;

				var sequence = json.sequence;

				var data:Dynamic = {
					sender: {id: src, name: Steam.getFriendPersonaName(src)},
					data: json.data
				};

				if (isOldPacket(src, type, sequence))
					return;

				if (events.exists(type))
					events.get(type)(data);
			}
		}
	}

	function isOldPacket(src:String, type:String, sequence:Int) {
		if (!sequencer.exists(src))
			sequencer.set(src, []);

		if (!sequencer.get(src).exists(type))
			sequencer.get(src).set(type, sequence);

		var sqcDiff = sequence - sequencer.get(src).get(type);
		if (sqcDiff < 0)
			sqcDiff = -sqcDiff;

		if (sqcDiff > 300)
			if (sequence < sequencer.get(src).get(type))
				sequencer.get(src).set(type, sequence);

		if (sequence < sequencer.get(src).get(type)) {
			customTrace('dropped packet $sequence because it was older than most recent packet ${sequencer.get(src).get(type)}');
			return true;
		}

		sequencer.get(src).set(type, sequence);
		return false;
	}
}
