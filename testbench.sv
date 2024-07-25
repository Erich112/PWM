// Code your testbench here
`include "pwm_generator.v"
`include "define.v"

module testbench_pd;
   wire clk_out;

   reg [15:0] period;
   reg [15:0] duty;
   reg oe;
   reg start;
   logic clk; 
   pwm_period_duty_signal_generator pd(clk,start,period,duty,oe,clk_out);
   initial begin
      oe = 1;
      start = 1;
      clk = 0;
      period = 8;
     	duty = 4;
   end
  always begin
    	 begin
	      #5 clk <= ~clk;
      end
  end
   initial begin
     
      $dumpfile("dump.vcd");
      $dumpvars(1);
      #200 $display ("Test done!\n");
      repeat(20)@(posedge clk);
      period = 8;
     	duty = 0;
      repeat(20)@(posedge clk);
      period = 0;
      repeat(20)@(posedge clk);
     	duty = 0;
      repeat(20)@(posedge clk);
      period = 8;
     	duty = 9;
      repeat(20)@(posedge clk);
      period = 8;
     	duty = 4;
      repeat(20)@(posedge clk);
      start = 0;
      oe = 0;
      repeat(20)@(posedge clk);
      start = 1;
      oe = 1;
      period = 8;
      duty = 7;
      repeat(10)@(posedge clk);
      duty = 6;
      #2000 $display ("Test done!\n");
      $finish;
      $dumpoff;     
   end
endmodule


//test PWM output
module testbench;
   logic Clk;
   reg CmdVal;
   reg [`CMD_ADDR_SIZE-1:0] CmdAddr;
   reg [`CMD_DATA_IN_SIZE-1:0] CmdDataIn;
   wire [`CMD_DATA_OUT_SIZE-1:0] CmdDataOut;
   reg CmdRW;
   reg Reset_l;
   reg OE;
   wire PWM_out;
   PWM pwm_test (Clk, CmdVal, CmdAddr, CmdDataIn, CmdDataOut, CmdRW, Reset_l, OE, PWM_out);

   initial begin
      Clk = 0;
      forever begin
	      #5 Clk = ~Clk;
      end
   end

   initial begin
      $fsdbDumpfile("inter.fsdb");
      $fsdbDumpvars(0);
      $dumpfile("dump.vcd");
      $dumpvars(1);
      repeat(1)@(posedge Clk);
      Reset_l <= 0;
      repeat(4)@(posedge Clk);
      CmdRW <= 0;
      CmdAddr <= 01;
      CmdVal <= 0;
      CmdDataIn <= 3;
      OE <= 1;
      repeat(20)@(posedge Clk);
      CmdRW <= 1; 
      repeat(4)@(posedge Clk);
      Reset_l <= 1;
      repeat(4)@(posedge Clk);
      CmdVal <= 1;
      repeat(10)@(posedge Clk);
      CmdRW <= 1;
      repeat(4)@(posedge Clk);
      Reset_l = 0;
         //OE = 1;
      CmdRW <= 0;
      repeat(20)@(posedge Clk);
      Reset_l <= 1;
      repeat(4)@(posedge Clk);
      CmdDataIn <= 7;
      CmdAddr <= 00;
      CmdRW <= 1;
      repeat(14)@(posedge Clk);
      CmdRW <= 0;
      CmdAddr <= 10;
      CmdVal <= 1;
      CmdDataIn <= 2;    
      repeat(30)@(posedge Clk);
      CmdRW <= 1;
      repeat(20)@(posedge Clk);
      CmdRW <= 0;
      CmdAddr <= 11;
      CmdDataIn <= 0;
      repeat(10)@(posedge Clk);
      CmdRW <= 0;
      CmdAddr <= 11;
      CmdDataIn <= 1;      
      repeat(30)@(posedge Clk);
      Reset_l <= 0;
      CmdRW <= 1;
      #1000 $display ("Test done!\n");
      $finish;
      $dumpoff;     
   end
endmodule
