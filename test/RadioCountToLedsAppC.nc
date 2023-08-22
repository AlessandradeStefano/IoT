#define NEW_PRINTF_SEMANTICS
#include "RadioCountToLeds.h"

configuration RadioCountToLedsAppC {}
implementation {
  components MainC, RadioCountToLedsC as App, LedsC;
  components PrintfC;
  components SerialStartC;
  components new AMSenderC(AM_RADIO_COUNT_MSG);
  components new AMReceiverC(AM_RADIO_COUNT_MSG);
  components new TimerMilliC() as Timer0;
  components new TimerMilliC() as Timer1;
  // components new TimerMilliC() as Timer2;
  components ActiveMessageC;

  
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


