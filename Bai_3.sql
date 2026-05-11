DROP PROCEDURE IF EXISTS DispenseMedicine;

DELIMITER //
CREATE PROCEDURE DispenseMedicine(
    IN p_patient_id INT, 
    IN p_medicine_id INT, 
    IN p_quantity INT, 
    OUT p_status_message VARCHAR(255)
)
BEGIN
    DECLARE v_stock INT;
    DECLARE v_price DECIMAL(18,2);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_status_message = 'Lỗi hệ thống: Quá trình cấp phát thuốc bị hủy bỏ.';
    END;

    START TRANSACTION;
    SELECT stock, price INTO v_stock, v_price 
    FROM Medicines 
    WHERE medicine_id = p_medicine_id;

    IF v_stock IS NULL THEN
        SET p_status_message = 'Lỗi: Thuốc không tồn tại trong hệ thống.';
        ROLLBACK;
    ELSEIF v_stock < p_quantity THEN
        SET p_status_message = 'Lỗi: Số lượng tồn kho không đủ.';
        ROLLBACK;
    ELSE
    
        UPDATE Medicines 
        SET stock = stock - p_quantity 
        WHERE medicine_id = p_medicine_id;
        
        UPDATE Patient_Invoices 
        SET total_due = total_due + (v_price * p_quantity)
        WHERE patient_id = p_patient_id;

        COMMIT;
        SET p_status_message = 'Đã cấp phát thành công.';
    END IF;
END
// DELIMITER ;

-- Trường hợp 1: Cấp phát hợp lệ (Bệnh nhân 1 mua 10 viên Amoxicillin)
SET @message1 = '';
CALL DispenseMedicine(1, 1, 10, @message1);
SELECT @message1 AS 'Trạng thái';
SELECT stock FROM Medicines WHERE medicine_id = 1; -- Kiểm tra kho giảm
SELECT total_due FROM Patient_Invoices WHERE patient_id = 1; -- Kiểm tra nợ tăng

-- Trường hợp 2: Chặn lỗi khi vượt quá tồn kho (Bệnh nhân 1 mua 10 viên Panadol trong khi chỉ còn 5)
SET @message2 = '';
CALL DispenseMedicine(1, 2, 10, @message2);
SELECT @message2 AS 'Trạng thái';
SELECT stock FROM Medicines WHERE medicine_id = 2; -- Kho vẫn giữ nguyên là 5