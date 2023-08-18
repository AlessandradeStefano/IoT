
#include "Topology.h"

configuration routingAppC {}

implementation {


/****** COMPONENTS *****/
components MainC, RoutingC as App;

components new AMSenderC(AM_MSG);
components new AMReceiverC(AM_MSG);

/****** INTERFACES *****/
//Boot interface
App.Boot -> MainC.Boot;

/****** Wire the other interfaces down here *****/
//Send and Receive interfaces
App.Receive -> AMReceiverC;
App.AMPacket -> AMSenderC;
App.AMSend -> AMSenderC;
App.PacketAcknowledgements -> AMSenderC.Acks;

//Radio Control
App.AMControl -> ActiveMessageC;

//Interfaces to access package fields
App.Packet -> AMSenderC;

//Timer interface



}