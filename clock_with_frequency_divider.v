module clock(
    input  clk,               // High frequency system clock from FPGA
    input  reset,             // Reset input
    input  set_alarm,         // Flag to set the alarm
    input  [5:0] alarm_data,  // Input for setting alarm hours, minutes, or seconds
    input  start,             // Start the clock
    input  set_hours,         // Flag to load hours
    input  set_mins,          // Flag to load minutes
    input  set_secs,          // Flag to load seconds
    output reg slow_clk,
    output reg buzzer,        // Alarm buzzer output
    output reg [4:0] hours,   // Output for hours (5 bits)
    output reg [5:0] mins,    // Output for minutes (6 bits)
    output reg [5:0] secs     // Output for seconds (6 bits)
);

// Internal registers to hold the current time
reg [4:0] alarm_hours_reg;
reg [5:0] alarm_mins_reg;
reg [5:0] alarm_secs_reg;

// Clock Divider Implementation
// 125 MHz to 1 Hz clock divider (assuming a 125 MHz input clock)
reg [26:0] count = 0;   // 27-bit counter for 125 million count
parameter DIVIDE_BY = 125000000 / 2;  // Half of 125 million for toggle at each 0.5 seconds
//reg slow_clk = 0;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        count <= 0;
        slow_clk <= 0;
    end else begin
        if (count == DIVIDE_BY - 1) begin
            count <= 0;
            slow_clk <= ~slow_clk;  // Toggle the slow clock
        end else begin
            count <= count + 1;
        end
    end
end

// Use slow_clk for your time-keeping logic
always @(posedge slow_clk or posedge reset) begin
    if (reset) begin
        secs <= 6'b000000;
        mins <= 6'b000000;
        hours <= 5'b00000;
        alarm_hours_reg <= 5'b00000;
        alarm_mins_reg <= 6'b000000;
        alarm_secs_reg <= 6'b000000;
    end else if (set_alarm) begin
        if (set_hours) alarm_hours_reg <= alarm_data[4:0];  // Load hours
        if (set_mins) alarm_mins_reg <= alarm_data;         // Load minutes
        if (set_secs) alarm_secs_reg <= alarm_data;         // Load seconds
    end else if (start) begin
        if (secs == 6'b111011) begin  // 59 in binary
            secs <= 6'b000000;  // Reset seconds
            if (mins == 6'b111011) begin  // 59 in binary
                mins <= 6'b000000;  // Reset minutes
                if (hours == 5'b10111) begin  // 23 in binary
                    hours <= 5'b00000;  // Reset hours
                end else begin
                    hours <= hours + 1'b1;  // Increment hours
                end
            end else begin
                mins <= mins + 1'b1;  // Increment minutes
            end
        end else begin
            secs <= secs + 1'b1;  // Increment seconds
            if (hours == alarm_hours_reg && mins == alarm_mins_reg && secs == alarm_secs_reg) begin
                buzzer <= 1;  // Activate buzzer
            end else begin
                buzzer <= 0;  // Deactivate buzzer
            end
        end
    end
end

endmodule
