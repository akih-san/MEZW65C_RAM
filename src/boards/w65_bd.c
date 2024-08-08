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

#include "../../src/w65.h"
#include <stdio.h>
#include <string.h>
#include <assert.h>
#include "../../drivers/SDCard.h"
#include "../../drivers/picregister.h"

#define SPI_PREFIX      SPI_SD
#define SPI_HW_INST     SPI1
#include "../../drivers/SPI.h"

#define W65_ADBUS		B
#define W65_ADR_L		C
#define W65_ADR_H		D

#define W65_NMI		E1
#define W65_DCK		A1
#define W65_IRQ		A2
#define W65_CLK		A3
#define W65_RW		A4
#define W65_RDY		A5

#define W65_RESET		E0
#define W65_BE			A0

// SPI
#define MISO			B2
#define MOSI			B0
#define SPI_CK			B1
#define SPI_SS			E2

//SD IO
#define SPI_SD_POCI		MISO
#define SPI_SD_PICO		MOSI
#define SPI_SD_CLK		SPI_CK
#define SPI_SD_SS       SPI_SS

//#define CLK_INC 524288;	// 16MHz
//#define CLK_INC 491520;	// 15MHz
//#define CLK_INC 458752;	// 14MHz
//#define CLK_INC 425984;	// 13MHz
//#define CLK_INC 393216;	// 12MHz
//#define CLK_INC 360448;	// 11MHz
//#define CLK_INC 327680;	// 10MHz
//#define CLK_INC 294912;	// 9MHz
#define CLK_INC 262144;	// 8MHz
//#define CLK_INC 229376;	// 7MHz
//#define CLK_INC 196608;	// 6MHz
//#define CLK_INC 163840;	// 5MHz
//#define CLK_INC 131072;	// 4MHz
//#define CLK_INC 98304;	// 3MHz
//#define CLK_INC 81920;	// 2.5MHz
//#define CLK_INC 65536;	// 2MHz
//#define CLK_INC 32768;	// 1MHz

#define CMD_REQ CLC4OUT

static void bus_hold_req(void);
static void bus_release_req(void);
static void reset_ioreq(void);
void bus_master_operation(void);

	#include "w65_cmn.c"

void sys_init()
{
    W65_common_sys_init();

//
// Setup CLC
//
	//========== CLC1 : make /BE  ==========

	CLCSELECT = 0;		// CLC1 select

	CLCnSEL0 = 0x2a;	// NCO1 : CLK
    CLCnSEL1 = 127;		// NC
	CLCnSEL2 = 127;		// NC
	CLCnSEL3 = 127;		// NC

    CLCnGLS0 = 0x02;	// NCO1 -> lcxg1
	CLCnGLS1 = 0x00;	// 0 -> lcxg2(DFF D)
    CLCnGLS2 = 0x00;	// 0 -> lcxg3(DFF R)
    CLCnGLS3 = 0x00;	// 0 -> lcxg4(DFF S)

    CLCnPOL = 0x00;		// POL=0: CLC1OUT = DFF Q
    CLCnCON = 0x84;		// 1-Input D Flip-Flop with S and R

	// Release wait (D-FF reset)
	// init DFF Q = 0 : Bus Hi-z

	G3POL = 1;
	G3POL = 0;

	PPS(W65_BE) = 0x01;	// output:CLC1OUT->/BE(RA0)

	//========== CLC2 : make IRQ  ==========

	CLCSELECT = 1;		// CLC2 select

	CLCnSEL0 = 0x2a;	// NCO1 : CLK
    CLCnSEL1 = 127;		// NC
	CLCnSEL2 = 127;		// NC
	CLCnSEL3 = 127;		// NC

    CLCnGLS0 = 0x02;	// NCO1 -> lcxg1
	CLCnGLS1 = 0x00;	// 0 -> lcxg2(DFF D)
    CLCnGLS2 = 0x00;	// 0 -> lcxg3(DFF R)
    CLCnGLS3 = 0x00;	// 0 -> lcxg4(DFF S)

    CLCnPOL = 0x80;		// POL=1: CLC2OUT = not DFF Q
    CLCnCON = 0x84;		// 1-Input D Flip-Flop with S and R

	// Release wait (D-FF reset)
	// init CLC2OUT = 1 : IRQ = 1

	G3POL = 1;
	G3POL = 0;

	PPS(W65_IRQ) = 0x02;	// output:CLC2OUT->/IRQ(RA2)

	// SPI data and clock pins slew at maximum rate

	SLRCON(SPI_SD_PICO) = 0;
	SLRCON(SPI_SD_CLK) = 0;
	SLRCON(SPI_SD_POCI) = 0;

}

