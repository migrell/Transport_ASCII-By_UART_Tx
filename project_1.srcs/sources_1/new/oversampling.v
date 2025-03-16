module uart_rx_with_oversampling (
    input clk,
    input rst,
    input rx,
    output [7:0] data_out,
    output data_ready
);
    // 상태 정의
    parameter IDLE = 3'b000, START = 3'b001, DATA = 3'b010, STOP = 3'b011;
    
    // 16배 오버샘플링 설정
    parameter OVERSAMPLE = 16;
    parameter SAMPLE_POINT = OVERSAMPLE / 2;     // 비트 중앙
    
    // 레지스터 선언
    reg [2:0] state, next_state;
    reg [7:0] data_reg, data_next;
    reg [3:0] sample_counter;    // 오버샘플링 카운터
    reg [2:0] bit_counter;       // 비트 카운터
    reg data_ready_reg;
    
    // RX 신호 안정화를 위한 시프트 레지스터
    reg [1:0] rx_sync;
    wire rx_filtered;
    
    // 노이즈 필터링을 위한 다수결 검출
    reg [2:0] majority_counter;
    
    // 출력 할당
    assign data_out = data_reg;
    assign data_ready = data_ready_reg;
    assign rx_filtered = rx_sync[0];
    
    // 동기화 및 노이즈 필터링
    always @(posedge clk) begin
        if (rst) begin
            rx_sync <= 2'b11;
            majority_counter <= 3'b000;
        end else begin
            // 2단계 동기화
            rx_sync <= {rx, rx_sync[1]};
            
            // 다수결 카운터 업데이트
            if (rx_sync[0])
                majority_counter <= (majority_counter == 3'b111) ? 3'b111 : majority_counter + 1;
            else
                majority_counter <= (majority_counter == 3'b000) ? 3'b000 : majority_counter - 1;
        end
    end
    
    // 상태 및 데이터 업데이트
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            data_reg <= 8'h00;
            sample_counter <= 0;
            bit_counter <= 0;
            data_ready_reg <= 1'b0;
        end else begin
            state <= next_state;
            data_reg <= data_next;
            
            // 데이터 준비 신호 펄스 생성
            if (state == STOP && next_state == IDLE)
                data_ready_reg <= 1'b1;
            else
                data_ready_reg <= 1'b0;
                
            // 오버샘플링 카운터 관리
            if (state == IDLE) begin
                sample_counter <= 0;
                bit_counter <= 0;
            end else begin
                sample_counter <= (sample_counter == OVERSAMPLE-1) ? 0 : sample_counter + 1;
                
                // 비트 카운터 업데이트 (한 비트 완료 시)
                if (sample_counter == OVERSAMPLE-1 && state == DATA)
                    bit_counter <= bit_counter + 1;
            end
        end
    end
    
    // 상태 전이 및 데이터 샘플링 로직
    always @(*) begin
        next_state = state;
        data_next = data_reg;
        
        case (state)
            IDLE: begin
                // 시작 비트(0) 검출
                if (rx_filtered == 1'b0)
                    next_state = START;
            end
            
            START: begin
                // 비트 중앙에서 시작 비트 재확인
                if (sample_counter == SAMPLE_POINT) begin
                    if (rx_filtered == 1'b0)  // 유효한 시작 비트
                        next_state = DATA;
                    else                       // 잘못된 시작 비트
                        next_state = IDLE;
                end
            end
            
            DATA: begin
                // 각 비트의 중앙에서 데이터 샘플링
                if (sample_counter == SAMPLE_POINT)
                    data_next[bit_counter] = rx_filtered;
                
                // 8비트 모두 수신 완료
                if (bit_counter == 7 && sample_counter == OVERSAMPLE-1)
                    next_state = STOP;
            end
            
            STOP: begin
                // 정지 비트 확인 (중앙에서)
                if (sample_counter == SAMPLE_POINT) begin
                    if (rx_filtered == 1'b1)  // 유효한 정지 비트
                        next_state = IDLE;
                    else                      // 프레이밍 에러
                        next_state = IDLE;    // 에러 처리 로직 추가 가능
                end
            end
            
            default: next_state = IDLE;
        endcase
    end
endmodule