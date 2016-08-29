/*KTH - The Royal Institute of Technology
 +School of Electrical Engineering/School of Technology and Health
 +Master Program in Network Services and Systems
 +@author: Gonga, António Oliveira - gonga@kth.se
 +Date: STOCKHOLM, Tue, April 15, 2008  16:27:45'
 +Last Modified: Dec 31, 2008 [05h24' Riga - Latvia]
 +file: PacketAnalizerP.nc
 +++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
/*NOTICE: As I am a supporter of open source Software, I do
 *autorize anyone interested to inprove this Application to
 *send me a notification. I hope that this application
 *will solve many of your problems.
 +<A. Gonga>
 +++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
//#include "AM.h"
#include "Sniffer.h"

module PacketAnalyzerP{
  uses{
    interface Boot;                             
    interface SplitControl as RadioControl;
    interface Receive as RadioReceive[am_id_t id];
    interface Receive as RadioSnoop[am_id_t id];
    interface Timer<TMilli> as TMilliSec;
    interface CC2420PacketBody;

    interface SendBuffer;     /*send a buffer of size UQLENGTH*/
    interface Leds;       

    interface CC2420Config;
  }
}implementation{
   enum{
     NBUFFERS    = 4,      /*number of buffers*/
     DATA_LENGTH = 28,     /*TOSH_DATA_LENGTH*/
     UQLENGTH    = 40,     /*input queue size*/
     TIMER_DELAY = 1024,   /*timer period*/     
  };

  enum{
    ALLOW_ALL     = 0,
    ALLOW_SRC     = 1,
    ALLOW_DST     = 2,
    ALLOW_SRC_DST = 3,
    PKT_SMPL_EN   = 120,
    PKT_SMPL_DIS  = 121,
  };

  Timestamp_t inputQueue0[UQLENGTH];    /*input queue 1*/
  Timestamp_t inputQueue1[UQLENGTH];    /*input queue 2*/
  Timestamp_t inputQueue2[UQLENGTH];    /*input queue 3*/
  Timestamp_t inputQueue3[UQLENGTH];    /*input queue 4*/


 // FilterMsg filter;

  uint8_t channelNr;;
  uint8_t filterVal;
  uint16_t src_addr;
  uint16_t dst_addr;


  bool samplingActive;
  uint16_t pktCounter;
  uint16_t samplingPeriod;

  uint8_t maxRetries;

  uint8_t uartIn;        //input queue index
  uint8_t bcounter;      //buffer counter
  norace uint32_t ctime; //current time

  task void uartSendTask(); /* to the uart*/

  task void changeRadioChannelTask();

  static inline void send_to_uart(cc2420_header_t*, void*,  uint32_t*, uint8_t); 

  /*Initializes the application
   +input params: none(void)
   +returns: none(void)
   +++++++++++++++++++++++++++++++++++++++++++*/
  void initialize(){
    uint8_t k;
    atomic{
       for(k = 0; k < UQLENGTH; k++){
          memset(&inputQueue0[k], (uint8_t)'\0', sizeof(Timestamp_t));
          memset(&inputQueue1[k], (uint8_t)'\0', sizeof(Timestamp_t));
          memset(&inputQueue2[k], (uint8_t)'\0', sizeof(Timestamp_t));          
          memset(&inputQueue3[k], (uint8_t)'\0', sizeof(Timestamp_t));          
       }
       uartIn = 0;
    }

    src_addr   = dst_addr  = 0;
    filterVal = channelNr = 0;

    samplingActive = FALSE;
    pktCounter     = 0;
    samplingPeriod = 0;

    ctime = 0;    
    call SendBuffer.init();
    call RadioControl.start();    
    call TMilliSec.startPeriodic(TIMER_DELAY);
  }

  /*Boots the application
   +input params/returns : none(void)
   ++++++++++++++++++++++++++++*/
  event void Boot.booted() {
    initialize();
  }

  /* starts the Radio, 
   +@params: error the status code
   +@return: none(void)
   ++++++++++++++++++++++++++++++++++++++++++++++++++++*/
  event void RadioControl.startDone(error_t error) {
    if (error == SUCCESS) {
        ;
    }else{
	call RadioControl.start();
    }
  }
  
  /*stops the Radio, 
   +@params: error the status code
   +@return: none(void)
   ++++++++++++++++++++++++++++++++++++++++++++++++++++*/
  event void RadioControl.stopDone(error_t error) {}

  /*periodic timer, fires each 1 second
   +@param/return: none
   +----------------------------------------+*/
  event void TMilliSec.fired(){
  }
  

  /*signaled when an incoming message has been received from the radio interface
   +@param msg : the incoming message
   +@param payload : the message payload
   +@len : the message payload length
   +@returns: the buffer to the next packet to be received
   ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
  event message_t *RadioSnoop.receive[am_id_t id](message_t *p, void *payload, uint8_t len) {

      cc2420_header_t *hdr1 = call CC2420PacketBody.getHeader(p);
      
         atomic{  
		ctime = call TMilliSec.getNow();
	 }
         
	 if(samplingActive){

             pktCounter = pktCounter+1;

	     if(pktCounter < samplingPeriod){
		   return p; 
	     }else{
		 pktCounter = 0;
	     }
         }

	 if(filterVal == ALLOW_ALL /*|| filter.val > ALLOW_SRC_DST*/){
	    send_to_uart(hdr1, payload,  &ctime, len);				
	 }else{	 
	 	if((filterVal== ALLOW_DST) && (dst_addr == hdr1->dest)){		
            		send_to_uart(hdr1, payload,  &ctime, len);				
		}else if((filterVal== ALLOW_SRC)  && (src_addr == hdr1->src)){
            		send_to_uart(hdr1, payload,  &ctime, len);				
	 	}else if((filterVal==ALLOW_SRC_DST) && (dst_addr == hdr1->dest)  
				&& (src_addr == hdr1->src)){
            		send_to_uart(hdr1, payload,  &ctime, len);
	 	}
         }
     
    return p;
  }
  
  /*signaled when an incoming message has been received from the radio interface
   +@param msg : the incoming message
   +@param payload : the message payload
   +@len : the message payload length
   +@returns: the buffer to the next packet to be received
   ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
  event message_t *RadioReceive.receive[am_id_t id](message_t *p, void *payload, uint8_t len) {
      cc2420_header_t *hdr1 = call CC2420PacketBody.getHeader(p);
      
         atomic{  
		ctime = call TMilliSec.getNow();
	 }

	 if(samplingActive){	     
              pktCounter = pktCounter+1;             

	     if(pktCounter < samplingPeriod){
		   return p; 
	     }else{
		atomic pktCounter = 0;
	     }
         }

	 if(filterVal == ALLOW_ALL /*|| filter.val > ALLOW_SRC_DST*/){
	    send_to_uart(hdr1, payload,  &ctime, len);				
	 }else{	 
	 	if((filterVal==ALLOW_DST) && (dst_addr == hdr1->dest)){		
            		send_to_uart(hdr1, payload,  &ctime, len);				
		}else if((filterVal== ALLOW_SRC)  && (src_addr == hdr1->src)){
            		send_to_uart(hdr1, payload,  &ctime, len);				
	 	}else if((filterVal==ALLOW_SRC_DST) && (dst_addr == hdr1->dest)  
				&& (src_addr == hdr1->src)){
            		send_to_uart(hdr1, payload,  &ctime, len);
	 	}
         }
     
    return p;
  }

  /*schedules and fills the input queues, so that they can be sent to the uart interface
   +@param header: the header of the received message
   +@param payload: the message payload
   +@param time: the time when the message was received
   +@param len: the message payload length
   +@returns: none(void)
   ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
  static inline void send_to_uart(cc2420_header_t *hdr, void* payload, uint32_t *time, uint8_t len){    
    atomic{
	   if(len > 28){
		len = 28;
	   }

	   if(bcounter == 0){ /*fills queue 1*/
                memcpy(&inputQueue0[uartIn].mac_hdr, hdr, MAC_HDR_LEN);
		inputQueue0[uartIn].len     = len; 
		inputQueue0[uartIn].time    = *time; 
                memcpy(&inputQueue0[uartIn].data, payload, len);
           }else if(bcounter == 1){ /*fills queue 1*/
                memcpy(&inputQueue1[uartIn].mac_hdr, hdr, MAC_HDR_LEN);
		inputQueue1[uartIn].len     = len; 
		inputQueue1[uartIn].time    = *time; 
                memcpy(&inputQueue1[uartIn].data, payload, len);
           }else if(bcounter == 2){  /*fills queue 2*/
                memcpy(&inputQueue2[uartIn].mac_hdr, hdr, MAC_HDR_LEN);
		inputQueue2[uartIn].len     = len; 
		inputQueue2[uartIn].time    = *time; 
                memcpy(&inputQueue2[uartIn].data, payload, len);
           } else if(bcounter == 3){
                memcpy(&inputQueue3[uartIn].mac_hdr, hdr, MAC_HDR_LEN);
		inputQueue3[uartIn].len  = len; 
		inputQueue3[uartIn].time = *time; 
                memcpy(&inputQueue3[uartIn].data, payload, len);
	   }
         uartIn = (uartIn + 1)%UQLENGTH;  /*increment the counter*/
         if(uartIn == 0){
	   bcounter = (bcounter + 1) % NBUFFERS; /*current buffer = next empty buffer*/
           post uartSendTask(); /*if the queue is full send to the uart*/
         }
    }

  }  

 /*send a queue using the SendBuffer interface
  +returns: none(void)
  +++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
  task void uartSendTask(){
    if(bcounter == 0){
	call SendBuffer.send(inputQueue3, (uint8_t)UQLENGTH);
    }else if(bcounter == 1){
	call SendBuffer.send(inputQueue0, (uint8_t)UQLENGTH);
    }else if(bcounter == 2){
	call SendBuffer.send(inputQueue1, (uint8_t)UQLENGTH);
    } else if(bcounter == 3){	
	call SendBuffer.send(inputQueue2, (uint8_t)UQLENGTH);
    }
  }
 /*signaled when a queue/buffer has been successfully or not
  +successfully sent. The <err> param speficies the error 
  +or status code
  ++++++++++++++++++++++++++++++++++++++++++*/
 event void SendBuffer.sendDone(error_t err){
    if(err == SUCCESS)
	call Leds.led2Toggle();
    else 
        call Leds.led0Toggle();
 }

  /* FILTER IMPLEMENTATION
   +
   ++++++++++++++++++++++++++++++++++++++++++++++++*/
 event message_t* SendBuffer.queryReceive(message_t *p, void* payload, uint8_t len){
    FilterMsg *my_filter;
     atomic{
	my_filter = (FilterMsg*)(call SendBuffer.getQueryMsg(p));

        atomic
         {
	    if(my_filter->val <= ALLOW_SRC_DST){
	     	filterVal = my_filter->val;
	     	src_addr  = my_filter->src_addr;
   	     	dst_addr  = my_filter->dst_addr;	
		call Leds.led0Toggle();
             }else if(my_filter->val == PKT_SMPL_EN){
		 samplingActive = TRUE;
	     	 samplingPeriod = my_filter->src_addr;
	     	 call Leds.led1Toggle();
	     }else if(my_filter->val == PKT_SMPL_DIS){		
		 samplingActive = FALSE;
	         samplingPeriod = 0;
	         call Leds.led1Toggle();
	     }
         }
        
	if(my_filter->val > ALLOW_SRC_DST && my_filter->src_addr == 0 && my_filter->dst_addr == 0){
	  if(my_filter->val >= 11 && my_filter->val <= 26){
		call Leds.led0Toggle();
	  	channelNr = my_filter->val;
	  	post changeRadioChannelTask();
	  }
	}
     } 
	
     return p;
  }  

  task void changeRadioChannelTask(){
     maxRetries = 3;
  
     call CC2420Config.setChannel(channelNr);     

     if(call CC2420Config.sync() == SUCCESS){		
       call Leds.led1Toggle();
     }     
  }

  event void CC2420Config.syncDone(error_t err)
  {
	if(err != SUCCESS && (--maxRetries > 0)){
	   call CC2420Config.setChannel(channelNr);
	   if(call CC2420Config.sync() == SUCCESS){
		call Leds.led1Toggle();
	   }
	}else{
	   maxRetries = 0;
	}
  }
 
}
