/*KTH - The Royal Institute of Technology
 +School of Electrical Engineering/School of Technology and Health
 +Master Program in Network Services and Systems
 +@author: Gonga, António Oliveira - gonga@kth.se
 +Date: STOCKHOLM, Tue, April 15, 2008  16:27:45'
 +file: PacketAnalizerC.nc
 +++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
/*NOTICE: As I am a supporter of open source Software, I do
 *autorize anyone interested to inprove this Application to
 *send me a notification. I do hope that this application
 *will solve many of your problems.
 +<A. Gonga
 +++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

configuration PacketAnalyzerC{
}implementation{

  components MainC, PacketAnalyzerP;
  components ActiveMessageC as Radio;
  components new TimerMilliC() as TimerC;
  components CC2420PacketC;
  components CC2420ControlC;

  components SendBufferC;
  PacketAnalyzerP.SendBuffer -> SendBufferC;

  components LedsC;
  PacketAnalyzerP.Leds -> LedsC;
  PacketAnalyzerP.TMilliSec -> TimerC;

  MainC.Boot <- PacketAnalyzerP;

  PacketAnalyzerP.CC2420Config -> CC2420ControlC; //channel modification

  PacketAnalyzerP.RadioControl -> Radio;
  PacketAnalyzerP.RadioSnoop   -> Radio.Snoop;
  PacketAnalyzerP.RadioReceive -> Radio.Receive;
  PacketAnalyzerP.CC2420PacketBody -> CC2420PacketC;
}
