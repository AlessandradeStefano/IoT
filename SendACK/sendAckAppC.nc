/**
 *  Configuration file for wiring of sendAckC module to other common 
 *  components needed for proper functioning
 *
 *  @author Luca Pietro Borsani
 */

#include "sendAck.h"

configuration sendAckAppC {}

implementation {

  components MainC, RandomC , sendAckC as App;
  components new AMSenderC(AM_MY_MSG);
  components new AMReceiverC(AM_MY_MSG);
  components ActiveMessageC;
  components new TimerMilliC() as Timer0;
  components new TimerMilliC() as Timer1;
  components new TimerMilliC() as Timer2;
  components SerialActiveMessageC as AM;
  components new FakeSensorC();

  //Boot interface
  App.Boot -> MainC.Boot;

  //Send and Receive interfaces
  App.Receive -> AMReceiverC;
  App.AMSend -> AMSenderC;
  App.SerialSplitControl -> AM;
  App.AMSerialSend -> AM.AMSend[AM_SERIAL_MSG];


  App.Random -> RandomC;
  RandomC <- MainC.SoftwareInit;

  //Radio Control
  App.SplitControl -> ActiveMessageC;

  //Interfaces to access package fields
  App.SerialPacket -> AM;
  App.AMPacket -> AMSenderC;
  App.Packet -> AMSenderC;
  App.PacketAcknowledgements->ActiveMessageC;

  //Timer interface
  App.MilliTimer -> Timer0;
  App.MissingTimer -> Timer1;
  App.SendTimer -> Timer2;
  //Fake Sensor read
  App.Read -> FakeSensorC;

}

