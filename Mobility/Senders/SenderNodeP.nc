/*------------------------------------------------------------------------+
 *School of Electrical Engineering/School of Technology and Health        +
 +  Master Program In Network Services and Systems                        +
 +	Master Thesis..Project                                            +
 +------------------------------------------------------------------------*	
 + author: Gonga, Antonio - gonga@kth.se				  +
 + Date created: January 12, 2009 15:55:45 PM                             +
 + LastModified: Jan 15, 2009 : 05:43:45 AM			          +
 +------------------------------------------------------------------------*/

/*
 FileName: SenderNodeP.nc
*/


module SenderNodeP{

  uses{
      interface Boot;
      interface Monitor;
      interface Routing;
      interface NodeRole;
      interface Init as InitData;
      interface DataSend as Send; 

      interface Leds;
      interface Timer<TMilli> as Timer0;    
  }
}
implementation{

 typedef struct mydata{
  uint8_t idx;
  uint8_t buf[21];
 }mydata_t;
 
 message_t msg;
 uint8_t idx = 0;
 uint16_t counter=0;

 event void Boot.booted(){    
    
    call Routing.init();
    call InitData.init(); 

    call NodeRole.setNodeAsMobile();        

    call Monitor.enableAuto();
    call Monitor.setInterval(100);
   
    call Timer0.startOneShot(1);
 }
 
 task void SendPacketTask(){
   uint8_t k;
   mydata_t *pkt = call Send.getPayload(&msg, sizeof(mydata_t));
   pkt->idx = idx;
    
   call Send.setPacketType(&msg, 3);
   if(call Send.send(&msg, sizeof(mydata_t)) == EBUSY){        
	post SendPacketTask();
   }else{
         counter++;
	 idx++;
   }       
 }

 event void Timer0.fired(){
    if(! (call Monitor.isSending())){
	if(counter < (uint16_t)53602){          
           post SendPacketTask();
        }
    }
    //post SendPacketTask();
    call Timer0.startOneShot(13);  
 }
 
 event void Send.sendDone(message_t *p, error_t err){
    //call Timer0.startOneShot(8);  
 }

}



