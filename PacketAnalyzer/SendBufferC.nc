
#define AM_UART_ID 10
#define AM_UART_RECEIVE_ID 20

configuration SendBufferC{
 provides interface SendBuffer;
}implementation{ 
  components SendBufferP; 

  SendBuffer = SendBufferP.SendBuffer;

  components CC2420PacketC;
  SendBufferP.CC2420PacketBody -> CC2420PacketC;

  components SerialActiveMessageC as Serial;

  components new SerialAMSenderC(AM_UART_ID) as SerialAM1;
  components new SerialAMReceiverC(AM_UART_RECEIVE_ID) as SerialAM2;

  SendBufferP.SerialControl -> Serial;

  SendBufferP.uartSend      -> SerialAM1.AMSend;
  SendBufferP.Packet        -> SerialAM1.Packet;  

  SendBufferP.uartReceive   -> SerialAM2.Receive;  
  SendBufferP.uartPacket    -> SerialAM2.Packet;

  components LedsC;
  SendBufferP.Leds -> LedsC;
}
