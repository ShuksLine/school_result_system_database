CREATE DATABASE school_result_system;
USE school_result_system;

CREATE TABLE id_counter (
  prefix  VARCHAR(10)  NOT NULL PRIMARY KEY,
  next_no INT UNSIGNED NOT NULL DEFAULT 1
) ENGINE=InnoDB;

CREATE TABLE school_profile (
  school_id           VARCHAR(20)  NOT NULL DEFAULT '' PRIMARY KEY,
  school_name         VARCHAR(150) NOT NULL,
  rc_number           VARCHAR(30)  NULL,
  tagline             VARCHAR(150) NULL,
  address             VARCHAR(255) NULL,
  phone               VARCHAR(30)  NULL,
  email               VARCHAR(120) NULL,
  logo_path           VARCHAR(255) NULL,
  head_of_school_name VARCHAR(120) NULL,
  head_signature_path VARCHAR(255) NULL
) ENGINE=InnoDB;

CREATE TABLE web_role  (
  role_id   VARCHAR(20) NOT NULL DEFAULT '' PRIMARY KEY,
  role_name VARCHAR(30) NOT NULL UNIQUE
    CHECK (role_name IN ('ADMIN_USER','TEACHER','STUDENT','PARENT'))
) ENGINE=InnoDB;

CREATE TABLE admin_user(
  admin_id       VARCHAR(20) NOT NULL DEFAULT '' PRIMARY KEY,
  surname        VARCHAR(60) NOT NULL,
  first_name     VARCHAR(60) NOT NULL,
  other_names    VARCHAR(80) NULL,
  gender         ENUM('Male','Female') NULL,
  phone          VARCHAR(30) NULL,
  email          VARCHAR(120) NULL,
  signature_path VARCHAR(255) NULL,
  is_active      TINYINT(1)  NOT NULL DEFAULT 1,
  created_at     TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE teacher (
  teacher_id     VARCHAR(20) NOT NULL DEFAULT '' PRIMARY KEY,
  employment_no   VARCHAR(30) NULL UNIQUE,
  surname        VARCHAR(60) NOT NULL,
  first_name     VARCHAR(60) NOT NULL,
  other_names    VARCHAR(80) NULL,
  gender         ENUM('Male','Female') NULL,
  phone          VARCHAR(30) NULL,
  email          VARCHAR(120) NULL,
  signature_path VARCHAR(255) NULL,   
  is_active      TINYINT(1)  NOT NULL DEFAULT 1,
  created_at     TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE parent_guardian (
  parent_id   VARCHAR(20) NOT NULL DEFAULT '' PRIMARY KEY,
  surname     VARCHAR(60) NOT NULL,
  first_name  VARCHAR(60) NOT NULL,
  other_names VARCHAR(80) NULL,
  phone       VARCHAR(30) NULL,
  email       VARCHAR(120) NULL,
  address     VARCHAR(255) NULL,
  created_at  TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_parent_phone (phone)
) ENGINE=InnoDB;

CREATE TABLE user_account (
  user_id       VARCHAR(20)  NOT NULL DEFAULT '' PRIMARY KEY,
  username      VARCHAR(60)  NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  role_id       VARCHAR(20)  NOT NULL,
  admin_id      VARCHAR(20)  NULL,
  teacher_id    VARCHAR(20)  NULL,
  parent_id     VARCHAR(20)  NULL,
  is_active     TINYINT(1)   NOT NULL DEFAULT 1,
  last_login_at DATETIME     NULL,
  created_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_user_role    FOREIGN KEY (role_id)    REFERENCES web_role (role_id),
  CONSTRAINT fk_user_admin   FOREIGN KEY (admin_id)   REFERENCES admin_user (admin_id),
  CONSTRAINT fk_user_teacher FOREIGN KEY (teacher_id) REFERENCES teacher (teacher_id),
  CONSTRAINT fk_user_parent  FOREIGN KEY (parent_id)  REFERENCES parent_guardian (parent_id),
  CONSTRAINT chk_user_one_person CHECK (
    (admin_id IS NOT NULL) + (teacher_id IS NOT NULL) + (parent_id IS NOT NULL) = 1)
) ENGINE=InnoDB;

CREATE TABLE student(
  student_id     VARCHAR(20) NOT NULL DEFAULT '' PRIMARY KEY,  
  admission_no   VARCHAR(30) NOT NULL UNIQUE,               
  surname        VARCHAR(60) NOT NULL,
  first_name     VARCHAR(60) NOT NULL,
  other_names    VARCHAR(80) NULL,
  date_of_birth  DATE        NOT NULL,
  gender         ENUM('Male','Female') NOT NULL,
  admission_date DATE        NULL,
  status         ENUM('active','graduated','withdrawn') NOT NULL DEFAULT 'active',
  photo_path     VARCHAR(255) NULL,
  created_at     TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_student_name (surname, first_name)
) ENGINE=InnoDB;

CREATE TABLE student_parent_link (
  link_id      VARCHAR(20) NOT NULL DEFAULT '' PRIMARY KEY,
  student_id   VARCHAR(20) NOT NULL,
  parent_id    VARCHAR(20) NOT NULL,
  relationship ENUM('Father','Mother','Guardian','Other') NOT NULL DEFAULT 'Guardian',
  is_primary   TINYINT(1)  NOT NULL DEFAULT 0,
  UNIQUE KEY uq_student_parent (student_id, parent_id),
  CONSTRAINT fk_link_student FOREIGN KEY (student_id) REFERENCES student (student_id),
  CONSTRAINT fk_link_parent  FOREIGN KEY (parent_id)  REFERENCES parent_guardian (parent_id)
) ENGINE=InnoDB;


-- Academic Structure below

CREATE TABLE academic_session (
  session_id   VARCHAR(20) NOT NULL DEFAULT '' PRIMARY KEY,
  session_name VARCHAR(9)  NOT NULL UNIQUE, 
  start_date   DATE NULL,
  end_date     DATE NULL,
  is_current   TINYINT(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB;

CREATE TABLE term(
  term_id      VARCHAR(20) NOT NULL DEFAULT '' PRIMARY KEY,
  term_no      TINYINT UNSIGNED NOT NULL UNIQUE,
  term_name    VARCHAR(20) NOT NULL UNIQUE,         
  term_word    VARCHAR(10) NOT NULL,                   
  term_ordinal VARCHAR(5)  NOT NULL                    
) ENGINE=InnoDB;

CREATE TABLE grading_scale (
  scale_id   VARCHAR(20) NOT NULL DEFAULT '' PRIMARY KEY,
  scale_name VARCHAR(60) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE grade_band (
  band_id   VARCHAR(20)  NOT NULL DEFAULT '' PRIMARY KEY,
  scale_id  VARCHAR(20)  NOT NULL,
  min_score DECIMAL(5,2) NOT NULL,
  max_score DECIMAL(5,2) NOT NULL,
  grade     VARCHAR(3)   NOT NULL,
  remark    VARCHAR(30)  NOT NULL,
  UNIQUE KEY uq_band (scale_id, min_score),
  CONSTRAINT fk_band_scale FOREIGN KEY (scale_id) REFERENCES grading_scale (scale_id)
) ENGINE=InnoDB;

CREATE TABLE class_level(
  class_id            VARCHAR(20) NOT NULL DEFAULT '' PRIMARY KEY,
  class_name          VARCHAR(30) NOT NULL UNIQUE,
  level_group         ENUM('preschool','elementary','secondary') NOT NULL,
  sort_order          TINYINT UNSIGNED NOT NULL,
  scale_id            VARCHAR(20) NOT NULL,
  ca_max              DECIMAL(5,2) NOT NULL,
  exam_max            DECIMAL(5,2) NOT NULL,
  has_mid_term        TINYINT(1)   NOT NULL DEFAULT 0,
  mid_term_max        DECIMAL(5,2) NULL,
  has_habits          TINYINT(1)   NOT NULL DEFAULT 0,
  has_checklist       TINYINT(1)   NOT NULL DEFAULT 0,   
  show_class_averages TINYINT(1)   NOT NULL DEFAULT 1,
  show_promotion      TINYINT(1)   NOT NULL DEFAULT 0,   
  next_class_id       VARCHAR(20)  NULL,
  CONSTRAINT fk_class_scale FOREIGN KEY (scale_id)      REFERENCES grading_scale (scale_id),
  CONSTRAINT fk_class_next  FOREIGN KEY (next_class_id) REFERENCES class_level (class_id),
  CONSTRAINT chk_class_total CHECK (ca_max + exam_max = 100)
) ENGINE=InnoDB;

CREATE TABLE class_section(
  section_id       VARCHAR(20) NOT NULL DEFAULT '' PRIMARY KEY,
  session_id       VARCHAR(20) NOT NULL,
  class_id         VARCHAR(20) NOT NULL,
  section_name     VARCHAR(40) NOT NULL,
  class_teacher_id VARCHAR(20) NULL,
  UNIQUE KEY uq_section (session_id, class_id, section_name),
  CONSTRAINT fk_section_session FOREIGN KEY (session_id)       REFERENCES academic_session (session_id),
  CONSTRAINT fk_section_class   FOREIGN KEY (class_id)         REFERENCES class_level (class_id),
  CONSTRAINT fk_section_teacher FOREIGN KEY (class_teacher_id) REFERENCES teacher (teacher_id)
) ENGINE=InnoDB;

CREATE TABLE teacher_section (
  assignment_id VARCHAR(20) NOT NULL DEFAULT '' PRIMARY KEY,
  teacher_id    VARCHAR(20) NOT NULL,
  section_id    VARCHAR(20) NOT NULL,
  UNIQUE KEY uq_teacher_section (teacher_id, section_id),
  CONSTRAINT fk_ts_teacher FOREIGN KEY (teacher_id) REFERENCES teacher (teacher_id),
  CONSTRAINT fk_ts_section FOREIGN KEY (section_id) REFERENCES class_section (section_id)
) ENGINE=InnoDB;

CREATE TABLE student_enrolment (
  enrolment_id VARCHAR(20) NOT NULL DEFAULT '' PRIMARY KEY,
  student_id   VARCHAR(20) NOT NULL,
  session_id   VARCHAR(20) NOT NULL DEFAULT '',
  section_id   VARCHAR(20) NOT NULL,
  enrolled_on  DATE NULL,
  status       ENUM('active','withdrawn','graduated') NOT NULL DEFAULT 'active',
  UNIQUE KEY uq_enrol (student_id, session_id),
  KEY idx_enrol_section (section_id),
  CONSTRAINT fk_enrol_student FOREIGN KEY (student_id) REFERENCES student (student_id),
  CONSTRAINT fk_enrol_session FOREIGN KEY (session_id) REFERENCES academic_session (session_id),
  CONSTRAINT fk_enrol_section FOREIGN KEY (section_id) REFERENCES class_section (section_id)
) ENGINE=InnoDB;

-- Subjects Details below

CREATE TABLE subject(
  subject_id   VARCHAR(20) NOT NULL DEFAULT '' PRIMARY KEY,
  subject_name VARCHAR(80) NOT NULL UNIQUE,
  short_name   VARCHAR(30) NULL
) ENGINE=InnoDB;

CREATE TABLE class_subject (
  class_subject_id VARCHAR(20) NOT NULL DEFAULT '' PRIMARY KEY,
  session_id       VARCHAR(20) NOT NULL,
  class_id         VARCHAR(20) NOT NULL,
  subject_id       VARCHAR(20) NOT NULL,
  display_order    TINYINT UNSIGNED NOT NULL DEFAULT 1,
  counts_in_total  TINYINT(1)   NOT NULL DEFAULT 1,   
  is_optional      TINYINT(1)   NOT NULL DEFAULT 0,   
  ca_max           DECIMAL(5,2) NULL,                 
  exam_max         DECIMAL(5,2) NULL,                
  in_mid_term      TINYINT(1)   NOT NULL DEFAULT 0,
  mid_term_label   VARCHAR(100) NULL,                
  offered_term1    TINYINT(1)   NOT NULL DEFAULT 1,
  offered_term2    TINYINT(1)   NOT NULL DEFAULT 1,
  offered_term3    TINYINT(1)   NOT NULL DEFAULT 1, 
  UNIQUE KEY uq_class_subject (session_id, class_id, subject_id),
  CONSTRAINT fk_cs_session FOREIGN KEY (session_id) REFERENCES academic_session (session_id),
  CONSTRAINT fk_cs_class   FOREIGN KEY (class_id)   REFERENCES class_level (class_id),
  CONSTRAINT fk_cs_subject FOREIGN KEY (subject_id) REFERENCES subject (subject_id)
) ENGINE=InnoDB;

CREATE TABLE student_subject_optout(
  optout_id        VARCHAR(20) NOT NULL DEFAULT '' PRIMARY KEY,
  enrolment_id     VARCHAR(20) NOT NULL,
  class_subject_id VARCHAR(20) NOT NULL,
  UNIQUE KEY uq_optout (enrolment_id, class_subject_id),
  CONSTRAINT fk_optout_enrol FOREIGN KEY (enrolment_id)     REFERENCES student_enrolment (enrolment_id),
  CONSTRAINT fk_optout_cs    FOREIGN KEY (class_subject_id) REFERENCES class_subject (class_subject_id)
) ENGINE=InnoDB;

-- Habits and Attitude below

CREATE TABLE habit_trait (
  habit_id   VARCHAR(20)  NOT NULL DEFAULT '' PRIMARY KEY,
  trait_name VARCHAR(100) NOT NULL UNIQUE,
  sort_order TINYINT UNSIGNED NOT NULL DEFAULT 1,
  is_active  TINYINT(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB;

CREATE TABLE rating_scale (
  rating_value TINYINT UNSIGNED NOT NULL PRIMARY KEY,   
  rating_grade CHAR(1)     NOT NULL,
  rating_label VARCHAR(20) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE checklist_section (
  checklist_section_id VARCHAR(20) NOT NULL DEFAULT '' PRIMARY KEY,
  section_title        VARCHAR(80) NOT NULL UNIQUE,
  sort_order           TINYINT UNSIGNED NOT NULL DEFAULT 1
) ENGINE=InnoDB;


CREATE TABLE checklist_item (
  checklist_item_id    VARCHAR(20) NOT NULL DEFAULT '' PRIMARY KEY,
  class_id             VARCHAR(20) NOT NULL,
  term_id              VARCHAR(20) NOT NULL,
  checklist_section_id VARCHAR(20) NOT NULL,
  item_text            VARCHAR(255) NOT NULL,
  sort_order           SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  is_active            TINYINT(1) NOT NULL DEFAULT 1,
  KEY idx_item_class_term (class_id, term_id),
  CONSTRAINT fk_item_class   FOREIGN KEY (class_id)             REFERENCES class_level (class_id),
  CONSTRAINT fk_item_term    FOREIGN KEY (term_id)              REFERENCES term (term_id),
  CONSTRAINT fk_item_section FOREIGN KEY (checklist_section_id) REFERENCES checklist_section (checklist_section_id)
) ENGINE=InnoDB;

-- Report Card Details below

CREATE TABLE report_card (
  report_id            VARCHAR(20) NOT NULL DEFAULT '' PRIMARY KEY, 
  enrolment_id         VARCHAR(20) NOT NULL,
  term_id              VARCHAR(20) NOT NULL,
  date_of_issue        DATE NULL,
  times_school_opened  SMALLINT UNSIGNED NULL,
  times_present        SMALLINT UNSIGNED NULL,
  next_term_begins     DATE NULL,
  general_comment      TEXT NULL,
  promoted_to_class_id   VARCHAR(20) NULL,       
  promoted_to_section_id VARCHAR(20) NULL,
  class_teacher_id     VARCHAR(20) NULL,         
  total_score          DECIMAL(7,2) NULL,       
  average_score        DECIMAL(5,1) NULL, 
  status               ENUM('draft','submitted') NOT NULL DEFAULT 'draft',
  created_by           VARCHAR(20) NULL,
  created_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  submitted_by         VARCHAR(20) NULL,
  submitted_at         DATETIME NULL,
  UNIQUE KEY uq_report (enrolment_id, term_id),
  KEY idx_report_term_status (term_id, status),
  CONSTRAINT fk_rep_enrol   FOREIGN KEY (enrolment_id)           REFERENCES student_enrolment (enrolment_id),
  CONSTRAINT fk_rep_term    FOREIGN KEY (term_id)                REFERENCES term (term_id),
  CONSTRAINT fk_rep_pclass  FOREIGN KEY (promoted_to_class_id)   REFERENCES class_level (class_id),
  CONSTRAINT fk_rep_psect   FOREIGN KEY (promoted_to_section_id) REFERENCES class_section (section_id),
  CONSTRAINT fk_rep_teacher FOREIGN KEY (class_teacher_id)       REFERENCES teacher (teacher_id),
  CONSTRAINT fk_rep_created FOREIGN KEY (created_by)             REFERENCES user_account (user_id),
  CONSTRAINT fk_rep_submit  FOREIGN KEY (submitted_by)           REFERENCES user_account (user_id)
) ENGINE=InnoDB;

CREATE TABLE report_score(
  score_id         VARCHAR(20) NOT NULL DEFAULT '' PRIMARY KEY,
  report_id        VARCHAR(20) NOT NULL,
  class_subject_id VARCHAR(20) NOT NULL,
  ca_score         DECIMAL(5,2) NULL,
  exam_score       DECIMAL(5,2) NULL,
  total_score      DECIMAL(5,2) NULL,      
  grade            VARCHAR(3)   NULL,      
  remark           VARCHAR(30)  NULL, 
  UNIQUE KEY uq_report_subject (report_id, class_subject_id),
  CONSTRAINT fk_score_report FOREIGN KEY (report_id)        REFERENCES report_card (report_id) ON DELETE CASCADE,
  CONSTRAINT fk_score_cs     FOREIGN KEY (class_subject_id) REFERENCES class_subject (class_subject_id)
) ENGINE=InnoDB;

CREATE TABLE report_habit (
  report_habit_id VARCHAR(20) NOT NULL DEFAULT '' PRIMARY KEY,
  report_id       VARCHAR(20) NOT NULL,
  habit_id        VARCHAR(20) NOT NULL,
  rating_value    TINYINT UNSIGNED NOT NULL,
  UNIQUE KEY uq_report_habit (report_id, habit_id),
  CONSTRAINT fk_rh_report FOREIGN KEY (report_id)    REFERENCES report_card (report_id) ON DELETE CASCADE,
  CONSTRAINT fk_rh_habit  FOREIGN KEY (habit_id)     REFERENCES habit_trait (habit_id),
  CONSTRAINT fk_rh_rating FOREIGN KEY (rating_value) REFERENCES rating_scale (rating_value)
) ENGINE=InnoDB;

CREATE TABLE report_checklist (
  report_checklist_id VARCHAR(20) NOT NULL DEFAULT '' PRIMARY KEY,
  report_id           VARCHAR(20) NOT NULL,
  checklist_item_id   VARCHAR(20) NOT NULL,
  rating              ENUM('Emerging','Developing','Mastered') NOT NULL,
  UNIQUE KEY uq_report_item (report_id, checklist_item_id),
  CONSTRAINT fk_rc_report FOREIGN KEY (report_id)         REFERENCES report_card (report_id) ON DELETE CASCADE,
  CONSTRAINT fk_rc_item   FOREIGN KEY (checklist_item_id) REFERENCES checklist_item (checklist_item_id)
) ENGINE=InnoDB;

-- Mid Term Report details below

CREATE TABLE mid_term_report (
  mid_term_id      VARCHAR(20) NOT NULL DEFAULT '' PRIMARY KEY,
  enrolment_id     VARCHAR(20) NOT NULL,
  term_id          VARCHAR(20) NOT NULL,
  test_date        DATE NULL,
  class_teacher_id VARCHAR(20) NULL,
  total_score      DECIMAL(6,2) NULL,
  status           ENUM('draft','submitted') NOT NULL DEFAULT 'draft',
  created_by       VARCHAR(20) NULL,
  created_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  submitted_by     VARCHAR(20) NULL,
  submitted_at     DATETIME NULL,
  UNIQUE KEY uq_mid_term (enrolment_id, term_id),
  CONSTRAINT fk_mt_enrol   FOREIGN KEY (enrolment_id)     REFERENCES student_enrolment (enrolment_id),
  CONSTRAINT fk_mt_term    FOREIGN KEY (term_id)          REFERENCES term (term_id),
  CONSTRAINT fk_mt_teacher FOREIGN KEY (class_teacher_id) REFERENCES teacher (teacher_id),
  CONSTRAINT fk_mt_created FOREIGN KEY (created_by)       REFERENCES user_account (user_id),
  CONSTRAINT fk_mt_submit  FOREIGN KEY (submitted_by)     REFERENCES user_account (user_id)
) ENGINE=InnoDB;

CREATE TABLE mid_term_score (
  mid_term_score_id VARCHAR(20) NOT NULL DEFAULT '' PRIMARY KEY,
  mid_term_id       VARCHAR(20) NOT NULL,
  class_subject_id  VARCHAR(20) NOT NULL,
  score             DECIMAL(5,2) NULL,
  UNIQUE KEY uq_mt_subject (mid_term_id, class_subject_id),
  CONSTRAINT fk_mts_mt FOREIGN KEY (mid_term_id)      REFERENCES mid_term_report (mid_term_id) ON DELETE CASCADE,
  CONSTRAINT fk_mts_cs FOREIGN KEY (class_subject_id) REFERENCES class_subject (class_subject_id)
) ENGINE=InnoDB;


-- Access Control below

CREATE TABLE student_pin(
  pin_id          VARCHAR(20) NOT NULL DEFAULT '' PRIMARY KEY,
  student_id      VARCHAR(20) NOT NULL,
  session_id      VARCHAR(20) NOT NULL,
  term_id         VARCHAR(20) NOT NULL,
  pin_salt        CHAR(16) NOT NULL,
  pin_hash        CHAR(64) NOT NULL,  
  failed_attempts TINYINT UNSIGNED NOT NULL DEFAULT 0,
  is_locked       TINYINT(1) NOT NULL DEFAULT 0,
  issued_by       VARCHAR(20) NULL,
  issued_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_pin (student_id, session_id, term_id),
  CONSTRAINT fk_pin_student FOREIGN KEY (student_id) REFERENCES student (student_id),
  CONSTRAINT fk_pin_session FOREIGN KEY (session_id) REFERENCES academic_session (session_id),
  CONSTRAINT fk_pin_term    FOREIGN KEY (term_id)    REFERENCES term (term_id)
) ENGINE=InnoDB;


CREATE TABLE import_student_staging(
  row_id            VARCHAR(20) NOT NULL DEFAULT '' PRIMARY KEY,
  admission_no      VARCHAR(30)  NULL,
  surname           VARCHAR(60)  NULL,
  first_name        VARCHAR(60)  NULL,
  other_names       VARCHAR(80)  NULL,
  date_of_birth     VARCHAR(20)  NULL,    
  gender            VARCHAR(10)  NULL, 
  class_name        VARCHAR(30)  NULL,
  section_name      VARCHAR(40)  NULL,
  parent_surname    VARCHAR(60)  NULL,
  parent_first_name VARCHAR(60)  NULL,
  parent_phone      VARCHAR(30)  NULL,
  parent_email      VARCHAR(120) NULL,
  relationship      VARCHAR(20)  NULL,
  import_status     ENUM('pending','imported','error') NOT NULL DEFAULT 'pending',
  error_message     VARCHAR(255) NULL,
  student_id        VARCHAR(20)  NULL
) ENGINE=InnoDB;

CREATE TABLE audit_log (
  log_id      VARCHAR(20) NOT NULL DEFAULT '' PRIMARY KEY,
  user_id     VARCHAR(20) NULL,
  action_name VARCHAR(40) NOT NULL,
  table_name  VARCHAR(40) NOT NULL,
  record_id   VARCHAR(20) NOT NULL,
  detail      JSON NULL,
  created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;