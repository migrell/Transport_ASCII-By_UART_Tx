module precise_baud_generator (
    input clk,
    input rst,
    output baud_tick,
    output sample_tick
);
    // 고정된 9600 보드레이트에 맞춘 정밀 분주 파라미터
    parameter CLOCK_RATE = 100000000;  // 100MHz
    parameter BAUD_RATE = 9600;
    
    // 더 정밀한 카운트 값 계산
    localparam INTEGER_COUNT = CLOCK_RATE / BAUD_RATE;  // 10416
    localparam FRACTIONAL_BITS = 8;  // 분수 정밀도 비트 수
    localparam FRACTIONAL_INCREMENT = ((CLOCK_RATE % BAUD_RATE) << FRACTIONAL_BITS) / BAUD_RATE;
    
    // 카운터 레지스터
    reg [$clog2(INTEGER_COUNT)-1:0] int_count;
    reg [FRACTIONAL_BITS-1:0] frac_count;
    
    // 출력 레지스터
    reg baud_tick_reg, sample_tick_reg;
    
    // 비트 중앙 샘플링 포인트 (정확히 1/2 지점)
    localparam SAMPLE_POINT = INTEGER_COUNT / 2;
    
    // 출력 할당
    assign baud_tick = baud_tick_reg;
    assign sample_tick = sample_tick_reg;
    
    // 정밀 보드레이트 생성 로직
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            int_count <= 0;
            frac_count <= 0;
            baud_tick_reg <= 0;
            sample_tick_reg <= 0;
        end else begin
            // 기본값 초기화
            baud_tick_reg <= 1'b0;
            sample_tick_reg <= 1'b0;
            
            // 정수 카운터가 0에 도달하면 틱 생성
            if (int_count == 0) begin
                // 분수 카운터 업데이트 및 오버플로 처리
                {int_count, frac_count} <= {INTEGER_COUNT-1, frac_count} + {13'b0, FRACTIONAL_INCREMENT};
                baud_tick_reg <= 1'b1;  // 비트 경계 틱 생성
            end else begin
                // 일반적인 카운트 다운
                int_count <= int_count - 1;
                
                // 비트 중앙 샘플링 틱 생성
                if (int_count == SAMPLE_POINT)
                    sample_tick_reg <= 1'b1;
            end
        end
    end
endmodule