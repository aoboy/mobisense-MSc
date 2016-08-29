#Makefile
#author: antonio gonga - gonga@kth.se
#date created: Tue, April 05, 2008
#date modified: Dec 28, 2008
#Stockholm, Sweden

COMPONENT=PacketAnalyzerC

BUILD_EXTRA_DEPS += FilterMsg.class
CLEAN_EXTRA = *.class *.nc~ *.txt FilterMsg.java *.o 


FilterMsg.class: $(wildcard *.java) FilterMsg.java
	javac FilterMsg.java


FilterMsg.java:
	mig java -target=$(PLATFORM) -java-classname=FilterMsg Sniffer.h FilterMsg -o $@




CFLAGS = -DCC2420_NO_ACKNOWLEDGEMENTS
CFLAGS += -DCC2420_NO_ADDRESS_RECOGNITION
CFLAGS += -DTOSH_DATA_LENGTH=0x2D
CFLAGS += -DLOW_POWER_LISTENING
CFLAGS += -I$(PacketAnalyzer)/SendBufferC

include $(MAKERULES)

