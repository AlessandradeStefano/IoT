/**
 *  @author Luca Pietro Borsani
 */

#ifndef SENDACK_H
#define SENDACK_H

uint16_t counter=0;
  uint8_t rec_id[4];
  uint8_t idKey1[20];
  uint8_t idKey2[20];

typedef nx_struct serial_msg {
  nx_uint16_t sample_value;
} serial_msg_t;

typedef nx_struct my_msg {
	nx_uint8_t msg_type;
	nx_uint8_t key[20];
	nx_uint16_t address_id;
	nx_uint16_t xValue;
	nx_uint16_t yValue;
	nx_uint8_t statusValue;
} my_msg_t;


#define REQ 1
#define RESP 2 
#define REQACK 3

#define MISS 1
#define FALL 2

enum{
AM_MY_MSG = 6,
};
enum {
AM_SERIAL_MSG = 0x89,
};

#endif
