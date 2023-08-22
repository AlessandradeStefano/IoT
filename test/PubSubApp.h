#ifndef PRINTF_H
#define PRINTF_H

#ifndef NEW_PRINTF_SEMANTICS
#warning \
"                                  *************************** PRINTF SEMANTICS HAVE CHANGED! ********************************************* Make sure you now include the following two components in your top level application file: PrintfC and SerialStartC. To supress this warning in the future, #define the variable NEW_PRINTF_SEMANTICS. Take a look at the updated tutorial application under apps/tutorials/printf for an example. ************************************************************************************"
#endif

#ifndef PRINTF_BUFFER_SIZE
#define PRINTF_BUFFER_SIZE 250
#endif

#if PRINTF_BUFFER_SIZE > 255
  #define PrintfQueueC	BigQueueC
  #define PrintfQueue	BigQueue
#else
  #define PrintfQueueC	QueueC
  #define PrintfQueue	Queue
#endif

#if defined (_H_msp430hardware_h) || defined (_H_atmega128hardware_H)
  #include <stdio.h>
#else
#ifdef __M16C60HARDWARE_H__
  #include "m16c60_printf.h"
#else
  #include "generic_printf.h"
#endif
#endif
#undef putchar

#include "message.h"
int printfflush();

#ifndef PRINTF_MSG_LENGTH
#define PRINTF_MSG_LENGTH	28
#endif
typedef nx_struct printf_msg {
  nx_uint8_t buffer[PRINTF_MSG_LENGTH];
} printf_msg_t;

enum {
  AM_PRINTF_MSG = 100,
};

#endif //PRINTF_H

#ifndef PUB_SUB_APP_H
#define PUB_SUB_APP_H

typedef nx_struct radio_count_msg {
  nx_uint8_t messageType;
    nx_uint16_t sender_ID;
    nx_uint16_t destination;
    nx_uint8_t topic;
    nx_uint8_t payload;
} radio_count_msg_t;

    /*
    CONNECT = 0
    CONNACK = 1
    SUBSCRIBE = 2
    SUBACK = 3
    PUBLISH = 4
    ACK = 5
    */

enum {
  AM_RADIO_COUNT_MSG = 6,
};

#endif
