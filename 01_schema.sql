DROP DATABASE IF EXISTS medical_centre;
CREATE DATABASE medical_centre CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE medical_centre;

CREATE TABLE specialities (
    id    INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Ідентифікатор спеціальності',
    name  VARCHAR(25) NOT NULL COMMENT 'Назва спеціальності',
    
    CONSTRAINT uq_specialities_name UNIQUE (name)
) ENGINE = InnoDB COMMENT = 'Довідник спеціальностей лікарів';

CREATE TABLE roles (
    id    INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Ідентифікатор ролі',
    name  VARCHAR(25) NOT NULL COMMENT 'Назва ролі',
    
    CONSTRAINT uq_roles_name UNIQUE (name)
) ENGINE = InnoDB COMMENT = 'Довідник ролей користувачів системи';

CREATE TABLE services (
    id    INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Ідентифікатор послуги',
    name  VARCHAR(50) NOT NULL COMMENT 'Назва послуги',
    
    CONSTRAINT uq_services_name UNIQUE (name)
) ENGINE = InnoDB COMMENT = 'Довідник медичних послуг центру';

CREATE TABLE patient_types (
    id    INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Ідентифікатор типу пацієнта',
    name  VARCHAR(25) NOT NULL COMMENT 'Назва типу пацієнта',
    
    CONSTRAINT uq_patient_types_name UNIQUE (name)
) ENGINE = InnoDB COMMENT = 'Довідник типів пацієнтів';

CREATE TABLE diagnoses (
    id    INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Ідентифікатор діагнозу',
    name  VARCHAR(100) NOT NULL COMMENT 'Код МКХ-10 і назва діагнозу',
    
    CONSTRAINT uq_diagnoses_name UNIQUE (name)
) ENGINE = InnoDB COMMENT = 'Довідник діагнозів';

CREATE TABLE consumables (
    id         INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Ідентифікатор матеріалу',
    name       VARCHAR(50)   NOT NULL COMMENT 'Назва медикаменту або матеріалу',
    unit_cost  DECIMAL(10,2) NOT NULL COMMENT 'Вартість одиниці, грн',
    
    CONSTRAINT uq_consumables_name UNIQUE (name),
    CONSTRAINT chk_consumables_unit_cost CHECK (unit_cost > 0)
) ENGINE = InnoDB COMMENT = 'Довідник медикаментів і витратних матеріалів';

CREATE TABLE treatment_types (
    id    INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Ідентифікатор виду лікування',
    name  VARCHAR(100) NOT NULL COMMENT 'Назва виду лікування',
    
    CONSTRAINT uq_treatment_types_name UNIQUE (name)
) ENGINE = InnoDB COMMENT = 'Довідник видів лікування';

CREATE TABLE counterparties (
    id     INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Ідентифікатор контрагента',
    name   VARCHAR(100) NOT NULL COMMENT 'Назва організації',
    phone  VARCHAR(13)  NULL     COMMENT 'Телефон у форматі +380XXXXXXXXX',
    
    CONSTRAINT uq_counterparties_name UNIQUE (name),
    CONSTRAINT chk_counterparties_phone CHECK (phone REGEXP '^\\+380[0-9]{9}$')
) ENGINE = InnoDB COMMENT = 'Контрагенти: лабораторії, постачальники, сервісні організації, клієнти';

CREATE TABLE warehouses (
    id    INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Ідентифікатор складу',
    name  VARCHAR(100) NOT NULL COMMENT 'Назва складу або кабінету',
    
    CONSTRAINT uq_warehouses_name UNIQUE (name)
) ENGINE = InnoDB COMMENT = 'Місця зберігання матеріалів і техніки';

