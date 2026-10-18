;
; ChromaLink IoT - ATmega328P firmware (Arduino UNO, 16 MHz)
;
; Drives a common-cathode RGB LED from two input sources at once:
;   - five push buttons on PD2..PD6 (active low, internal pull-ups)
;   - single-character commands '1'..'5' on the UART (9600 8N1),
;     sent by the ESP32 bridge when a button is tapped in the phone app
;
; Timing comes from Timer1 in CTC mode (10 ms tick, flag polled - no ISRs),
; so the color-cycle mode never blocks input handling.
;

.include "m328pdef.inc"

; ---- Pin map ------------------------------------------------------------
.equ LED_R      = PB1               ; D9
.equ LED_G      = PB2               ; D10
.equ LED_B      = PB3               ; D11
.equ BUZZER     = PB4               ; D12
.equ LED_MASK   = (1<<LED_R)|(1<<LED_G)|(1<<LED_B)

.equ BTN_YELLOW  = PD2              ; D2
.equ BTN_MAGENTA = PD3              ; D3
.equ BTN_WHITE   = PD4              ; D4
.equ BTN_CYCLE   = PD5              ; D5
.equ BTN_OFF     = PD6              ; D6
.equ BTN_MASK    = (1<<PD2)|(1<<PD3)|(1<<PD4)|(1<<PD5)|(1<<PD6)

; ---- Colors (PORTB bit patterns) ----------------------------------------
.equ C_OFF      = 0
.equ C_RED      = (1<<LED_R)
.equ C_GREEN    = (1<<LED_G)
.equ C_BLUE     = (1<<LED_B)
.equ C_YELLOW   = C_RED | C_GREEN
.equ C_MAGENTA  = C_RED | C_BLUE
.equ C_CYAN     = C_GREEN | C_BLUE
.equ C_WHITE    = C_RED | C_GREEN | C_BLUE

; ---- Modes --------------------------------------------------------------
.equ MODE_OFF     = 0
.equ MODE_YELLOW  = 1
.equ MODE_MAGENTA = 2
.equ MODE_WHITE   = 3
.equ MODE_CYCLE   = 4
.equ NO_INPUT     = 0xFF

; ---- Timing -------------------------------------------------------------
.equ TICK_TOP       = 2499          ; 16 MHz / 64 / 2500 = 100 Hz -> 10 ms
.equ TICKS_PER_STEP = 50            ; 500 ms per color in cycle mode
.equ BAUD_UBRR      = 103           ; 9600 baud @ 16 MHz

; ---- Registers ----------------------------------------------------------
.def temp  = r16
.def mode  = r17
.def step  = r18                    ; index into cycle_colors
.def ticks = r19                    ; ticks left before next cycle step
.def scratch = r21

.cseg
.org 0x0000
    rjmp reset

reset:
    ldi temp, high(RAMEND)
    out SPH, temp
    ldi temp, low(RAMEND)
    out SPL, temp

    ; LEDs and buzzer as outputs, all off
    ldi temp, LED_MASK | (1<<BUZZER)
    out DDRB, temp
    clr temp
    out PORTB, temp

    ; Buttons as inputs with pull-ups
    in temp, DDRD
    andi temp, low(~BTN_MASK)
    out DDRD, temp
    in temp, PORTD
    ori temp, BTN_MASK
    out PORTD, temp

    rcall timer_init
    rcall uart_init

    ; Startup sequence: 3 s beep, then all LEDs on for 2 s
    sbi PORTB, BUZZER
    ldi r24, low(300)
    ldi r25, high(300)
    rcall wait_ticks
    cbi PORTB, BUZZER

    ldi temp, C_WHITE
    rcall set_color
    ldi r24, low(200)
    ldi r25, high(200)
    rcall wait_ticks

    ldi mode, MODE_OFF
    rcall apply_mode

main_loop:
    rcall read_input                ; temp = requested mode or NO_INPUT
    cpi temp, NO_INPUT
    breq check_cycle
    cp temp, mode                   ; ignore held buttons / repeated commands
    breq check_cycle
    mov mode, temp
    rcall apply_mode

check_cycle:
    cpi mode, MODE_CYCLE
    brne main_loop
    sbis TIFR1, OCF1A               ; wait for the next 10 ms tick
    rjmp main_loop
    ldi temp, (1<<OCF1A)
    out TIFR1, temp
    dec ticks
    brne main_loop
    rcall show_cycle_step
    rjmp main_loop

