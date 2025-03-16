module send_tx_btn(
    input clk,
    input rst,
    input btn_start,
    output tx_done,
    output tx
);
    wire w_start;
    reg [7:0] send_tx_data_reg, send_tx_data_next;
    reg btn_ready_reg, btn_ready_next;
    
    // 버튼 디바운스 모듈
    btn_debounce U_Start_btn(
        .clk(clk),
        .reset(rst),
        .i_btn(btn_start),
        .o_btn(w_start)
    );
    
    // UART 모듈 인스턴스화
    uart U_UART(
        .clk(clk),
        .rst(rst),
        .btn_start(w_start && btn_ready_reg),
        .tx_data_in(send_tx_data_reg),
        .tx_done(tx_done),
        .tx(tx)
    );
    
    // 레지스터 업데이트 로직
    always @(posedge clk, posedge rst) begin
        if(rst) begin
            send_tx_data_reg <= 8'h30; // "0" ASCII 코드
            btn_ready_reg <= 1'b1; // 초기에는 준비 상태
        end else begin
            send_tx_data_reg <= send_tx_data_next;
            btn_ready_reg <= btn_ready_next;
        end
    end
    
    // 다음 데이터 계산 로직
    always @(*) begin
        send_tx_data_next = send_tx_data_reg;
        btn_ready_next = btn_ready_reg;
        
        if(w_start && btn_ready_reg) begin
            // 버튼 입력 처리 중 상태로 변경
            btn_ready_next = 1'b0;
            
            if(send_tx_data_reg == 8'h7A) begin // "z" ASCII 코드
                send_tx_data_next = 8'h30; // "0"로
            end else begin
                send_tx_data_next = send_tx_data_reg + 1; // ASCII 코드값 + 1
            end
        end
        
        // 전송 완료 시 버튼 준비 상태로 복귀
        if(tx_done && !btn_ready_reg) begin
            btn_ready_next = 1'b1;
        end
    end
endmodule