/*------------------------------------------------------------------------+
 *School of Electrical Engineering/School of Technology and Health        +
 +  Master Program In Network Services and Systems                        +
 +	Master Thesis..Project                                            +
 +------------------------------------------------------------------------*	
 + author: Gonga, Antonio - gonga@kth.se				  +
 + Date created: January 12, 2009 02:10:45 AM                             +
 +------------------------------------------------------------------------*/

#include "ETXLinkLayer.h"

module ETXDataForwarderP{
  provides{
    	interface Init;
        interface Packet;
	interface DataSend;
	interface Receive[am_id_t id];
        interface Intercept[am_id_t id];                
  }
  uses{
        interface Leds;
        interface AMPacket;
	interface SplitControl;
	interface AMSend as Forward;
	interface AMSend as SubSend;	
	interface Receive as RecvData;
	interface Packet as SubPacket;

	interface Routing;
	interface Monitor;
	interface RouteControl;
	
	interface Timer<TMilli> as MonitorTimer;    
	
	interface LinkLayer;
  }
}
implementation{

     enum{
	PKT_RET_CTR   = 3,
     };

     message_t  pmsg;
     uint8_t    msgLengths[BUFR_QUEUE_LEN];
     message_t  QueueBufs[BUFR_QUEUE_LEN];       //Forward Buffer
     message_t  * ONE_NOK Queue[BUFR_QUEUE_LEN];

     uint8_t    queueIn, queueOut;
     bool       radioBusy, radioFull, sending;

     uint8_t failCtr; 
     uint8_t maxRetrans;

     //Function Prototypes   
     void initialize();
     message_t* forward_packet(message_t* p, uint8_t);
     routing_hdr_t* getHeader(message_t* p);

     //Task Prototypes     
     task void ForwardPacketsTask();     

   /*-------------------------------------------------------------------------------------------*/
     routing_hdr_t* getHeader(message_t* p){
	return (routing_hdr_t*)call SubPacket.getPayload(p, ROUTING_HDR_LEN);	
     }

   /*-------------------------------------------------------------------------------------------*/
   void initialize(){
       uint8_t i;

        for (i = 0; i < BUFR_QUEUE_LEN; i++){
            Queue[i]      = &QueueBufs[i];
	    msgLengths[i] = 0;
        }
        queueIn = queueOut = 0;
        radioBusy = FALSE;
        radioFull = FALSE;
        sending   = FALSE;

	failCtr   = maxRetrans = 0;
     }

   /*-------------------------------------------------------------------------------------------*/
     command error_t Init.init(){
	initialize();
	call SplitControl.start();
	call MonitorTimer.startPeriodic(7);
	return SUCCESS;
     }

   /*-------------------------------------------------------------------------------------------*/
     event void MonitorTimer.fired(){
       if(call Monitor.isAuto()){
       	  if(call Monitor.isSending()){
             call Monitor.sendMonitor();
          }
       }
    }
   /*-------------------------------------------------------------------------------------------*/
     event void SplitControl.startDone(error_t err){
	if(err != SUCCESS)
	  call SplitControl.start();
     }

     event void SplitControl.stopDone(error_t err){
	if(err != SUCCESS)
	    return;
     }

   /*-------------------------------------------------------------------------------------------*/
    task void relayPacketTask(){
      uint16_t dest;
      message_t *p;
         
         p = Queue[queueOut];
	 maxRetrans = PKT_RET_CTR;
	 dest = call AMPacket.destination(p);
	 	
	 if(call Forward.send(dest, Queue[queueOut], msgLengths[queueOut]) == SUCCESS){
		;
	 }
    }      

   /*-------------------------------------------------------------------------------------------*/
    task void ForwardPacketsTask(){	
	 atomic {
	    if (queueIn == queueOut && !radioFull) {
        	radioBusy = FALSE;
        	return;
      	    }
    	 }        
		  		   
	 if(call Routing.getNextHop(Queue[queueOut], 0) == SUCCESS){ //no route... discard packet	     
	     post relayPacketTask();	    	    	 	    
	 }else{
	    post ForwardPacketsTask();
	    radioBusy = FALSE;
	 }
    }   

   /*-------------------------------------------------------------------------------------------*/   
    event void Forward.sendDone(message_t *p, error_t err){
	
         if(p == Queue[queueOut]){
	     //call LinkLayer.dataSuccess(call Routing.getParent());
	     atomic{	       
	         queueOut = (queueOut + 1)%BUFR_QUEUE_LEN;         	    
	         if(radioFull)
        	    radioFull = FALSE;          	
	     }
	 }else{
	      if(--maxRetrans > 0){
		 message_t *retMsg = Queue[queueOut];

		 //call LinkLayer.dataFailed(call Routing.getParent());

		 call Routing.getNextHop(retMsg, 2);
		 post relayPacketTask();
		 return;
	      }else{
		   //skip it,; go to the next packet...
		   atomic{
			maxRetrans = 0;
			queueOut = (queueOut + 1)%BUFR_QUEUE_LEN;
			if(radioFull)
        	    	   radioFull = FALSE; 
		   }
	      }	
	 }  
	
	 maxRetrans = 0;
         post ForwardPacketsTask();
    }

   /*-------------------------------------------------------------------------------------------*/
    message_t* forward_packet(message_t* p, uint8_t len){
      message_t* ret = p;
       	
	atomic{
	    if(!radioFull){
		ret = Queue[queueIn];
		Queue[queueIn] = p;
		msgLengths[queueIn] = len;
		
                queueIn = (queueIn + 1)%BUFR_QUEUE_LEN;
		
		if(queueIn == queueOut)
		    radioFull = TRUE;

		if(!radioBusy){
		    post ForwardPacketsTask();
		    radioBusy = TRUE;
		}
	   }else{
		;//find somehow to resend packet...cannot be lost
	   }
	}
	
      return ret;
    }

   /*-------------------------------------------------------------------------------------------*/
    event message_t* RecvData.receive(message_t* ONE p, void* COUNT_NOK(len) payload, uint8_t len){
	uint8_t id = call AMPacket.type(p);
	uint16_t addr = call AMPacket.destination(p);

	  /*---..broadcast packets and packets not destinated to the node are discarded...*/
	if(addr == TOS_BCAST_ADDR || addr != call AMPacket.address() /* || id != AM_ETXDATA_MSG*/){
	    return p;
	}	
	
	 /*If the packet has reached the root, don't forward*/
        if(call Routing.getRootNode()){	   
	   return signal Receive.receive[id](p, payload, len);
	}else if(signal Intercept.forward[id](p, payload, len)){
	    call Leds.led2Toggle();
	    return forward_packet(p, len);
	}else{
	    return p;
	}		
    }

   /*-------------------------------------------------------------------------------------------*/
    command void* Packet.getPayload(message_t *p, uint8_t len){
	void* payload = call SubPacket.getPayload(p, len);
	if(payload != NULL){
	   payload += ROUTING_HDR_LEN;
	}
	return payload;
    }

   /*-------------------------------------------------------------------------------------------*/
    command uint8_t Packet.payloadLength(message_t *p){
	return (call SubPacket.payloadLength(p) - ROUTING_HDR_LEN);    
    }

   /*-------------------------------------------------------------------------------------------*/
    command void Packet.setPayloadLength(message_t *p, uint8_t len){
	return call SubPacket.setPayloadLength(p, len + ROUTING_HDR_LEN);
    }

    /*-------------------------------------------------------------------------------------------*/
    command uint8_t Packet.maxPayloadLength(){
	return (call SubPacket.maxPayloadLength() - ROUTING_HDR_LEN);
    }

    /*-------------------------------------------------------------------------------------------*/  
    command void Packet.clear(message_t *p){}
   

    //DATASEND
    /*-------------------------------------------------------------------------------------------*/
     command error_t DataSend.send(message_t *p, uint8_t len){
	len += ROUTING_HDR_LEN;

	if(len > call SubPacket.maxPayloadLength() || call Routing.getRootNode()){
	   return FAIL;
	}
        
        if(sending == TRUE){
	   return EBUSY;
	}        

        /*if(call Monitor.isSending()){	   
	   call Routing.setHeaderType(p, TYPE_MONITOR);
	   call Monitor.set(FALSE);
        }else{
	    call Routing.setHeader(p);
        }*/  
	call Routing.setHeader(p);             

        if(call Routing.getNextHop(p, 0) != SUCCESS){
	   return FAIL;
	}
   
	call Monitor.update(len);	//counts the number of bytes

	failCtr = PKT_RET_CTR;
        if(call SubSend.send(call Routing.getParent(), p, len) != SUCCESS){	   
	   sending = TRUE;
	   return FAIL;
	}
	 
        sending = TRUE;       

	return SUCCESS;
    }
    
   command error_t DataSend.sendVoid(void* data, uint8_t len){
       return call DataSend.send(&pmsg, len);
   }

  command void* DataSend.getVoidPayload(uint8_t len){
      return call Packet.getPayload(&pmsg, len);
  }
     /*-------------------------------------------------------------------------------------------*/
    event void SubSend.sendDone(message_t *p, error_t err){ 
	if(err == SUCCESS){
	     failCtr = 0;
	     sending = FALSE;
	     signal DataSend.sendDone(p, SUCCESS);	
	     return;
	}else{
	    if((--failCtr) > 0){
	        call Routing.getNextHop(p, 1);
	     	if(call SubSend.send(call AMPacket.destination(p), p, call SubPacket.payloadLength(p)) == SUCCESS){		
			;
	     	}             
	        return; //??               
	     }else if(failCtr <= 0){
	         failCtr = 0;
		 sending = FALSE;
	         signal DataSend.sendDone(p, FAIL);
	        return;
             }
	}               	
    }
    /*-------------------------------------------------------------------------------------------*/  
    command void* DataSend.getPayload(message_t *p, uint8_t len){
	return call Packet.getPayload(p, len);
    }

    command void DataSend.setPacketType(message_t *p, uint8_t type){
	routing_hdr_t *hdr = getHeader(p);
	hdr->type = type;
    }
   /*-------------------------------------------------------------------------------------------*/
    /*command uint8_t DataSend.payloadLength(message_t *p){
	return call Packet.payloadLength(p);
    }
    */
   /*-------------------------------------------------------------------------------------------*/
    command uint8_t DataSend.maxPayloadLength() {
        return call Packet.maxPayloadLength();
    }

   /*-------------------------------------------------------------------------------------------*/
    command error_t DataSend.cancel(message_t* m) {
      return FAIL;
    }
  
   /*-------------------------------------------------------------------------------------------+			
    +												+
    +-------------------------------------------------------------------------------------------*/

   default event void DataSend.sendDone(message_t* p, error_t err){
   }    

   default event bool Intercept.forward[am_id_t id](message_t *p, void* payload, uint8_t len){
	return TRUE;
   }

   default event message_t* Receive.receive[am_id_t id](message_t* p, void* payload, uint8_t len){
	return p;
   }
}