; -------------------------------------------------------------------------
; read_input: buttons take priority over UART.
; Returns the requested mode in temp, or NO_INPUT.
; -------------------------------------------------------------------------
read_input:
    ldi temp, MODE_YELLOW
    sbis PIND, BTN_YELLOW
    ret
    ldi temp, MODE_MAGENTA
    sbis PIND, BTN_MAGENTA
    ret
    ldi temp, MODE_WHITE
    sbis PIND, BTN_WHITE
    ret
    ldi temp, MODE_CYCLE
    sbis PIND, BTN_CYCLE
    ret
    ldi temp, MODE_OFF
    sbis PIND, BTN_OFF
    ret

    lds temp, UCSR0A
    sbrs temp, RXC0
    rjmp no_input
    lds temp, UDR0
    subi temp, '1'                  ; '1'..'5' -> 0..4
    cpi temp, 5
    brsh no_input                   ; anything else is ignored
    inc temp                        ; '1'..'4' -> MODE_YELLOW..MODE_CYCLE
    cpi temp, 5
    brne read_input_done
    ldi temp, MODE_OFF              ; '5' -> MODE_OFF
read_input_done:
    ret
no_input:
    ldi temp, NO_INPUT
    ret

; -------------------------------------------------------------------------
; apply_mode: show the static color for `mode`, or start the cycle.
; -------------------------------------------------------------------------
apply_mode:
    cpi mode, MODE_CYCLE
    brne apply_static
    clr step
    rjmp show_cycle_step

apply_static:
    ldi ZL, low(mode_colors*2)
    ldi ZH, high(mode_colors*2)
    add ZL, mode
    clr temp
    adc ZH, temp
    lpm temp, Z
    rjmp set_color

; show_cycle_step: output cycle_colors[step], advance step, reload ticks.
show_cycle_step:
    ldi ZL, low(cycle_colors*2)
    ldi ZH, high(cycle_colors*2)
    add ZL, step
    clr temp
    adc ZH, temp
    lpm temp, Z
    rcall set_color
    inc step
    andi step, 0x07                 ; 8 entries, wrap around
    ldi ticks, TICKS_PER_STEP
    ret

; set_color: write temp to the LED pins without touching the buzzer.
set_color:
    in scratch, PORTB
    andi scratch, low(~LED_MASK)
    or scratch, temp
    out PORTB, scratch
    ret

; -------------------------------------------------------------------------
; Peripherals
; -------------------------------------------------------------------------
timer_init:
    ldi temp, high(TICK_TOP)        ; 16-bit write: high byte first
    sts OCR1AH, temp
    ldi temp, low(TICK_TOP)
    sts OCR1AL, temp
    clr temp
    sts TCCR1A, temp
    ldi temp, (1<<WGM12)|(1<<CS11)|(1<<CS10)   ; CTC, clk/64
    sts TCCR1B, temp
    ret

uart_init:
    ldi temp, high(BAUD_UBRR)
    sts UBRR0H, temp
    ldi temp, low(BAUD_UBRR)
    sts UBRR0L, temp
    ldi temp, (1<<RXEN0)|(1<<TXEN0)
    sts UCSR0B, temp
    ldi temp, (1<<UCSZ01)|(1<<UCSZ00)          ; 8N1
    sts UCSR0C, temp
    ret

; wait_ticks: block for r25:r24 ticks of 10 ms.
wait_ticks:
    ldi temp, (1<<OCF1A)
    out TIFR1, temp
wait_ticks_loop:
    sbis TIFR1, OCF1A
    rjmp wait_ticks_loop
    ldi temp, (1<<OCF1A)
    out TIFR1, temp
    sbiw r24, 1
    brne wait_ticks_loop
    ret

; -------------------------------------------------------------------------
; Lookup tables (flash)
; -------------------------------------------------------------------------
mode_colors:                        ; indexed by MODE_OFF..MODE_WHITE
    .db C_OFF, C_YELLOW, C_MAGENTA, C_WHITE

cycle_colors:
    .db C_RED, C_GREEN, C_BLUE, C_YELLOW, C_CYAN, C_MAGENTA, C_WHITE, C_OFF
