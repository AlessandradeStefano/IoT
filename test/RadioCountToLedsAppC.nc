#define NEW_PRINTF_SEMANTICS
#include <string.h>
#include "RadioCountToLeds.h"
#include "printf.h"

/**
 * Configuration for the RadioCountToLeds application. RadioCountToLeds 
 * maintains a 4Hz counter, broadcasting its value in an AM packet 
 * every time it gets updated. A RadioCountToLeds node that hears a counter 
 * displays the bottom three bits on its LEDs. This application is a useful 
 * test to show that basic AM communication and timers work.
 *
 * @author Philip Levis
 * @date   June 6 2005
 */

configuration RadioCountToLedsAppC {}
implementation {
  components MainC, RadioCountToLedsC as App, LedsC;
  components new AMSenderC(AM_RADIO_COUNT_MSG);
  components new AMReceiverC(AM_RADIO_COUNT_MSG);
  components new TimerMilliC() as Timer0;
  components new TimerMilliC() as Timer1;
  // components new TimerMilliC() as Timer2;
  components ActiveMessageC;
  components PrintfC;
  
  App.Boot -> MainC.Boot;
  
  App.Receive -> AMReceiverC;
  App.AMSend -> AMSenderC;
  App.AMControl -> ActiveMessageC;
  App.Leds -> LedsC;
  App.MilliTimer0 -> Timer0;
  App.MilliTimer1 -> Timer1;
  // App.MilliTimer2 -> Timer2;
  App.Packet -> AMSenderC;
}


