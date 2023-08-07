`timescale 1ns / 1ps

// ---------- AES256 UART ----------

module aes256_uart  (
                    clk,
                    reset_n,
                    data_in,
                    led,           // output
                    data_out           // output
                    );


// ---------- MODULE INTERFACE ----------

input               clk;                // global clock
input               reset_n;              // global negative edge reset
input               data_in;            // input data bits for RX
output wire [5:0]   led;           // output data bits from TX
output wire         data_out;           // output data bits from TX


// ---------- MODULE REGISTERS AND SIGNALS ----------

  // 10 MHz clock
  // Want to interface to 115200 baud UART
  // 10000000 / 115200 = 87 Clocks Per Bit.

wire            rx;
wire            rx_ready;
wire [7:0]      rx_byte;

reg  [7:0]      tx_byte;
reg             tx_start;
wire            tx_busy;
wire            tx;
    
reg             aes_start;
reg  [255:0]    key;
reg  [127:0]    text_in;
wire [127:0]    text_out;
wire            aes_ready;

wire            rx_done;
parameter       num_bytes_rx = 48;    // number of bytes
parameter       num_bytes_tx = 16;    // number of bytes
reg  [5:0]      cnt_rx;              // loop integer to send data
reg  [4:0]      cnt_tx;  

reg [2:0]           current_state, next_state;
parameter           RX_DATA = 6'd0,
                    AES = 6'd1,
                    TX_DATA = 6'd2,
                    TX_BUSY = 6'd3;

// ---------- STATE MACHINE ----------
/*
always @ (posedge clk or negedge reset_n)
  begin: STATE_MEMORY
  
    if (!reset_n)   current_state <= RX_DATA;
    else            current_state <= next_state;
    
  end


always @ (current_state or rx_done or aes_ready or tx_busy)
  begin: NEXT_STATE_LOGIC
  
    case (current_state)
      RX_DATA : next_state = (rx_done) ? AES : RX_DATA;
      AES :     next_state = (aes_ready) ? TX_DATA : AES;
      TX_DATA : next_state = TX_BUSY;
      TX_BUSY : begin
                  if (!tx_busy && !tx_start)
                    next_state = TX_DATA;
                  else if (cnt_tx == num_bytes_tx)
                    next_state = RX_DATA;
                  else
                    next_state = TX_BUSY;
                end

      default : next_state = RX_DATA;
    endcase
    
  end
*/
always @ (posedge clk or negedge reset_n)
  begin: STATE_MEMORY
  
    if (!reset_n)   current_state <= RX_DATA;
    else
      begin
        case (current_state)
          RX_DATA : current_state <= (rx_done) ? AES : RX_DATA;
          AES :     current_state <= (aes_ready) ? TX_DATA : AES;
          TX_DATA : current_state <= TX_BUSY;
          TX_BUSY : begin
                      if (!tx_busy && !tx_start)
                        current_state <= TX_DATA;
                      else if (cnt_tx == num_bytes_tx)
                        current_state <= RX_DATA;
                      else
                        current_state <= TX_BUSY;
                    end
    
          default : current_state <= RX_DATA;
        endcase
      end
  end

always @ (posedge clk or negedge reset_n)
  begin: RX

    if (!reset_n)
      begin
        key <= 0;
        text_in <= 0;
        aes_start <= 0;
      end
    else if (current_state == RX_DATA && rx_ready)
        case (cnt_rx)
            0:	key[7:0] <= rx_byte;
            1:	key[15:8] <= rx_byte;
            2:	key[23:16] <= rx_byte;
            3:	key[31:24] <= rx_byte;
            4:	key[39:32] <= rx_byte;
            5:	key[47:40] <= rx_byte;
            6:	key[55:48] <= rx_byte;
            7:	key[63:56] <= rx_byte;
            8:	key[71:64] <= rx_byte;
            9:	key[79:72] <= rx_byte;
            10:	key[87:80] <= rx_byte;
            11:	key[95:88] <= rx_byte;
            12:	key[103:96] <= rx_byte;
            13:	key[111:104] <= rx_byte;
            14:	key[119:112] <= rx_byte;
            15:	key[127:120] <= rx_byte;
            16:	key[135:128] <= rx_byte;
            17:	key[143:136] <= rx_byte;
            18:	key[151:144] <= rx_byte;
            19:	key[159:152] <= rx_byte;
            20:	key[167:160] <= rx_byte;
            21:	key[175:168] <= rx_byte;
            22:	key[183:176] <= rx_byte;
            23:	key[191:184] <= rx_byte;
            24:	key[199:192] <= rx_byte;
            25:	key[207:200] <= rx_byte;
            26:	key[215:208] <= rx_byte;
            27:	key[223:216] <= rx_byte;
            28:	key[231:224] <= rx_byte;
            29:	key[239:232] <= rx_byte;
            30:	key[247:240] <= rx_byte;
            31:	key[255:248] <= rx_byte;
            
            32:	text_in[7:0] <= rx_byte;
            33:	text_in[15:8] <= rx_byte;
            34:	text_in[23:16] <= rx_byte;
            35:	text_in[31:24] <= rx_byte;
            36:	text_in[39:32] <= rx_byte;
            37:	text_in[47:40] <= rx_byte;
            38:	text_in[55:48] <= rx_byte;
            39:	text_in[63:56] <= rx_byte;
            40:	text_in[71:64] <= rx_byte;
            41:	text_in[79:72] <= rx_byte;
            42:	text_in[87:80] <= rx_byte;
            43:	text_in[95:88] <= rx_byte;
            44:	text_in[103:96] <= rx_byte;
            45:	text_in[111:104] <= rx_byte;
            46:	text_in[119:112] <= rx_byte;
            47:	begin
                  text_in[127:120] <= rx_byte;
                  aes_start <= 1;
                end
        endcase
    else if (current_state == AES)
        aes_start <= 0;

  end

always @ (posedge clk or negedge reset_n)
  begin: TX

    if (!reset_n)
      begin
        tx_byte <= 0;
        tx_start <= 1'b0;
      end
    else if (current_state == TX_DATA)
      begin
        tx_byte <= (cnt_tx == 0)  ? text_out  [7:0]  : 
                   (cnt_tx == 1)  ? text_out [15:8]  :
                   (cnt_tx == 2)  ? text_out [23:16] :
                   (cnt_tx == 3)  ? text_out [31:24] :
                   (cnt_tx == 4)  ? text_out [39:32] : 
                   (cnt_tx == 5)  ? text_out [47:40] :
                   (cnt_tx == 6)  ? text_out [55:48] :
                   (cnt_tx == 7)  ? text_out [63:56] :
                   (cnt_tx == 8)  ? text_out [71:64] :
                   (cnt_tx == 9)  ? text_out [79:72] : 
                   (cnt_tx == 10) ? text_out [87:80] :
                   (cnt_tx == 11) ? text_out [95:88] :
                   (cnt_tx == 12) ? text_out[103:96] :
                   (cnt_tx == 13) ? text_out[111:104]:
                   (cnt_tx == 14) ? text_out[119:112]: 
                   (cnt_tx == 15) ? text_out[127:120]:
                                    tx_byte <= 8'b0;
        tx_start <= 1'b1;
      end
    else if (current_state == TX_BUSY)
        tx_start <= 1'b0;

  end


always @ (posedge clk or negedge reset_n)
  begin: CNT_RX

    if (!reset_n)
        cnt_rx <= 0;
    else if (rx_ready)
        cnt_rx <= cnt_rx + 1;
    else if (cnt_rx == num_bytes_rx)
        cnt_rx <= 0;

  end


always @ (posedge clk or negedge reset_n)
  begin: CNT_TX

    if (!reset_n)
	   cnt_tx <= 0;
    else if (current_state==TX_DATA)
	   cnt_tx <= cnt_tx + 1;
    else if (cnt_tx == num_bytes_tx && current_state==TX_BUSY)
	   cnt_tx <= 0;

  end


assign rx = data_in;
assign rx_done = (cnt_rx == num_bytes_rx) ? 1'b1 : 1'b0;
assign data_out = tx;
assign led = cnt_rx;


// ---------- MODULES INSTANTIATION ----------

aes256_enc  aes256_enc_u    (
                            .clk(clk),
                            .reset_n(reset_n),
                            .start(aes_start),
                            .key_in(key),
                            .data_in(text_in),
                            .data_out(text_out),    // output
                            .ready(aes_ready)       // output
                            );

serial_rx   serial_rx_u     (
                            .clk(clk),
                            .rst(!reset_n),
                            .rx(rx),
                            .new_data(rx_ready),    // output
                            .data(rx_byte)          // output
                            );
                        
serial_tx   serial_tx_u     (
                            .clk(clk),
                            .rst(!reset_n),
                            .tx_block(1'b0),
                            .data(tx_byte),
                            .new_data(tx_start),
                            .busy(tx_busy),     // output
                            .tx(tx)             // output
                            );
        

endmodule
