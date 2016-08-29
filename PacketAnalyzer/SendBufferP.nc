
/*KTH - The Royal Institute of Technology
 +School of Electrical Engineering/School of Technology and Health
 +Master Program in Network Services and Systems
 +@author: Gonga, António Oliveira - gonga@kth.se
 +Date: STOCKHOLM, Tue, April 15, 2008  16:27:45'
 +file: SendBufferP.nc
 +++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
/*NOTICE: As I am a supporter of open source Software, I do
 *autorize anyone interested to inprove this Application to
 *send me a notification. I do hope that this application
 *will solve many of your problems.
 +<A. Gonga
 +++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

//#include "Serial.h"
//#include "message.h"
//#include "CC2420.h"
#include "Sniffer.h"

module SendBufferP{
   provides{
	interface SendBuffer;
   }
   uses{
	interface AMSend as uartSend;
	interface Packet;
	interface Leds;
	interface CC2420PacketBody;
	interface AMPacket;

	interface SplitControl as SerialControl;
	
	interface Receive as uartReceive;
        interface Packet  as uartPacket;
   }
}implementation{
 
   enum{
      OFFSET = MAC_HEADER_SIZE + MAC_FOOTER_SIZE,
   };

   message_t msg;

   Timestamp_t *buf_starts, *buf_ends;

   uint8_t bufLength;
   uint8_t msgLength;
   uint8_t retransCtr;
   uint8_t index;

   command void SendBuffer.init(){
      atomic{
           index = bufLength = retransCtr = 0;
      }
      call SerialControl.start();
   }

   command uint8_t SendBuffer.plength(message_t* p){
     return (call CC2420PacketBody.getHeader(p))->length - OFFSET; 
   }

   event void SerialControl.startDone(error_t er){
      if(er != SUCCESS)
	call SerialControl.start();
   }

   event void SerialControl.stopDone(error_t er){}

    task void uartSendTask(){
      if(call uartSend.send(0xffff, &msg, msgLength) != SUCCESS){
       ;
      }
    }


   task void sendBufferTask(){
     Timestamp_t *ts;
     void *payload;
     atomic{
	ts = &buf_starts[index];	
        payload =(Timestamp_t*) call Packet.getPayload(&msg, TOSH_DATA_LENGTH);
        if(ts->len < 28){
	  msgLength = MAC_HDR_LEN +5 + ts->len; 
	}else{
	  msgLength = sizeof(Timestamp_t); 
	}
        memcpy(payload, ts , msgLength);
     }
     retransCtr = 3;
     post uartSendTask();
   }

  void addDataBuffer(Timestamp_t *start, uint8_t len){
      buf_starts = start;
      buf_ends   = (start+len);
      index = 0;
  }

  command error_t SendBuffer.send(Timestamp_t* msgBuffer, uint8_t bLen){
     bufLength = bLen;
     addDataBuffer(msgBuffer, bLen);
     post sendBufferTask();
     return SUCCESS;
  }


  event message_t* uartReceive.receive(message_t* p_msg, void* payload, uint8_t len){
	return signal SendBuffer.queryReceive(p_msg, payload, len);
  }



 command FilterMsg* SendBuffer.getQueryMsg(message_t *p){
	return (FilterMsg*) call uartPacket.getPayload(p, sizeof(FilterMsg)); 
 }

  event void uartSend.sendDone(message_t *p, error_t err){
      if(p == &msg){
	 retransCtr = 0;
	 index = (index+1)%bufLength;
         if(index == 0){  /*index=0 ->buffer empty */
	   signal SendBuffer.sendDone(SUCCESS);
	   return;
         }
      }else{
	if(--retransCtr > 0){
          call Leds.led0Toggle(); 
	  post uartSendTask();
        }else{ 
	   ;
	   //signal SendBuffer.sendDone(FAIL);
	}
      }
      post sendBufferTask();
  }

  default event void SendBuffer.sendDone(error_t err){
	
  }

}
