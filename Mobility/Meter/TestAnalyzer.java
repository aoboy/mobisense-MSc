   import net.tinyos.packet.*;
   import net.tinyos.message.*; 
   import net.tinyos.util.*;
   import java.util.*;
   import java.io.*;


public class TestAnalyzer{
  private String filename ="packets.txt";
  private OutputStreamWriter osw;

 
  public TestAnalyzer(){
    try{
         osw = new OutputStreamWriter(new FileOutputStream(filename));
    }catch(Exception ex){  ex.printStackTrace();  }
   
    Thread t = new Thread(new DispPacket());
    t.start(); 
       
  }
 
  class DispPacket implements Runnable{
        private PacketSource reader;        

  	public void printByte(OutputStreamWriter p, int b) {
            try{
        	 String bs = Integer.toHexString(b & 0xff).toUpperCase();
        	 if (b >=0 && b < 16)
            	    p.write("0");
        	 p.write(bs + " ");
            }catch(Exception ex){ ex.printStackTrace();}
  	}

  	public void printPacket(OutputStreamWriter p, byte[] packet, int from, int count) {
        	for (int i = from; i < count; i++)
            		printByte(p, packet[i]);
                try{
		    osw.write("\n");
                    osw.flush();
                 }catch(Exception ex){ ex.printStackTrace();}
  	}
      
        public void run(){
	    reader = BuildSource.makePacketSource();
            if(reader != null){
                ReadPacketInBytes();
            }else {System.out.println("UNABLE TO OPEN SERIAL PORT");
            }
	   System.exit(1);
	}
	
        public void ReadPacketInBytes(){
	  int npkts=0;
          int n_mpkts=0;
          try{
	       reader.open(PrintStreamMessenger.err);
	       for(;;){
                   byte[] packet = reader.readPacket();
		   int n = getnReceivedPkts(packet);
		   if(n>=100){
		     npkts++;
		      if(packet[8] == 1){
			n_mpkts++;
		      }
		      System.out.println("Total Sent:"+(n-99)+" - Received: "+npkts+" PktLoss: "+(n-npkts-99)+" -MPkts:"+(n_mpkts-1));
		   }
		   if((n-99) > 60000){
			break;
		   }		                 
	       }
          }catch(Exception ex){ ex.printStackTrace();}
        }
	
	public int getnReceivedPkts(byte[] b){
	  int n_recvd=0, n=11;
	   for(int i= 10, exp=0; i <=11; i++, exp++){		
		n_recvd += (int)Math.pow(256, 11-i)*(b[i]&0xff);
	   } 
	  return n_recvd;
  	}

  }

  public static void main(String[] args){
	
        TestAnalyzer test = new TestAnalyzer();	
  }
}
