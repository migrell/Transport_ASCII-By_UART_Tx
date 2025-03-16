`timescale 1ns / 1ps

module baud_tick_gen (
    input clk,
    input rst,
    output baud_tick
);
    // 9600 baud rate 설정
    parameter BAUD_RATE = 9600;
    localparam BAUD_COUNT = 100_000_000 / BAUD_RATE;
    
    reg [$clog2(BAUD_COUNT) - 1 : 0] count_reg, count_next;
    reg tick_reg, tick_next;
    
    // 출력 할당
    assign baud_tick = tick_reg;
    
    always @(posedge clk, posedge rst) begin
        if(rst == 1) begin
            count_reg <= 0;
            tick_reg <= 0;
        end else begin
            count_reg <= count_next;
            tick_reg <= tick_next;
        end
    end
    
    // 다음 상태 로직
    always @(*) begin
        count_next = count_reg;
        tick_next = tick_reg;
        
        if (count_reg == BAUD_COUNT - 1) begin
            count_next = 0;
            tick_next = 1'b1;
        end else begin
            count_next = count_reg + 1;
            tick_next = 1'b0;
        end
    end
endmodule