CREATE TABLE analyses (
    id               INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Ідентифікатор аналізу',
    name             VARCHAR(100) NOT NULL COMMENT 'Назва аналізу',
    counterparty_id  INT NULL COMMENT 'Лабораторія-виконавець (NULL — виконується в центрі)',
    
    CONSTRAINT uq_analyses_name UNIQUE (name),
    CONSTRAINT fk_analyses_counterparties FOREIGN KEY (counterparty_id)
        REFERENCES counterparties (id) 
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE = InnoDB COMMENT = 'Довідник аналізів';

CREATE TABLE workers (
    id             INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Ідентифікатор працівника',
    last_name      VARCHAR(50) NOT NULL COMMENT 'Прізвище',
    first_name     VARCHAR(50) NOT NULL COMMENT 'Ім''я',
    middle_name    VARCHAR(50) NOT NULL COMMENT 'По батькові',
    gender         ENUM('Чоловік', 'Жінка') NOT NULL COMMENT 'Стать',
    birth_date     DATE        NOT NULL COMMENT 'Дата народження',
    phone          VARCHAR(13) NOT NULL COMMENT 'Телефон у форматі +380XXXXXXXXX',
    email          VARCHAR(50) NOT NULL COMMENT 'Електронна пошта',
    speciality_id  INT NULL COMMENT 'Спеціальність (лише для лікарів)',
    role_id        INT NOT NULL COMMENT 'Роль у системі',
    login          VARCHAR(50) NOT NULL COMMENT 'Логін для входу',
    password_hash  CHAR(60)    NOT NULL COMMENT 'Хеш пароля (bcrypt)',
    is_blocked     BOOLEAN     NOT NULL DEFAULT FALSE COMMENT 'TRUE — працівника звільнено, вхід заблоковано',
    
    CONSTRAINT uq_workers_phone UNIQUE (phone),
    CONSTRAINT uq_workers_email UNIQUE (email),
    CONSTRAINT uq_workers_login UNIQUE (login),
    CONSTRAINT chk_workers_phone CHECK (phone REGEXP '^\\+380[0-9]{9}$'),
    CONSTRAINT fk_workers_specialities FOREIGN KEY (speciality_id)
        REFERENCES specialities (id) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE,
    CONSTRAINT fk_workers_roles FOREIGN KEY (role_id)
        REFERENCES roles (id) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE
) ENGINE = InnoDB COMMENT = 'Працівники центру та їхні облікові записи';

CREATE TABLE worker_services (
    id          INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Ідентифікатор позиції прайс-листа',
    worker_id   INT NOT NULL COMMENT 'Лікар',
    service_id  INT NOT NULL COMMENT 'Послуга',
    price       DECIMAL(7,2) NOT NULL COMMENT 'Поточна ціна послуги в цього лікаря, грн',
    is_active   BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'FALSE — послугу знято з прайс-листа',
    
    CONSTRAINT uq_worker_services UNIQUE (worker_id, service_id),
    CONSTRAINT chk_worker_services_price CHECK (price > 0),
    CONSTRAINT fk_worker_services_workers FOREIGN KEY (worker_id)
        REFERENCES workers (id) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE,
    CONSTRAINT fk_worker_services_services FOREIGN KEY (service_id)
        REFERENCES services (id) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE
) ENGINE = InnoDB COMMENT = 'Прайс-лист: послуги лікарів і їхні ціни (зв''язок M:N)';

CREATE TABLE worker_schedules (
    id          INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Ідентифікатор зміни',
    worker_id   INT  NOT NULL COMMENT 'Працівник',
    work_date   DATE NOT NULL COMMENT 'Робочий день',
    start_time  TIME NOT NULL COMMENT 'Початок зміни',
    end_time    TIME NOT NULL COMMENT 'Кінець зміни',
    
    CONSTRAINT uq_worker_schedules UNIQUE (worker_id, work_date),
    CONSTRAINT chk_worker_schedules_time CHECK (start_time < end_time),
    CONSTRAINT fk_worker_schedules_workers FOREIGN KEY (worker_id)
        REFERENCES workers (id) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE
) ENGINE = InnoDB COMMENT = 'Графік роботи працівників';

CREATE TABLE patients (
    id                INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Ідентифікатор пацієнта',
    last_name         VARCHAR(50) NOT NULL COMMENT 'Прізвище',
    first_name        VARCHAR(50) NOT NULL COMMENT 'Ім''я',
    middle_name       VARCHAR(50) NOT NULL COMMENT 'По батькові',
    gender            ENUM('Чоловік', 'Жінка') NOT NULL COMMENT 'Стать',
    birth_date        DATE        NOT NULL COMMENT 'Дата народження (вік обчислюється)',
    phone             VARCHAR(13) NOT NULL COMMENT 'Телефон (не унікальний: у дитини — телефон батьків)',
    patient_type_id   INT NOT NULL COMMENT 'Тип пацієнта',
    family_doctor_id  INT NULL COMMENT 'Сімейний лікар (посилання на workers)',
    is_active         BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'FALSE — картку деактивовано',
    
    CONSTRAINT chk_patients_phone CHECK (phone REGEXP '^\\+380[0-9]{9}$'),
    CONSTRAINT fk_patients_patient_types FOREIGN KEY (patient_type_id)
        REFERENCES patient_types (id) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE,
    CONSTRAINT fk_patients_workers FOREIGN KEY (family_doctor_id)
        REFERENCES workers (id)
        ON DELETE RESTRICT 
        ON UPDATE CASCADE
) ENGINE = InnoDB COMMENT = 'Пацієнти медичного центру';

CREATE TABLE appointments (
    id            INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Ідентифікатор запису на прийом',
    patient_id    INT      NOT NULL COMMENT 'Пацієнт',
    worker_id     INT      NOT NULL COMMENT 'Лікар',
    starts_at     DATETIME NOT NULL COMMENT 'Дата й час початку прийому',
    duration_min  INT      NOT NULL COMMENT 'Тривалість, хв',
    status        ENUM('Заплановано', 'Відмінено', 'Закінчено', 'Не з''явився')
                  NOT NULL DEFAULT 'Заплановано' COMMENT 'Стан запису',
                  
    CONSTRAINT chk_appointments_duration CHECK (duration_min > 0),
    CONSTRAINT fk_appointments_patients FOREIGN KEY (patient_id)
        REFERENCES patients (id) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE,
    CONSTRAINT fk_appointments_workers FOREIGN KEY (worker_id)
        REFERENCES workers (id) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE
) ENGINE = InnoDB COMMENT = 'Записи пацієнтів на прийом';

CREATE TABLE appointment_services (
    id                 INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Ідентифікатор рядка',
    appointment_id     INT NOT NULL COMMENT 'Запис на прийом',
    worker_service_id  INT NOT NULL COMMENT 'Позиція прайс-листа лікаря',
    price              DECIMAL(10,2) NOT NULL COMMENT 'Ціна на момент запису, грн',
    
    CONSTRAINT uq_appointment_services UNIQUE (appointment_id, worker_service_id),
    CONSTRAINT chk_appointment_services_price CHECK (price >= 0),
    CONSTRAINT fk_appointment_services_appointments FOREIGN KEY (appointment_id)
        REFERENCES appointments (id) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
    CONSTRAINT fk_appointment_services_worker_services FOREIGN KEY (worker_service_id)
        REFERENCES worker_services (id) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE
) ENGINE = InnoDB COMMENT = 'Послуги прийому з зафіксованою ціною (зв''язок M:N)';


CREATE TABLE contracts (
    id               INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Ідентифікатор договору',
    number           VARCHAR(50) NOT NULL COMMENT 'Номер договору',
    counterparty_id  INT  NOT NULL COMMENT 'Контрагент',
    direction        ENUM('Оплата', 'Дохід') NOT NULL COMMENT 'Оплата — платить центр; Дохід — платять центру',
    amount           DECIMAL(12,2) NOT NULL COMMENT 'Сума договору, грн',
    start_date       DATE NOT NULL COMMENT 'Початок дії',
    end_date         DATE NOT NULL COMMENT 'Закінчення дії',
    
    CONSTRAINT uq_contracts_number UNIQUE (number),
    CONSTRAINT chk_contracts_amount CHECK (amount > 0),
    CONSTRAINT chk_contracts_dates CHECK (start_date < end_date),
    CONSTRAINT fk_contracts_counterparties FOREIGN KEY (counterparty_id)
        REFERENCES counterparties (id) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE
) ENGINE = InnoDB COMMENT = 'Договори з контрагентами';

CREATE TABLE transactions (
    id                INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Ідентифікатор транзакції',
    transaction_type  ENUM('Дохід', 'Витрата') NOT NULL COMMENT 'Надходження чи витрата',
    amount            DECIMAL(12,2) NOT NULL COMMENT 'Сума, грн',
    transaction_date  DATE NOT NULL COMMENT 'Дата',
    purpose           VARCHAR(100) NOT NULL COMMENT 'Призначення платежу',
    appointment_id    INT NULL COMMENT 'Прийом, за який оплачено (для оплат пацієнтів)',
    contract_id       INT NULL COMMENT 'Договір, за яким проведено платіж',
    
    CONSTRAINT chk_transactions_amount CHECK (amount > 0),
    CONSTRAINT chk_transactions_one_source CHECK (appointment_id IS NULL OR contract_id IS NULL),
    CONSTRAINT fk_transactions_appointments FOREIGN KEY (appointment_id)
        REFERENCES appointments (id) 
        ON DELETE RESTRICT 
        ON UPDATE RESTRICT,
    CONSTRAINT fk_transactions_contracts FOREIGN KEY (contract_id)
        REFERENCES contracts (id) 
        ON DELETE RESTRICT 
        ON UPDATE RESTRICT
) ENGINE = InnoDB COMMENT = 'Фінансові транзакції: надходження та витрати';

CREATE TABLE medical_records (
    id              INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Ідентифікатор медичного запису',
    appointment_id  INT  NOT NULL COMMENT 'Прийом, за результатами якого створено запис',
    record_date     DATE NOT NULL COMMENT 'Дата створення',
    
    CONSTRAINT uq_medical_records_appointment UNIQUE (appointment_id),
    CONSTRAINT fk_medical_records_appointments FOREIGN KEY (appointment_id)
        REFERENCES appointments (id) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE
) ENGINE = InnoDB COMMENT = 'Медичні записи за результатами прийомів';

CREATE TABLE medical_record_diagnoses (
    id                 INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Ідентифікатор рядка',
    medical_record_id  INT NOT NULL COMMENT 'Медичний запис',
    diagnosis_id       INT NOT NULL COMMENT 'Діагноз',
    
    CONSTRAINT uq_medical_record_diagnoses UNIQUE (medical_record_id, diagnosis_id),
    CONSTRAINT fk_medical_record_diagnoses_medical_records FOREIGN KEY (medical_record_id)
        REFERENCES medical_records (id) 
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_medical_record_diagnoses_diagnoses FOREIGN KEY (diagnosis_id)
        REFERENCES diagnoses (id) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE
) ENGINE = InnoDB COMMENT = 'Діагнози медичного запису (зв''язок M:N)';

CREATE TABLE medical_record_analyses (
    id                 INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Ідентифікатор рядка',
    medical_record_id  INT NOT NULL COMMENT 'Медичний запис',
    analysis_id        INT NOT NULL COMMENT 'Аналіз',
    result             VARCHAR(100) NULL COMMENT 'Результат (NULL — ще не надійшов)',
    
    CONSTRAINT uq_medical_record_analyses UNIQUE (medical_record_id, analysis_id),
    CONSTRAINT fk_medical_record_analyses_medical_records FOREIGN KEY (medical_record_id)
        REFERENCES medical_records (id) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
    CONSTRAINT fk_medical_record_analyses_analyses FOREIGN KEY (analysis_id)
        REFERENCES analyses (id) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE
) ENGINE = InnoDB COMMENT = 'Аналізи медичного запису та їхні результати (зв''язок M:N)';

CREATE TABLE medical_record_treatments (
    id                 INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Ідентифікатор рядка',
    medical_record_id  INT NOT NULL COMMENT 'Медичний запис',
    treatment_type_id  INT NOT NULL COMMENT 'Вид лікування',
    description        VARCHAR(100) NULL COMMENT 'Призначення: препарат, дозування, курс',
    
    CONSTRAINT fk_medical_record_treatments_medical_records FOREIGN KEY (medical_record_id)
        REFERENCES medical_records (id) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
    CONSTRAINT fk_medical_record_treatments_treatment_types FOREIGN KEY (treatment_type_id)
        REFERENCES treatment_types (id) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE
) ENGINE = InnoDB COMMENT = 'Лікування, призначене в медичному записі';

CREATE TABLE sick_leaves (
    id                 INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Ідентифікатор лікарняного',
    medical_record_id  INT  NOT NULL COMMENT 'Медичний запис, за яким видано лікарняний',
    start_date         DATE NOT NULL COMMENT 'Початок',
    end_date           DATE NOT NULL COMMENT 'Закінчення',
    
    CONSTRAINT uq_sick_leaves_medical_record UNIQUE (medical_record_id),
    CONSTRAINT chk_sick_leaves_dates CHECK (start_date <= end_date),
    CONSTRAINT fk_sick_leaves_medical_records FOREIGN KEY (medical_record_id)
        REFERENCES medical_records (id) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE
) ENGINE = InnoDB COMMENT = 'Лікарняні листи (зв''язок 1:1 з медичним записом)';

CREATE TABLE stock_batches (
    id                  INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Ідентифікатор партії',
    consumable_id       INT  NOT NULL COMMENT 'Матеріал',
    warehouse_id        INT  NOT NULL COMMENT 'Місце зберігання',
    transaction_id      INT  NOT NULL COMMENT 'Транзакція закупівлі',
    initial_quantity    INT  NOT NULL COMMENT 'Кількість при надходженні',
    remaining_quantity  INT  NOT NULL COMMENT 'Поточний залишок',
    expiration_date     DATE NOT NULL COMMENT 'Термін придатності',
    status              ENUM('В наявності', 'В дорозі', 'Закінчилась') NOT NULL COMMENT 'Стан партії',
    storage_conditions  VARCHAR(50) NULL COMMENT 'Особливі умови зберігання',
    
    CONSTRAINT chk_stock_batches_initial CHECK (initial_quantity > 0),
    CONSTRAINT chk_stock_batches_remaining CHECK (remaining_quantity BETWEEN 0 AND initial_quantity),
    CONSTRAINT fk_stock_batches_consumables FOREIGN KEY (consumable_id)
        REFERENCES consumables (id) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE,
    CONSTRAINT fk_stock_batches_warehouses FOREIGN KEY (warehouse_id)
        REFERENCES warehouses (id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_stock_batches_transactions FOREIGN KEY (transaction_id)
        REFERENCES transactions (id) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE
) ENGINE = InnoDB COMMENT = 'Партії матеріалів на складі';

CREATE TABLE utilizations (
    id              INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Ідентифікатор запису використання',
    stock_batch_id  INT  NOT NULL COMMENT 'Партія',
    appointment_id  INT  NULL     COMMENT 'Прийом (NULL — використано поза прийомом)',
    worker_id       INT  NOT NULL COMMENT 'Працівник, який зафіксував використання',
    quantity        INT  NOT NULL COMMENT 'Кількість',
    used_on         DATE NOT NULL COMMENT 'Дата використання',
    
    CONSTRAINT chk_utilizations_quantity CHECK (quantity > 0),
    CONSTRAINT fk_utilizations_stock_batches FOREIGN KEY (stock_batch_id)
        REFERENCES stock_batches (id) 
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_utilizations_appointments FOREIGN KEY (appointment_id)
        REFERENCES appointments (id) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE,
    CONSTRAINT fk_utilizations_workers FOREIGN KEY (worker_id)
        REFERENCES workers (id) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE
) ENGINE = InnoDB COMMENT = 'Журнал використання матеріалів з партій';

CREATE TABLE medical_devices (
    id                  INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Ідентифікатор одиниці техніки',
    name                VARCHAR(50) NOT NULL COMMENT 'Назва',
    producer            VARCHAR(30) NOT NULL COMMENT 'Виробник',
    serial_number       VARCHAR(25) NOT NULL COMMENT 'Серійний номер',
    license_number      VARCHAR(30) NOT NULL COMMENT 'Номер ліцензії',
    license_expires_on  DATE        NOT NULL COMMENT 'Дата завершення ліцензії',
    status              ENUM('Працює', 'Зламано', 'Обслуговується') NOT NULL COMMENT 'Поточний стан',
    service_phone       VARCHAR(13) NOT NULL COMMENT 'Телефон сервісної служби',
    warehouse_id        INT NOT NULL COMMENT 'Місце розташування',
    
    CONSTRAINT uq_medical_devices_serial UNIQUE (serial_number),
    CONSTRAINT uq_medical_devices_license UNIQUE (license_number),
    CONSTRAINT chk_medical_devices_phone CHECK (service_phone REGEXP '^\\+380[0-9]{9}$'),
    CONSTRAINT fk_medical_devices_warehouses FOREIGN KEY (warehouse_id)
        REFERENCES warehouses (id) 
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE = InnoDB COMMENT = 'Медична техніка центру';

CREATE TABLE appointment_devices (
    id                 INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Ідентифікатор рядка',
    appointment_id     INT NOT NULL COMMENT 'Запис на прийом',
    medical_device_id  INT NOT NULL COMMENT 'Використана техніка',
    
    CONSTRAINT uq_appointment_devices UNIQUE (appointment_id, medical_device_id),
    CONSTRAINT fk_appointment_devices_appointments FOREIGN KEY (appointment_id)
        REFERENCES appointments (id) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
    CONSTRAINT fk_appointment_devices_medical_devices FOREIGN KEY (medical_device_id)
        REFERENCES medical_devices (id) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE
) ENGINE = InnoDB COMMENT = 'Техніка, використана під час прийому (зв''язок M:N)';

CREATE TABLE device_maintenances (
    id                 INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Ідентифікатор обслуговування',
    medical_device_id  INT  NOT NULL COMMENT 'Одиниця техніки',
    maintenance_type   ENUM('Огляд', 'Ремонт') NOT NULL COMMENT 'Вид робіт',
    service_date       DATE NOT NULL COMMENT 'Дата обслуговування',
    description        VARCHAR(100) NOT NULL COMMENT 'Опис виконаних робіт',
    next_service_date  DATE NULL COMMENT 'Дата наступного планового огляду',
    transaction_id     INT  NOT NULL COMMENT 'Транзакція оплати робіт',
    
    CONSTRAINT chk_device_maintenances_next CHECK (next_service_date > service_date),
    CONSTRAINT fk_device_maintenances_medical_devices FOREIGN KEY (medical_device_id)
        REFERENCES medical_devices (id) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE,
    CONSTRAINT fk_device_maintenances_transactions FOREIGN KEY (transaction_id)
        REFERENCES transactions (id) 
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE = InnoDB COMMENT = 'Журнал технічних оглядів і ремонтів';

CREATE INDEX ix_patients_name ON patients (last_name, first_name);
CREATE INDEX ix_appointments_worker_starts ON appointments (worker_id, starts_at);
CREATE INDEX ix_transactions_date ON transactions (transaction_date);
CREATE INDEX ix_stock_batches_expiration ON stock_batches (expiration_date);
