/*------------------------------------------------------------------------+
 *School of Electrical Engineering/School of Technology and Health        +
 +  Master Program In Network Services and Systems                        +
 +	Master Thesis..Project                                            +
 +------------------------------------------------------------------------*	
 + author: Gonga, Antonio - gonga@kth.se				  +
 + Date created: January 12, 2009 15:50:45 PM                             +
 +------------------------------------------------------------------------*/

/*
 FileName: RootNodeP.nc
*/


module RootNodeP{

  uses{
      interface Boot;
      interface Routing;
      interface NodeRole;
      interface Init as InitData;
      interface Receive[am_id_t id]; 

      interface Leds;
      interface SplitControl as SerialControl;
      interface AMSend as SerialSend;   
  }
}
implementation{

 enum{
   UART_BUFFER_LEN = 12
 };

 uint8_t    msgLengths[UART_BUFFER_LEN];
 message_t  uartQueueBufs[UART_BUFFER_LEN];
 message_t  * ONE_NOK uartQueue[UART_BUFFER_LEN];

 uint8_t uartIn, uartOut; 
 bool uartFull, uartBusy;
 
 task void sendToUartTask();
 message_t* ONE sendToUart(message_t* ONE msg, void* payload, uint8_t len);

 static void Initialize(){
   uint8_t k;
   for(k = 0; k < UART_BUFFER_LEN; k++){
        msgLengths[k] = 0;
	uartQueue[k]  = &uartQueueBufs[k];
   }
      
   uartIn = uartOut = 0;
   uartFull = uartBusy = FALSE;
 }

 event void Boot.booted(){
    call Routing.init();
    call InitData.init();    
    call Routing.setRootNode();
    call NodeRole.setNodeAsRouter();
    Initialize();
    call SerialControl.start();
 }

 event void SerialControl.startDone(error_t err){
    if(err != SUCCESS)
	call SerialControl.start();
 }

 event void SerialControl.stopDone(error_t err){   
 }

 task void sendToUartTask(){
  uint8_t len;

    atomic {
      if (uartIn == uartOut && !uartFull) {
        uartBusy = FALSE;
        return;
      }
    }

    len = msgLengths[uartOut];

    if (call SerialSend.send(0xffff, uartQueue[uartOut], len) == SUCCESS) {
         ;
    }
    else {
	//call Leds.led0Toggle();     
        post sendToUartTask();
    }
 }

 event void SerialSend.sendDone(message_t* p, error_t err){
    if (err == SUCCESS){
      atomic
        if (p == uartQueue[uartOut]){

            if (++uartOut >= UART_BUFFER_LEN)
              uartOut = 0;
            if (uartFull)
              uartFull = FALSE;
        }
    }

    post sendToUartTask();
 }

 message_t* ONE sendToUart(message_t* ONE msg, void* payload, uint8_t len){
    message_t *ret = msg;
	atomic{
	   if( !uartFull){
		ret = uartQueue[uartIn];
          	uartQueue[uartIn]  = msg;
	        msgLengths[uartIn] = len;

          	uartIn = (uartIn + 1) % UART_BUFFER_LEN;

	        if (uartIn == uartOut)
            	    uartFull = TRUE;

                if (!uartBusy){
                  post sendToUartTask();
                  uartBusy = TRUE;
                }
           }	
        }
   return ret;
 }
  
 event message_t* Receive.receive[am_id_t id](message_t *p, void* payload, uint8_t len){
       
    call Leds.led2Toggle();
    return sendToUart(p, payload, len);
 }

}
