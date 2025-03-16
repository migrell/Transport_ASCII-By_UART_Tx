module uart_tx_timing_ctrl (
    input clk,
    input rst,
    input tick,
    input sample_tick,
    input [7:0] data_in,
    input start_trigger,
    output reg tx,
    output reg tx_done
);
    // 고정밀 상태 머신 정의
    parameter IDLE = 4'b0000;
    parameter START_BIT = 4'b0001;
    parameter DATA_BIT0 = 4'b0010;
    parameter DATA_BIT1 = 4'b0011;
    parameter DATA_BIT2 = 4'b0100;
    parameter DATA_BIT3 = 4'b0101;
    parameter DATA_BIT4 = 4'b0110;
    parameter DATA_BIT5 = 4'b0111;
    parameter DATA_BIT6 = 4'b1000;
    parameter DATA_BIT7 = 4'b1001;
    parameter STOP_BIT = 4'b1010;
    
    reg [3:0] state, next_state;
    reg [7:0] data_buffer;
    reg tick_prev, sample_prev;
    
    // 에지 검출
    wire tick_edge = tick && !tick_prev;
    wire sample_edge = sample_tick && !sample_prev;
    
    // 상태 및 레지스터 업데이트
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            data_buffer <= 8'h00;
            tx <= 1'b1;
            tx_done <= 1'b1;
            tick_prev <= 1'b0;
            sample_prev <= 1'b0;
        end else begin
            state <= next_state;
            tick_prev <= tick;
            sample_prev <= sample_tick;
            
            // 상태에 기반한 출력 설정
            case (state)
                IDLE: begin
                    tx <= 1'b1;
                    tx_done <= 1'b1;
                    
                    // 시작 트리거 감지
                    if (start_trigger) begin
                        data_buffer <= data_in;
                        tx <= 1'b0; // 즉시 시작 비트 출력
                        tx_done <= 1'b0;
                    end
                end
                
                START_BIT: tx <= 1'b0;
                
                DATA_BIT0: tx <= data_buffer[0];
                DATA_BIT1: tx <= data_buffer[1];
                DATA_BIT2: tx <= data_buffer[2];
                DATA_BIT3: tx <= data_buffer[3];
                DATA_BIT4: tx <= data_buffer[4];
                DATA_BIT5: tx <= data_buffer[5];
                DATA_BIT6: tx <= data_buffer[6];
                DATA_BIT7: tx <= data_buffer[7];
                
                STOP_BIT: tx <= 1'b1;
                
                default: tx <= 1'b1;
            endcase
        end
    end
    
    // 상태 전이 로직 - 명확한 타이밍 정의
    always @(*) begin
        next_state = state;
        
        case (state)
            IDLE: 
                if (start_trigger) next_state = START_BIT;
            
            START_BIT: 
                if (sample_edge) next_state = DATA_BIT0;
            
            DATA_BIT0: 
                if (tick_edge) next_state = DATA_BIT1;
            
            DATA_BIT1: 
                if (tick_edge) next_state = DATA_BIT2;
            
            DATA_BIT2: 
                if (tick_edge) next_state = DATA_BIT3;
            
            DATA_BIT3: 
                if (tick_edge) next_state = DATA_BIT4;
            
            DATA_BIT4: 
                if (tick_edge) next_state = DATA_BIT5;
            
            DATA_BIT5: 
                if (tick_edge) next_state = DATA_BIT6;
            
            DATA_BIT6: 
                if (tick_edge) next_state = DATA_BIT7;
            
            DATA_BIT7: 
                if (tick_edge) next_state = STOP_BIT;
            
            STOP_BIT: 
                if (tick_edge) next_state = IDLE;
            
            default: next_state = IDLE;
        endcase
    end
endmodule