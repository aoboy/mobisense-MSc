/*------------------------------------------------------------------------+
 *School of Electrical Engineering/School of Technology and Health        +
 +  Master Program In Network Services and Systems                        +
 +	Master Thesis..Project                                            +
 +------------------------------------------------------------------------*	
 + author: Gonga, Antonio - gonga@kth.se				  +
 + Date created: January 12, 2009 16:30:00 PM                             +
 +------------------------------------------------------------------------*/

/*
 FileName: RootNodeP.nc
*/

configuration SenderNodeC{  
}
implementation{
  components 
     SenderNodeP,
     MobilityC;
  components
     LedsC,
     MainC,
     new TimerMilliC() as Timer; 
    
  
  SenderNodeP.Boot   -> MainC;
  SenderNodeP.Leds   -> LedsC;
  SenderNodeP.Timer0 -> Timer;
  
  SenderNodeP.Monitor   -> MobilityC;  
  SenderNodeP.Routing   -> MobilityC;
  SenderNodeP.Send      -> MobilityC;
  SenderNodeP.InitData  -> MobilityC;
  SenderNodeP.NodeRole  -> MobilityC;
}

