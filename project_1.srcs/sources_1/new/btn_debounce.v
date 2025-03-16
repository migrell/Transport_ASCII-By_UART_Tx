`timescale 1ns / 1ps

module btn_debounce(
    input clk,
    input reset,
    input i_btn,
    output o_btn
);
    // 내부 신호 선언
    reg [7:0] q_reg, q_next; // Shift register
    reg edge_detect;
    wire btn_debounce;
    
    // 1MHz 클럭 생성 (100MHz에서 분주)
    localparam DIVIDER = 100; // 100MHz → 1MHz로 변경
    reg [$clog2(DIVIDER) - 1 :0] counter;
    reg r_1mhz;
    
    // 1MHz 클럭 생성
    always @(posedge clk, posedge reset) begin
        if(reset) begin
            counter <= 0;
            r_1mhz <= 0;
        end else begin
            if(counter == DIVIDER - 1) begin
                counter <= 0;
                r_1mhz <= 1'b1;
            end else begin
                counter <= counter + 1;
                r_1mhz <= 1'b0;
            end
        end
    end
    
    // Shift register 상태 업데이트
    always @(posedge r_1mhz, posedge reset) begin
        if(reset) begin
            q_reg <= 0;
        end else begin
            q_reg <= q_next;
        end
    end
    
    // 다음 상태 로직
    always @(*) begin
        q_next = {i_btn, q_reg[7:1]}; // 최상위 비트에 현재 버튼 상태 삽입
    end
    
    // 8비트 모두 1이면 디바운스 완료
    assign btn_debounce = &q_reg;
    
    // 엣지 검출을 위한 FF
    always @(posedge clk, posedge reset) begin
        if(reset) begin
            edge_detect <= 1'b0;
        end else begin
            edge_detect <= btn_debounce;
        end
    end
    
    // 상승 엣지 검출 (버튼이 눌러진 순간만 1)
    assign o_btn = btn_debounce & (~edge_detect);
endmodule