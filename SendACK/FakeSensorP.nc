/**
 *  Source file for implementation of module Middleware
 *  which provides the main logic for middleware message management
 *
 *  @author Luca Pietro Borsani
 */
 
generic module FakeSensorP() {

	provides interface Read<uint16_t>;
	
	uses interface Random;
	uses interface Timer<TMilli> as Timer0;

} implementation {

	//***************** Boot interface ********************//
	command error_t Read.read(){
		call Timer0.startOneShot( 10 );
		
		return SUCCESS;
	}

	//***************** Timer0 interface ********************//
	event void Timer0.fired() {
	
		uint16_t status = 3;
		int res =call Random.rand16();
		
		while(res > 10){ res = res/10; }
		if (res == 1 || res ==2 || res == 3 ) status = 0;
		else if (res == 4 || res ==5 || res == 6 ) status = 1;
		else if (res == 7 || res ==8 || res == 9 ) status = 2;
		// if (res == 10 ) status = 3;

		signal Read.readDone( SUCCESS , status );
	}
}
