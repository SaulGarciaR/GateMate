`timescale 1ns / 1ps
//`define CCSDF
// ---------- SERIAL TOP ----------

module aes256_uart_tb ();


// ---------- MODULE REGISTERS AND SIGNALS ----------

  // Testbench uses a 10 MHz clock
parameter c_CLOCK_PERIOD_NS = 100;


reg             clk;            // global clock
reg             reset_n;              // global async negative edge reset
wire [7:0]	led;


// ---------- GLOBAL CLOCK GENERATOR ----------

initial
  begin
    clk = 1'b0;
    forever
      #(c_CLOCK_PERIOD_NS/2) clk = ~clk;
  end


// ----------  ----------

initial
  begin
    `ifdef CCSDF
		$sdf_annotate("aes256_impl_00.sdf", aes256_impl_u);
    `endif
		$dumpfile("sim/aes256_impl_tb.vcd");
		$dumpvars(0, aes256_uart_tb);
		
    reset_n = 1'b0;
    #15    reset_n = 1'b1;
	
    repeat (1000) # c_CLOCK_PERIOD_NS;
    $finish;
    
    
  end



// ---------- MODULES INSTANTIATION ----------

// -- DEVICE UNDER TEST --
aes256_impl aes256_impl_u   (
                            .clk10(clk),
                            .reset_n(reset_n),
                            .led(led)	// output
                            );
                            
                        
endmodule
