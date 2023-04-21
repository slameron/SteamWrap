package steamwrap.api;

import haxe.io.Bytes;
import steamwrap.helpers.SteamBase;
import steamwrap.helpers.Loader;

/**
 * Selective wrapper for Steam networking API.
 * (implementing P2P session API is not required)
 * @author YellowAfterlife
 */
@:allow(steamwrap.api.Steam)
class Networking extends SteamBase {
	/**
	 * Calls `sendPacket()` for every member in the current lobby.
	 * @param eventType The name of the event. Make sure to add a callback for this event using `Steam.addPacketEvent()`.
	 * @param data The data you want to send.
	 * @param type The type of packet you're sending. Valid options are `UNRELIABLE`, `UNRELIABLE_NO_DELAY`, `RELIABLE`, and `RELIABLE_WITH_BUFFERING`
	 * @param toSelf Whether or not the sender should also receive the packet.
	 */
	public function broadcast(eventType:String, data:Dynamic, type:EP2PSend = UNRELIABLE, toSelf:Bool = true) {
		if (Steam.matchmaking.getLobbyID() == '0')
			return;

		for (i in 0...Steam.matchmaking.getLobbyMembers()) {
			var id = Steam.matchmaking.getLobbyMember(i);

			if (!toSelf)
				if (Steam.getSteamID() == id)
					continue;

			sendPacket(id, eventType, data, type);
		}
	}

	/**
	 * Sends a packet to the given endpoint.
	 * @param id The SteamID of the endpoint. Usually the ID of another Steam user.
	 * @param eventType The name of the event you're sending this packet for. Make sure to use `Steam.addPacketEvent()` to add a callback for when this packet is received.
	 * @param data The data you want to send.
	 * @param type The type of packet you're sending. Valid options are `UNRELIABLE`, `UNRELIABLE_NO_DELAY`, `RELIABLE`, and `RELIABLE_WITH_BUFFERING` 
	 */
	public function sendPacket(id:String, eventType:String, data:Dynamic, type:EP2PSend):Int {
		var json = {type: eventType, data: data};
		var bytes = Bytes.ofString(haxe.Json.stringify(json));

		return SteamWrap_SendPacket(id, bytes, bytes.length, cast type);
	}

	// private var SteamWrap_SendP2PPacket = Loader.load("SteamWrap_SendP2PPacket", "coiii");
	private var SteamWrap_SendPacket = Loader.loadRaw("SteamWrap_SendPacket", 4);

	/**
	 * Pulls the next packet out of receive queue, returns whether there was one.
	 * If successful, also fills out data for getPacketData/getPacketSender.
	 */
	public function receivePacket():Bool {
		return SteamWrap_ReceivePacket();
	}

	private var SteamWrap_ReceivePacket = Loader.loadRaw("SteamWrap_ReceivePacket", 0);

	/**
	 * Returns the data of the last receives packet as Bytes.
	 */
	public function getPacketData():Bytes {
		return Bytes.ofData(SteamWrap_GetPacketData());
	}

	private var SteamWrap_GetPacketData = Loader.loadRaw("SteamWrap_GetPacketData", 0);

	/**
	 * Returns Steam ID of sender of the last received packet.
	 */
	public function getPacketSender():String {
		return SteamWrap_GetPacketSender();
	}

	private var SteamWrap_GetPacketSender = Loader.loadRaw("SteamWrap_GetPacketSender", 0);

	//
	private function new(appId:Int, customTrace:String->Void) {
		if (active)
			return;
		init(appId, customTrace);
	}
}

@:enum abstract EP2PSend(Int) {
	/** Akin to UDP */
	public var UNRELIABLE = 0;

	/** Akin to UDP with instant send flag */
	public var UNRELIABLE_NO_DELAY = 1;

	/** Akin to TCP */
	public var RELIABLE = 2;

	/** Akin to TCP with Nagle's algorithm*/
	public var RELIABLE_WITH_BUFFERING = 3;
}
