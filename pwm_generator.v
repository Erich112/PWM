`include "define.v"

module pwm_registers(
    input clk,
    input CmdVal,
    input [`CMD_ADDR_SIZE-1:0] CmdAddr,
    input [`CMD_DATA_IN_SIZE-1:0] CmdDataIn,
    output reg [`CMD_DATA_OUT_SIZE-1:0] CmdDataOut,
    input CmdRW,
    input Reset_l,
    output reg [`PERIOD_SIZE-1:0] period,
    output reg [`DUTY_SIZE-1:0] duty,
    output reg [`PRESCALER_SIZE-1:0] prescaler,
    output reg start
    );
    reg [15:0] TmpCmdDataOut;
    always@(posedge clk or Reset_l) begin
        
        if(!Reset_l) begin // reset active on low
            period = `PERIOD_RESET_VAL;
            duty = `DUTY_RESET_VAL;
            prescaler = `PRESCALER_RESET_VAL;
            start = `START_RESET_VAL;
            CmdDataOut = 16'bz;
        end
        else begin
            if (CmdVal == 1) begin 
                if(CmdRW == 1) //read
                begin
                    case (CmdAddr)
                        `PERIOD_ADDR: TmpCmdDataOut <= period;
                        `DUTY_ADDR: TmpCmdDataOut <=  duty;
                        `PRESCALER_ADDR: TmpCmdDataOut <= {13'b0, prescaler};
                        `START_ADDR: TmpCmdDataOut <= {15'b0, start};
                    endcase
                end
                if(CmdRW == 0) begin //write 
                // registers are written only when cmdVal == 1 and RW == 0 begin
                    case (CmdAddr)
                        `PERIOD_ADDR: period = CmdDataIn;
                        `DUTY_ADDR: duty = CmdDataIn;
                        `PRESCALER_ADDR: prescaler = CmdDataIn[2:0];
                        `START_ADDR: start = CmdDataIn[0];
                    endcase
                end
            end
            CmdDataOut <= TmpCmdDataOut;
            //having a temp reg, read is relayed by 1 extra clk cycle
        end
    end
endmodule
module pwm_prescaler_clk_generator (
    input clk,
    input [`PRESCALER_SIZE-1:0] prescaler_in,
    output reg clk_out
    );
    reg [`PRESCALER_SIZE-1:0] cnt = 1;  //cnt = counts how many clk barriers are needed for one new clk_out barrier (at least one)
  	reg current_clk_val = 1;
    always@(posedge clk or negedge clk) begin
        if (prescaler_in == 0)  //same clk
            clk_out <= clk;
        else begin
        if(cnt < 2** prescaler_in) begin //begin couting for the current barrier
      	    clk_out <= current_clk_val;
    	    cnt <= cnt + 1;
        end
        else begin  // when couting is done, start it again but with the neg barrier
      	    cnt <= 1;
            current_clk_val <= ~current_clk_val; 
        end
    end
  end
endmodule

module pwm_period_duty_signal_generator(
    input clk,
    input start,
    input [`PERIOD_SIZE-1:0] period,
    input [`DUTY_SIZE-1:0] duty,
    input oe,
    output reg signal_out
    );
    reg [15:0] cnt = 0, current_clk_val, switched;
    always@(posedge clk) begin
            if(!oe)
                signal_out <= 1'bz;
            else begin
                if(!start)
                    signal_out <= current_clk_val;
                else begin
                    if (period == 0)
                        signal_out <= 1;
                    if (period-duty == 1 && cnt == duty) begin
                        signal_out <= 0;
                        cnt <= 0;
                    end
                    if(cnt >= period-1)
                	    cnt <= 0;
                    // if duty == 0 or duty >= period, we need to start counting until period
                    // else, count the duties, then the rest of the period
                    else begin 
                      if(cnt < period) begin
                        if (cnt < duty)
                                signal_out <= 1;
                        else
                                signal_out <= 0;
                        cnt <= cnt + 1;
                        end
                    end
                end
            end
            current_clk_val <= signal_out;
        end
endmodule

module PWM(
    input Clk,
    input CmdVal,
    input [`CMD_ADDR_SIZE-1:0] CmdAddr,
    input [`CMD_DATA_IN_SIZE-1:0] CmdDataIn,
    output reg [`CMD_DATA_OUT_SIZE-1:0] CmdDataOut,
    input CmdRW,
    input Reset_l,
    input OE,
    output reg PWM_out
    );

    wire [`PERIOD_SIZE-1:0] Period;
    wire [`DUTY_SIZE-1:0] Duty;
    wire [`PRESCALER_SIZE-1:0] Prescaler;
    wire Start;
    wire new_prescaler_Clk;

    pwm_registers PWM_regs(Clk, CmdVal, CmdAddr, CmdDataIn, CmdDataOut, CmdRW, Reset_l, Period, Duty, Prescaler, Start);
    pwm_prescaler_clk_generator PWM_pr_clk(Clk, Prescaler, new_prescaler_Clk);
    pwm_period_duty_signal_generator PWM_out_signal(new_prescaler_Clk, Start, Period, Duty, OE, PWM_out);
endmodule