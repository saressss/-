USE medical_centre;
-- E2 : Пацієнти

SET @search = NULL, @family_doctor = NULL, @age = NULL, @type = NULL, @activeness = TRUE, @gender = 'Чоловік';

SELECT patients.id AS '№', -- Загальний вивід
CONCAT(patients.last_name, ' ',patients.first_name, ' ', patients.middle_name) AS 'ПІБ', 
patients.phone AS 'Телефон', date_format(patients.birth_date, '%d.%m.%Y') AS 'Дата народж.', LEFT(patients.gender, 1) AS 'Стать', 
patient_types.name AS 'Тип', 
IFNULL(CONCAT(workers.last_name, ' ', LEFT(workers.first_name, 1), '. ', LEFT(workers.middle_name, 1), '.'), '-') AS 'Сімейний лікар',
IF(patients.is_active, 'Активний', 'Архів') AS 'Статус'
FROM patients
JOIN patient_types ON patients.patient_type_id = patient_types.id
LEFT JOIN workers ON patients.family_doctor_id = workers.id 
WHERE patients.is_active = @activeness -- За статусом
AND (@type IS NULL OR patient_types.id = @type) -- За типом
AND (@search IS NULL OR CONCAT(patients.last_name, ' ',patients.first_name, ' ', patients.middle_name) LIKE CONCAT('%', @search, '%')) -- За ПІБом
AND (@family_doctor IS NULL OR patients.family_doctor_id = @family_doctor) -- За сімейним лікарем
AND (@age IS NULL OR TIMESTAMPDIFF(YEAR, patients.birth_date, current_date()) >= @age) -- Пошук за віком
AND (@gender IS NULL OR patients.gender = @gender) -- Пошук за статтю
ORDER BY patients.id LIMIT 14 OFFSET 0; 

-- Кількість пацієнтів для пагінації («показано 1–14 з N»)
SELECT COUNT(*) AS `Усього`
FROM patients
JOIN patient_types ON patients.patient_type_id = patient_types.id
LEFT JOIN workers ON patients.family_doctor_id = workers.id
WHERE patients.is_active = @activeness
AND (@type IS NULL OR patient_types.id = @type)
AND (@search IS NULL OR CONCAT(patients.last_name, ' ', patients.first_name, ' ', patients.middle_name) LIKE CONCAT('%', @search, '%'))
AND (@family_doctor IS NULL OR patients.family_doctor_id = @family_doctor)
AND (@gender IS NULL OR patients.gender = @gender)
AND (@age IS NULL OR TIMESTAMPDIFF(YEAR, patients.birth_date, CURRENT_DATE()) >= @age);

-- Е2. Дії з кнопок (форми «Додати пацієнта», «Редагувати пацієнта», діалог деактивації)

SET @last_name = 'Мирошниченко', @first_name = 'Іван', @middle_name = 'Петрович', -- Запит 2.3. Додати пацієнта (форма «Додати пацієнта»)
    @phone = '+380671112233', @birth_date = '1989-04-17', @gender = 'Чоловік',
    @patient_type = 1, @family_doctor = 4;    -- 1 = Дорослий, 4 = Шевченко А. М. (може бути NULL)

INSERT INTO patients (last_name, first_name, middle_name, phone, birth_date, gender, patient_type_id, family_doctor_id)
VALUES (@last_name, @first_name, @middle_name, @phone, @birth_date, @gender, @patient_type, @family_doctor);

SELECT LAST_INSERT_ID() AS `Id нового пацієнта`;   -- id, який отримав новий запис

-- Запит 2.4. Редагувати пацієнта (форма «Редагувати пацієнта», № 11 — Тимошенко Л. В.)
-- Спершу форма підтягує поточні значення обраного пацієнта:
SET @id = 11;

SELECT last_name, first_name, middle_name, phone, DATE_FORMAT(birth_date, '%d.%m.%Y') AS birth_date,
       gender, patient_type_id, family_doctor_id, is_active
FROM patients
WHERE id = @id;

-- Після натискання «зберегти» оновлюються всі поля форми:
SET @last_name = 'Тимошенко', @first_name = 'Людмила', @middle_name = 'Василівна',
    @phone = '+380502229911', @birth_date = '1960-10-08', @gender = 'Жінка',
    @patient_type = 3, @family_doctor = 4;    -- змінено номер телефону

UPDATE patients
SET last_name        = @last_name,
    first_name       = @first_name,
    middle_name      = @middle_name,
    phone            = @phone,
    birth_date       = @birth_date,
    gender           = @gender,
    patient_type_id  = @patient_type,
    family_doctor_id = @family_doctor
WHERE id = @id;

-- Запит 2.5. Деактивувати пацієнта (діалог «Деактивувати пацієнта?», № 8 — Король А. В.)
-- Картку не видаляємо: прийоми, медичні записи й оплати залишаються в історії.
SET @id = 8;

UPDATE patients
SET is_active = FALSE
WHERE id = @id AND is_active = TRUE;

SELECT ROW_COUNT() AS `Деактивовано записів`;   -- 1 — успішно, 0 — пацієнт уже в архіві



-- E3: Картка пацієнта

SET @id = 11;
-- int id = 1
SELECT last_name, first_name, middle_name,
CONCAT(TIMESTAMPDIFF(YEAR, birth_date, current_date()), ' (', date_format(birth_date, '%d.%m.%Y'), ')' ) AS 'Вік', 
CONCAT(gender, '-', patient_types.name)
FROM patients
JOIN patient_types ON patients.patient_type_id = patient_types.id
WHERE patients.id = @id;

SELECT mr.id AS '№', date_format(record_date, '%d.%m.%Y') AS "Дата", CONCAT('№',a.id, ' - ', s.name) as 'Прийом',
CONCAT(w.last_name, ' ', LEFT(w.first_name, 1), '. ', LEFT(w.middle_name, 1), '.') AS 'Лікар',
SUBSTRING_INDEX(d.name)
FROM medical_records mr
LEFT JOIN appointments a ON mr.appointment_id = a.id
LEFT JOIN appointment_services a_s ON a_s.appointment_id = a.id
LEFT JOIN worker_services w_s ON a_s.worker_service_id = w_s.id
LEFT JOIN services s ON w_s.service_id = s.id
LEFT JOIN patients p ON a.patient_id = p.id
LEFT JOIN workers w ON a.worker_id = w.id
LEFT JOIN medical_record_diagnoses m_d ON m_d.medical_record_id = mr.id
LEFT JOIN diagnoses d ON m_d.diagnosis_id = d.id
WHERE p.id = @id;





