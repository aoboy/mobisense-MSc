/*------------------------------------------------------------------------+
 *School of Electrical Engineering/School of Technology and Health        +
 +  Master Program In Network Services and Systems                        +
 +	Master Thesis..Project                                            +
 +------------------------------------------------------------------------*	
 + author: Gonga, Antonio - gonga@kth.se				  +
 + Date created: January 12, 2009 15:55:45 PM                             +
 +------------------------------------------------------------------------*/

/*
 FileName: RouterNodeP.nc
*/


module RouterNodeP{

  uses{
      interface Leds;
      interface Boot;
      interface Routing;
      interface NodeRole;
      interface Init as InitData;
      interface Intercept[am_id_t id];     
  }
}
implementation{

 event void Boot.booted(){
    call Routing.init();
    call InitData.init();     
    call NodeRole.setNodeAsRouter();
 }
 
 event bool Intercept.forward[am_id_t id](message_t *p, void* payload, uint8_t len){
       //call Leds.led2Toggle();
    return TRUE;
 }

}


