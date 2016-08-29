/*------------------------------------------------------------------------+
 *School of Electrical Engineering/School of Technology and Health        +
 +  Master Program In Network Services and Systems                        +
 +	Master Thesis..Project                                            +
 +------------------------------------------------------------------------*	
 + author: Gonga, Antonio - gonga@kth.se				  +
 + Date created: January 12, 2009 15:38:05 PM                             +
 +------------------------------------------------------------------------*/

/*
 FileName: RouterNodeP.nc
*/


configuration RouterNodeC{  
}
implementation{
  components 
     RouterNodeP,
     MobilityC,
     LedsC,
     MainC;
  
  RouterNodeP.Boot -> MainC;
  RouterNodeP.Leds      -> LedsC;

  RouterNodeP.Routing   -> MobilityC;
  RouterNodeP.Intercept -> MobilityC;
  RouterNodeP.InitData  -> MobilityC;
  RouterNodeP.NodeRole  -> MobilityC;
}


