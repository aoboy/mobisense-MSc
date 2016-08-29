/*------------------------------------------------------------------------+
 *School of Electrical Engineering/School of Technology and Health        +
 +  Master Program In Network Services and Systems                        +
 +	Master Thesis..Project                                            +
 +------------------------------------------------------------------------*	
 + author: Gonga, Antonio - gonga@kth.se				  +
 + Date created: January 12, 2009 02:10:45 AM                             +
 +------------------------------------------------------------------------*/

/*
 Mobile/RouterA.DataSend(A) --->RouterB.Intercept(B)---->RouterC.Intercept(C)-------->RouterBase.Receive(RootNode)
*/

#include "ETXLinkLayer.h"

configuration MobilityC{
   provides{
	interface Init;
	interface Packet;
	interface Routing;
	interface Monitor;
	interface NodeRole;
        interface DataSend;	
	interface StdControl;
	interface RouteControl;
	interface Receive[am_id_t];
        interface Intercept[am_id_t];
	
	interface LinkLayer;
	interface SendBeacon;
	interface ReceiveBeacon;
   }
}
implementation{
  components 
        ETXRoutingP as Router,
	ETXDataForwarderP as Forwarder,
        ETXLinkLayerP;
  components
        new AMSenderC(AM_BEACON_MSG) as BeaconSender,
        new AMReceiverC(AM_BEACON_MSG) as BeaconReceiver;
  components
        new AMSenderC(AM_ETXDATA_MSG) as DataSender,
        new AMSenderC(AM_ETXDATA_MSG) as DataSenderMine,
        new AMReceiverC(AM_ETXDATA_MSG) as DataReceiver;
  components
        new TimerMilliC() as Timer1,
        new TimerMilliC() as Timer2,
	new TimerMilliC() as Timer3,
	new TimerMilliC() as Timer4,
        MainC,
        LedsC;
  components 
        ActiveMessageC,
        CC2420ActiveMessageC as CC2420;        
 
  //Wiring
  MainC.SoftwareInit -> Forwarder;  

  LinkLayer    = ETXLinkLayerP;
  SendBeacon   = ETXLinkLayerP;
  ReceiveBeacon= ETXLinkLayerP;

  Init         = Forwarder;
  Packet       = Forwarder;
  DataSend     = Forwarder;
  Receive      = Forwarder.Receive;
  Intercept    = Forwarder.Intercept;

  Routing      = Router;
  Monitor      = Router;
  NodeRole     = Router;
  StdControl   = Router;
  RouteControl = Router; 

  Forwarder.Leds         -> LedsC;
  Forwarder.AMPacket     -> ActiveMessageC;
  Forwarder.SplitControl -> ActiveMessageC;
  Forwarder.Forward      -> DataSender;
  Forwarder.SubSend      -> DataSenderMine;
  Forwarder.RecvData     -> DataReceiver;
  Forwarder.SubPacket    -> ActiveMessageC;
  Forwarder.Routing      -> Router;
  Forwarder.Monitor      -> Router;
  Forwarder.RouteControl -> Router;
  Forwarder.LinkLayer    -> ETXLinkLayerP;
  Forwarder.MonitorTimer -> Timer4;

  Router.Leds            -> LedsC;
  Router.Send            -> Forwarder;
  Router.AMPacket        -> ActiveMessageC;
  Router.Packet          -> ActiveMessageC;
  Router.CC2420Packet    -> CC2420;
  Router.Timer0          -> Timer1;
  Router.updateTimer     -> Timer2;
  Router.ReceiveBeacon   -> ETXLinkLayerP;
  Router.SendBeacon      -> ETXLinkLayerP;
  Router.LinkLayer       -> ETXLinkLayerP;

  ETXLinkLayerP.SendBcn  -> BeaconSender;
  ETXLinkLayerP.BeaconRcv-> BeaconReceiver;
  ETXLinkLayerP.Leds     -> LedsC;
  ETXLinkLayerP.Packet   -> ActiveMessageC;
  ETXLinkLayerP.AMPacket -> ActiveMessageC;
  ETXLinkLayerP.updtTimer-> Timer3;
}

