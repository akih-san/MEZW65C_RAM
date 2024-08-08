/*
 *  This source is for PIC18F47Q43 UART, I2C, SPI and TIMER0
 *
 * Base source code is maked by @hanyazou
 *  https://twitter.com/hanyazou
 *
 * Redesigned by Akihito Honda(Aki.h @akih_san)
 *  https://twitter.com/akih_san
 *  https://github.com/akih-san
 *
 *  Target: MEZW65C02_RAM
 *  Date. 2024.6.21
*/

#define BOARD_DEPENDENT_SOURCE

#include "../w65.h"

// console input buffers
#define U3B_SIZE 128
unsigned char rx_buf[U3B_SIZE];	//UART Rx ring buffer
unsigned int rx_wp, rx_rp, rx_cnt;

const unsigned char rom[] = {
	/* org $fff0 */
	0x38,			/* sec */
	0xFB,			/* xce */
	0xDB,			/* stp */

	0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,

	/* org $fffa */
	0xF2, 0xFF,	/* NMI Vector */
	0xF0, 0xFF,	/* Reset Vector */
	0xF2, 0xFF		/* IRQ/BRK Vector */
};

//TIMER0 seconds counter
static union {
    unsigned int w; //16 bits Address
    struct {
        unsigned char l; //Address low
        unsigned char h; //Address high
    };
} adjCnt;

TPB tim_pb;			// TIME device parameter block

//initialize TIMER0 & TIM device parameter block
void timer0_init(void) {
	adjCnt.w = TIMER0_INITC;	// set initial adjust timer counter
	tim_pb.TIM_DAYS = TIM20240101;
	tim_pb.TIM_MINS = 0;
	tim_pb.TIM_HRS = 0;
	tim_pb.TIM_SECS = 0;
	tim_pb.TIM_HSEC = 0;
}

//
// define interrupt
//
// Never called, logically
void __interrupt(irq(default),base(8)) Default_ISR(){}

////////////// UART3 Receive interrupt ////////////////////////////
// UART3 Rx interrupt
// PIR9 (bit0:U3RXIF bit1:U3TXIF)
/////////////////////////////////////////////////////////////////
void __interrupt(irq(U3RX),base(8)) URT3Rx_ISR(){

	unsigned char rx_data;

	rx_data = U3RXB;			// get rx data

	if (rx_cnt < U3B_SIZE) {
		rx_buf[rx_wp] = rx_data;
		rx_wp = (rx_wp + 1) & (U3B_SIZE - 1);
		rx_cnt++;
	}
}

static void wait_for_programmer()
{
    //
    // Give a chance to use PRC (RB6) and PRD (RB7) to PIC programer.
    //
    printf("\n\r");
    printf("wait for programmer ...\r");
    __delay_ms(200);
    printf("                       \r");

    printf("\n\r");
}

// UART3 Transmit
void putch(char c) {
    while(!U3TXIF);             // Wait or Tx interrupt flag set
    U3TXB = c;                  // Write data
}

// UART3 Recive
int getch(void) {
	char c;

	while(!rx_cnt);             // Wait for Rx interrupt flag set
	GIE = 0;                // Disable interrupt
	c = rx_buf[rx_rp];
	rx_rp = (rx_rp + 1) & ( U3B_SIZE - 1);
	rx_cnt--;
	GIE = 1;                // enable interrupt
    return c;               // Read data
}

void devio_init(void) {
	rx_wp = 0;
	rx_rp = 0;
	rx_cnt = 0;
    U3RXIE = 1;          // Receiver interrupt enable
}

static void reset_cpu()
{
	int i;
    union address_bus_u ab;

	// write cpu emulation mode operation program
	bus_hold_req();
	cpu_flg = 0;
	write_sram(0xfff0, (uint8_t *)rom, 16);
	read_sram(0xfff0, tmp_buf[0], 16);
	if (memcmp(rom, tmp_buf[0], 16) != 0) {
		bus_release_req();
		printf("Memory Write Error\r\n");
		while(1) {}
	}
	bus_release_req();

	LAT(W65_BE) = 1;        // reserse BUS
	LAT(W65_RESET) = 1;		// activate cpu

    __delay_ms(300);

	LAT(W65_BE) = 0;        // BUS Hi-z
	LAT(W65_RESET) = 0;		// cpu reset

    __delay_ms(300);

}


