/*------------------------------------------------------------------------+
 *School of Electrical Engineering/School of Technology and Health        +
 +  Master Program In Network Services and Systems                        +
 +	Master Thesis..Project                                            +
 +------------------------------------------------------------------------*	
 + author: Gonga, Antonio - gonga@kth.se				  +
 + Date created: January 12, 2009 16:30:00 PM                             +
 +------------------------------------------------------------------------*/

/*
 FileName: RootNodeC.nc
*/

#define AM_UART_ID   10

configuration RootNodeC{  
}
implementation{
  components 
     RootNodeP,
     MobilityC;
  components
     LedsC,
     MainC; 
  components 
     SerialActiveMessageC as Serial,
     new SerialAMSenderC(AM_UART_ID) as SerialAM1; 
  
  RootNodeP.Boot -> MainC;
  RootNodeP.Leds -> LedsC;

  RootNodeP.SerialSend    -> SerialAM1.AMSend;
  RootNodeP.SerialControl -> Serial;
  
  RootNodeP.Routing   -> MobilityC;
  RootNodeP.Receive   -> MobilityC;
  RootNodeP.InitData  -> MobilityC;
  RootNodeP.NodeRole  -> MobilityC;
}

