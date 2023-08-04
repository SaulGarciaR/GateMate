`timescale 1ns / 1ps

// ---------- SERIAL TOP ----------

module aes256_uart_tb ();


// ---------- MODULE REGISTERS AND SIGNALS ----------

  // Testbench uses a 10 MHz clock
  // Want to interface to 115200 baud UART
  // 10000000 / 115200 = 87 Clocks Per Bit.
parameter c_CLOCK_PERIOD_NS = 100;
parameter c_BIT_PERIOD      = 8700;

reg             clk;            // global clock
reg             reset_n;              // global async negative edge reset
reg             reset_tx;              // global async negative edge reset

reg  [7:0]      tx_byte;
reg             tx_start;
wire            tx_busy;
wire            tx;

wire            rx;
wire            rx_ready;
wire [7:0]      rx_byte;

reg  [255:0]    key;
reg  [127:0]    text_in;
reg  [383:0]    data_in;
reg  [127:0]    text_out_exp;
reg  [255:0]    data_received;
reg             first_data;
reg             data_ready;
parameter       num_bytes_tx = 48;    // number of bytes
parameter       num_bytes_rx = 16;    // number of bytes
integer         j;              // loop integer to transmit data
integer         i;              // loop integer to receive data
integer         n;              // loop integer to receive data

// ---------- EVENTS ----------

event reset_enable;     // async negative edge reset pulse
event reset_done;       // reset is done
event finish_sim;       // finish simulation

// ---------- GLOBAL CLOCK GENERATOR ----------

initial
  begin
    clk = 1'b0;
    forever
      #(c_CLOCK_PERIOD_NS/2) clk = ~clk;
  end


// ---------- DEFAULT INPUT VALUES ----------

initial 
  begin
	key = 256'h0;
	text_in = 128'h014730f80ac625fe84f026c60bfd547d;
	data_in = {text_in,key};
	text_out_exp = 128'h5c9d844ed46f9885085e5d6a4f94c7d7;
	data_received = 256'h0;
	i = 0;
	j = 0;
	first_data = 1'b0;
    data_ready = 1'b0;
  end


// ---------- GLOBAL ASYNC NEGATIVE EDGE RESET GENERATOR ----------
  
always @(reset_enable)
  begin
	       reset_n = 1'b0;
	#15    reset_n = 1'b1;
	-> reset_done;
  end


initial
  begin

    -> reset_enable;                // reset pulse
    @(reset_done);                  // wait until reset is done

    for(n=0; n < 2; n=n+1)
      begin
        reset_tx <= 1'b1;
	    #15    reset_tx <= 1'b0;
        for(j=0; j < num_bytes_tx; j=j+1)
          begin
            
            tx_start <= 1'b1;
            tx_byte <= data_in[8*j +: 8];
            @(posedge clk);
            tx_start <= 1'b0;
            @(negedge tx_busy);
    
          end
      
        wait (first_data);
        # 10000;
        $display("After Delay");
    end
    -> finish_sim;
    
  end

always @ (posedge rx_ready)
  begin

    data_received[8*i +: 8] <= rx_byte;
    i <= i+1;
    first_data <= (i >= num_bytes_rx-1) ? 1'b1: 1'b0;
    data_ready <= (i == (num_bytes_rx*2)-1) ? 1'b1: 1'b0;
    
  end

always @ (finish_sim)
  begin
    
    @ (posedge data_ready);
    if (data_received[127:0] == text_out_exp)
      $display("Test Passed - Correct Bytes Received");
    else
      $display("Test Failed - Incorrect Bytes Received");

    repeat (5) # c_BIT_PERIOD;
    $finish;

  end

// ---------- MODULES INSTANTIATION ----------

// -- DEVICE UNDER TEST --
aes256_uart aes256_uart_u   (
                            .clk(clk),
                            .reset_n(reset_n),
                            .data_in(tx),
                            .led(),
                            .data_out(rx)   // output
                            );
                            
// -- FOR TB --
serial_tx   serial_tx_u     (
                            .clk(clk),
                            .rst(reset_tx),
                            .tx_block(1'b0),
                            .data(tx_byte),
                            .new_data(tx_start),
                            .busy(tx_busy),         // output
                            .tx(tx)                 // output
                            );
                              
serial_rx   serial_rx_u     (
                            .clk(clk),
                            .rst(!reset_n),
                            .rx(rx),
                            .new_data(rx_ready),    // output
                            .data(rx_byte)          // output
                            );
                        
endmodule
