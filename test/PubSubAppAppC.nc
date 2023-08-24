#define NEW_PRINTF_SEMANTICS
#include "PubSubApp.h"

configuration PubSubAppAppC {}
implementation {
  components MainC, PubSubAppC as App, LedsC;
  components SerialPrintfC;
  components SerialStartC;
  components new AMSenderC(AM_RADIO_COUNT_MSG);
  components new AMReceiverC(AM_RADIO_COUNT_MSG);
  components new TimerMilliC() as Timer0;
  components new TimerMilliC() as Timer1;
  components new TimerMilliC() as Timer2;
  components new TimerMilliC() as Timer3;
  components new TimerMilliC() as Timer4;
  components new TimerMilliC() as Timer5;
  components ActiveMessageC;
  components RandomC;
  
  App.Boot -> MainC.Boot;
  
  App.Receive -> AMReceiverC;
  App.AMSend -> AMSenderC;
  App.AMControl -> ActiveMessageC;
  App.Leds -> LedsC;
  App.MilliTimer0 -> Timer0;
  App.MilliTimer1 -> Timer1;
  App.MilliTimer2 -> Timer2;
  App.MilliTimer3 -> Timer3;
  App.MilliTimer4 -> Timer4;
  App.MilliTimer4 -> Timer5;
  App.Packet -> AMSenderC;
  App.Random -> RandomC;
}


