package steamwrap.api;

import haxe.io.Bytes;
import steamwrap.helpers.Loader;
import steamwrap.helpers.SteamBase;

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
	public function broadcast(eventType:String, data:Dynamic, type:SteamNetworkingSend, toSelf:Bool = true) {
		if (Steam.matchmaking.getLobbyID() == '0')
			return;

		for (i in 0...Steam.matchmaking.getLobbyMembers()) {
			var id = Steam.matchmaking.getLobbyMember(i);

			if (!toSelf)
				if (Steam.getSteamID() == id)
					continue;

			sendMessage(id, eventType, data, type);
		}
	}

	/**
	 * Stores an incrementing number for each event, for each person you send an event to. The packet manager will drop packets whose sequence is less than that of the newest accepted packet.
	 */
	var sequencer:Map<String, Map<String, Int>> = [];

	/**
	 * Sends a packet to the given endpoint.
	 * @param id The SteamID of the endpoint. Usually the ID of another Steam user.
	 * @param eventType The name of the event you're sending this packet for. Make sure to use `Steam.addPacketEvent()` to add a callback for when this packet is received.
	 * @param data The data you want to send.
	 * @param type The type of packet you're sending. Valid options are `UNRELIABLE`, `UNRELIABLE_NO_DELAY`, `RELIABLE`, and `RELIABLE_WITH_BUFFERING` 
	 */ @:deprecated('Uses deprecated ISteamNetworking, use sendMessage instead')
	public function sendPacket(id:String, eventType:String, data:Dynamic, type:EP2PSend):Int {
		if (!sequencer.exists(id))
			sequencer.set(id, []);

		if (sequencer.get(id).exists(eventType))
			sequencer.get(id).set(eventType, 0);

		sequencer.get(id).set(eventType, sequencer.get(id).get(eventType) + 1 % 500);

		var json = {type: eventType, data: data, sequence: sequencer.get(id).get(eventType)};
		var bytes = Bytes.ofString(haxe.Json.stringify(json));

		return SteamWrap_SendPacket(id, bytes, bytes.length, cast type);
	}

	private var SteamWrap_SendPacket = Loader.loadRaw("SteamWrap_SendPacket", 4);

	public function sendMessage(id:String, eventType:String, data:Dynamic, sendFlags:SteamNetworkingSend, remoteChannel:Int = 0) {
		if (!sequencer.exists(id))
			sequencer.set(id, []);

		if (sequencer.get(id).exists(eventType))
			sequencer.get(id).set(eventType, 0);

		sequencer.get(id).set(eventType, sequencer.get(id).get(eventType) + 1 % 500);

		var json = {type: eventType, data: data, sequence: sequencer.get(id).get(eventType)};
		var bytes = Bytes.ofString(haxe.Json.stringify(json));

		if (id == Steam.getSteamID())
			return sendSelfMessage(id, json);
		return SteamWrap_SendMessage(id, bytes, bytes.length, sendFlags, remoteChannel);
	}

	function sendSelfMessage(id:String, json:Dynamic) {
		Steam.packetManager.selfMessages.push({src: id, json: json});
	}

	private var SteamWrap_SendMessage = Loader.loadRaw('SteamWrap_SendMessage', 5);

	// private var SteamWrap_SendP2PPacket = Loader.load("SteamWrap_SendP2PPacket", "coiii");

	/**
	 * Calls `queuePacket()` for every member in the current lobby. Send these packets with `Steam.networking.sendQueuedPackets()`.
	 * @param eventType The name of the event. Make sure to add a callback for this event using `Steam.addPacketEvent()`.
	 * @param data The data you want to send.
	 * @param type The type of packet you're sending. Valid options are `UNRELIABLE`, `UNRELIABLE_NO_DELAY`, `RELIABLE`, and `RELIABLE_WITH_BUFFERING`
	 * @param toSelf Whether or not the sender should also receive the packet.
	 */
	public function queueBroadcast(eventType:String, data:Dynamic, type:EP2PSend = UNRELIABLE, toSelf:Bool = true) {
		if (Steam.matchmaking.getLobbyID() == '0')
			return;

		for (i in 0...Steam.matchmaking.getLobbyMembers()) {
			var id = Steam.matchmaking.getLobbyMember(i);

			if (!toSelf)
				if (Steam.getSteamID() == id)
					continue;

			queuePacket(id, eventType, data, type);
		}
	}

	static var packetQueue:Array<{id:String, packet:Dynamic}> = [];

	/**
	 * Queues a packet to be sent when you call `Steam.networking.sendQueuedPackets()`.
	 * @param id The SteamID of the endpoint. Usually the ID of another Steam user.
	 * @param eventType The name of the event you're sending this packet for. Make sure to use `Steam.addPacketEvent()` to add a callback for when this packet is received.
	 * @param data The data you want to send.
	 * @param type The type of packet you're sending. Valid options are `UNRELIABLE`, `UNRELIABLE_NO_DELAY`, `RELIABLE`, and `RELIABLE_WITH_BUFFERING` 
	 */
	public function queuePacket(id:String, eventType:String, data:Dynamic, type:EP2PSend) {
		packetQueue.push({id: id, packet: {type: eventType, data: data, sendType: type}});
	}

	/**
		* Sends all packets that have been queued with `Steam.networking.queuePacket()` or `Steam.networking.queueBroadcast()`.
		* @return for (i in packetQueue)
					sendPacket(i.id, i.packet.type, i.packet.data, i.packet.sendType)
	 */
	public function sendQueuedPackets()
		for (i in packetQueue)
			sendPacket(i.id, i.packet.type, i.packet.data, i.packet.sendType);

	/**
	 * Pulls the next packet out of receive queue, returns whether there was one.
	 * If successful, also fills out data for getPacketData/getPacketSender.
	 */ @:deprecated('Uses deprecated ISteamNetworking, use receiveMessage instead')
	public function receivePacket():Bool {
		return SteamWrap_ReceivePacket();
	}

	private var SteamWrap_ReceivePacket = Loader.loadRaw("SteamWrap_ReceivePacket", 0);

	/**
	 * Returns the data of the last receives packet as Bytes.
	 */ @:deprecated('Uses deprecated ISteamNetworking, use getMessageBytes instead')
	public function getPacketData():Bytes {
		return Bytes.ofData(SteamWrap_GetPacketData());
	}

	private var SteamWrap_GetPacketData = Loader.loadRaw("SteamWrap_GetPacketData", 0);

	/**
	 * Returns Steam ID of sender of the last received packet.
	 */
	@:deprecated('Uses deprecated ISteamNetworking, use getMessageSender instead')
	public function getPacketSender():String {
		return SteamWrap_GetPacketSender();
	}

	private var SteamWrap_GetPacketSender = Loader.loadRaw("SteamWrap_GetPacketSender", 0);

	public function receiveMessage(remoteChannel:Int = 0):Bool {
		return SteamWrap_ReceiveMessage(remoteChannel);
	}

	private var SteamWrap_ReceiveMessage = Loader.loadRaw("SteamWrap_ReceiveMessage", 1);

	public function getMessageBytes():Bytes {
		return Bytes.ofData(SteamWrap_GetMessageBytes());
	}

	private var SteamWrap_GetMessageBytes = Loader.loadRaw('SteamWrap_GetMessageBytes', 0);

	public function getMessageSender():String {
		return SteamWrap_GetMessageSender();
	}

	private var SteamWrap_GetMessageSender = Loader.loadRaw('SteamWrap_GetMessageSender', 0);

	//
	private function new(appId:Int, customTrace:String->Void) {
		if (active)
			return;
		init(appId, customTrace);
	}
}

enum abstract EP2PSend(Int) {
	/** Akin to UDP */
	public var UNRELIABLE = 0;

	/** Akin to UDP with instant send flag */
	public var UNRELIABLE_NO_DELAY = 1;

	/** Akin to TCP */
	public var RELIABLE = 2;

	/** Akin to TCP with Nagle's algorithm*/
	public var RELIABLE_WITH_BUFFERING = 3;
}

enum abstract SteamNetworkingSend(Int) {
	public var UNRELIABLE = 0;
	public var NO_NAGLE = 1;
	// public var UNRELIABLE_NO_NAGLE = UNRELIABLE | NO_NAGLE;
	public var NO_DELAY = 4;
	// public var UNRELIABLE_NO_DELAY = UNRELIABLE | NO_DELAY | NO_NAGLE;
	public var RELIABLE = 8;
	// public var RELIABLE_NO_NAGLE = RELIABLE | NO_NAGLE;
}
