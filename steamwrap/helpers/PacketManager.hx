package steamwrap.helpers;

import steamwrap.api.Steam;

@:allow(steamwrap.api.Steam) class PacketManager extends SteamBase {
	public var events:Map<String, Dynamic->Void> = [];
	public var eventPersistence:Map<String, Bool> = [];

	private function new(appId:Int, customTrace:String->Void) {
		init(appId, customTrace);
	}

	var sequencer:Map<String, Map<String, Int>> = [];

	public function onEnterFrame() {
		if (Steam.active) {
			while (Steam.networking.receivePacket()) {
				var src = Steam.networking.getPacketSender();
				var str = Steam.networking.getPacketData().toString();
				var json = haxe.Json.parse(str);

				var type = json.type;

				var sequence = json.sequence;

				if (!sequencer.exists(src))
					sequencer.set(src, []);

				if (!sequencer.get(src).exists(type))
					sequencer.get(src).set(type, sequence);

				var sqcDiff = sequence - sequencer.get(src).get(type);
				if (sqcDiff < 0)
					sqcDiff = -sqcDiff;

				if (sqcDiff > 300)
					if (sequence < sequencer.get(src).get(type))
						seqencer.get(src).set(type, sequence);

				if (sequence < sequencer.get(src).get(type)) {
					customTrace('dropped packet $sequence because it was older than most recent packet ${sequencer.get(src).get(type)}');
					return;
				}

				seqencer.get(src).set(type, sequence);

				var data:Dynamic = {sender: {name: Steam.getFriendPersonaName(src), id: src}, data: json.data};

				if (events.exists(type))
					events.get(type)(data);
				else
					customTrace('There is no event for $type');
			}
		}
	}
}