void setup_sd(void) {
    //
    // Initialize SD Card
    //
    static int retry;
    for (retry = 0; 1; retry++) {
        if (20 <= retry) {
            printf("No SD Card?\n\r");
            while(1);
        }
//        if (SDCard_init(SPI_CLOCK_100KHZ, SPI_CLOCK_2MHZ, /* timeout */ 100) == SDCARD_SUCCESS)
        if (SDCard_init(SPI_CLOCK_100KHZ, SPI_CLOCK_4MHZ, /* timeout */ 100) == SDCARD_SUCCESS)
//        if (SDCard_init(SPI_CLOCK_100KHZ, SPI_CLOCK_8MHZ, /* timeout */ 100) == SDCARD_SUCCESS)
            break;
        __delay_ms(200);
    }
}

void start_W65(void)
{
	bus_release_req();

	// Unlock IVT
    IVTLOCK = 0x55;
    IVTLOCK = 0xAA;
    IVTLOCKbits.IVTLOCKED = 0x00;

    // Default IVT base address
    IVTBASE = 0x000008;

    // Lock IVT
    IVTLOCK = 0x55;
    IVTLOCK = 0xAA;
    IVTLOCKbits.IVTLOCKED = 0x01;

	// release /BE
	CLCSELECT = 0;		// CLC1 select
	G2POL = 1;			// /BE = 1 rising CLK edge

	// W65 start
    LAT(W65_RESET) = 1;		// Release reset

    __delay_ms(100);
}

static void bus_hold_req(void) {
	// Set address bus as output
	TRIS(W65_ADR_L) = 0x00;	// A7-A0
	TRIS(W65_ADR_H) = 0x00;	// A8-A15

	LAT(W65_RW) = 1;			// SRAM READ mode
	TRIS(W65_RW) = 0;			// output
    TRIS(W65_DCK) = 0;			// Set as output
}

static void bus_release_req(void) {
	// Set address bus as input
	TRIS(W65_ADR_L) = 0xff;	// A7-A0
	TRIS(W65_ADR_H) = 0xff;	// A8-A15

    TRIS(W65_DCK) = 1;		// Set as input
	TRIS(W65_RW) = 1;		// input
}

//--------------------------------
// event loop ( PIC MAIN LOOP )
//--------------------------------
void board_event_loop(void) {

	for (;;) {
		while(R(W65_RDY)) {}		// wait until RDY = 0

		// BUS -> Hi-z
		CLCSELECT = 0;				// CLC1 select
		G2POL = 0;					// /BE = 0 rising CLK edge
		bus_hold_req();				// PIC becomes a busmaster
		bus_master_operation();
		bus_release_req();
		// Release BUS
		G2POL = 1;					// /BE = 1 rising CLK edge

		CLCSELECT = 1;				// CLC2 select
		G2POL = 1;					// /IRQ = 0 at rising CLK edge
		while(!R(W65_RDY)){}		// check until RDY=1
		G2POL = 0;					// /IRQ = 1 at rising CLK edge
	}

}

#include "../../drivers/pic18f57q43_spi.c"
#include "../../drivers/SDCard.c"