static void W65_common_sys_init()
{
    // System initialize
    OSCFRQ = 0x08;      // 64MHz internal OSC

	// Disable analog function
    ANSELA = 0x00;
    ANSELB = 0x00;
    ANSELC = 0x00;
    ANSELD = 0x00;
    ANSELE0 = 0;
    ANSELE1 = 0;
    ANSELE2 = 0;

    // /RESET output pin
	WPU(W65_RESET) = 0;		// disable pull up
	LAT(W65_RESET) = 0;		// Reset
    TRIS(W65_RESET) = 0;	// Set as output

	// /NMI (RA0)
	WPU(W65_NMI) = 0;		// disable pull up
	LAT(W65_NMI) = 1;		// disable NMI
	TRIS(W65_NMI) = 0;		// Set as output

	// SPI_SS
	WPU(SPI_SS) = 1;		// SPI_SS Week pull up
	LAT(SPI_SS) = 1;		// set SPI disable
	TRIS(SPI_SS) = 0;		// Set as onput

	// /BE output pin
	WPU(W65_BE) = 0;		// disable pull up
	LAT(W65_BE) = 0;        // BUS Hi-z
    TRIS(W65_BE) = 0;       // Set as output
	
	WPU(W65_CLK) = 0;		// disable week pull up
	LAT(W65_CLK) = 1;		// init CLK = 1
    TRIS(W65_CLK) = 0;		// set as output pin
	
	// IRQ (RA2)
	WPU(W65_IRQ) = 1;		// Week pull up
    TRIS(W65_IRQ) = 0;		// set as output pin
	LAT(W65_IRQ) = 1;		// IRQ=1

	// RDY (RA5)
	WPU(W65_RDY) = 0;		// disable pull up
	TRIS(W65_RDY) = 1;		// Set as input

	// DCK (RA1)
	WPU(W65_DCK) = 0;		// disable pull up
	LAT(W65_DCK) = 0;		// BANK REG CLK = 0
	TRIS(W65_DCK) = 1;		// Set as input

	// SRAM_R/(/W) (RA4)
	WPU(W65_RW) = 1;		// week pull up
	LAT(W65_RW) = 1;		// SRAM R/(/W) disactive
	TRIS(W65_RW) = 1;		// Set as input

	// Address bus A7-A0 pin
    WPU(W65_ADR_L) = 0xff;       // Week pull up
    LAT(W65_ADR_L) = 0x00;
    TRIS(W65_ADR_L) = 0xff;      // Set as input

	// Address bus A15-A8 pin
    WPU(W65_ADR_H) = 0xff;       // Week pull up
    LAT(W65_ADR_H) = 0x00;
    TRIS(W65_ADR_H) = 0xff;      // Set as input

	// Data bus D7-D0 pin
    WPU(W65_ADBUS) = 0xff;       // Week pull up
    LAT(W65_ADBUS) = 0x00;
    TRIS(W65_ADBUS) = 0xff;      // Set as input

	// UART3 initialize
    U3BRG = 416;			// 9600bps @ 64MHz
    U3RXEN = 1;				// Receiver enable
    U3TXEN = 1;				// Transmitter enable

    // UART3 Receiver
    TRISA7 = 1;				// RX set as input
    U3RXPPS = 0x07;			// RA7->UART3:RXD;

    // UART3 Transmitter
    LATA6 = 1;				// Default level
    TRISA6 = 0;				// TX set as output
    RA6PPS = 0x26;			// UART3:TXD -> RA6;

    U3ON = 1;				// Serial port enable

	// Clock(RA3) by NCO FDC mode

	NCO1INC = CLK_INC;		// set CLK frequency parameters
	NCO1CLK = 0x00;			// Clock source Fosc
	NCO1PFM = 0;			// FDC mode
	NCO1OUT = 1;			// NCO output enable

	NCO1EN = 1;				// NCO enable
	PPS(W65_CLK) = 0x3f;	// RA3 assign NCO1

    wait_for_programmer();

	reset_cpu();

	bus_hold_req();

}

void write_sram(uint32_t addr, uint8_t *buf, unsigned int len)
{
    union address_bus_u ab;
    unsigned int i;

	ab.w = addr;
	i = 0;

	TRIS(W65_ADBUS) = 0x00;					// Set as output
	if (cpu_flg) {
		// W65C816 native mode
		while( i < len ) {
		    LAT(W65_ADR_L) = ab.ll;
			LAT(W65_ADR_H) = ab.lh;

		    LAT(W65_ADBUS) = ab.hl;
			LAT(W65_DCK) = 1;			// Set Bank register
			LAT(W65_DCK) = 0;
			
	        LAT(W65_RW) = 0;					// activate /WE
	        LAT(W65_ADBUS) = ((uint8_t*)buf)[i];
	        LAT(W65_RW) = 1;					// deactivate /WE

			i++;
			ab.w++;
		}
	}
	else {
		// W65C02 mode
		while( i < len ) {
		    LAT(W65_ADR_L) = ab.ll;
			LAT(W65_ADR_H) = ab.lh;

	        LAT(W65_RW) = 0;					// activate /WE
	        LAT(W65_ADBUS) = ((uint8_t*)buf)[i];
	        LAT(W65_RW) = 1;					// deactivate /WE

			i++;
			ab.w++;
	    }
	}
	TRIS(W65_ADBUS) = 0xff;					// Set as input
}

void read_sram(uint32_t addr, uint8_t *buf, unsigned int len)
{
    union address_bus_u ab;
    unsigned int i;

	ab.w = addr;
	i = 0;

	if (cpu_flg) {
		// W65C816 native mode
		while( i < len ) {
			TRIS(W65_ADBUS) = 0x00;					// Set as output
			LAT(W65_ADR_L) = ab.ll;
			LAT(W65_ADR_H) = ab.lh;

		    LAT(W65_ADBUS) = ab.hl;
			LAT(W65_DCK) = 1;			// Set Bank register
			LAT(W65_DCK) = 0;
			
			TRIS(W65_ADBUS) = 0xFF;					// Set as input
			ab.w++;									// Ensure bus data setup time from HiZ to valid data
			((uint8_t*)buf)[i] = PORT(W65_ADBUS);	// read data
			i++;
	    }
	}
	else {
		// W65C02 mode
		while( i < len ) {
			LAT(W65_ADR_L) = ab.ll;
			LAT(W65_ADR_H) = ab.lh;

			ab.w++;									// Ensure bus data setup time from HiZ to valid data
			((uint8_t*)buf)[i] = PORT(W65_ADBUS);	// read data
			i++;
	    }
	}
}
