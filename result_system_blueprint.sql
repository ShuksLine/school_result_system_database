
## Goal of the result_system
1. To manage students, teachers, and parents
2. To manage subjects, classes and exam
3. Automatically generate results and report cards per term

## Main Module
1. Student Management
2. Class and Subjcet Mananagement
3. Grade and Position calculation
4. Report card
5. Login and roles

## Tables and Attributes (MVP)
1. Table users {
    user_id         varchar [pk]
    role_id         varchar
    username        varchar
    email           varchar
    password_on     varchar
} 

2. Table students {
    student_id      varchar [pk]
    user_id         varchar [ref: > users.user_id]
    admission_no    varchar
    first_name      varchar
    last_name       varchar
    date_of_birth   date
    gender          varchar check [gender IN ['MALE','FEMALE','OTHER']]
    admission_date  date
}

3. Table teachers{
    teacher_id      varchar [pk]
    user_id         varchar [ref: > users.user_id]
    employment_no   varchar
    employment_type varchar
    first_name      varchar
    last_name       varchar
    class	        varchar
    employment_date date
}

4. Table parents{
    parent_id       varchar [pk]
    user_id         varchar [ref: > users.user_id]
    first_name      varchar
    last_name       varchar
    phone_number    varchar
    email	        varchar
	relationship    varchar
        check [relationship IN ['FATHER','MOTHER','GUARDIAN','OTHER']]
}

5. Table classes { 
    class_id        varchar [pk]
    class_name      varchar
}

6. Table subjects{
    subject_id      varchar [pk]
    subject_name    varchar
}

7. Table terms {
    term_id          varchar [pk]
    academic_year_id varchar [pk]
    term_name        varchar
    start_date       date
    end_date         date
}

8. Table exam{
    exam_id          varchar [pk]
    exam_name        varchar
    exam_type_id     varchar
    term_id          varchar [ref: > terms.term_id]
    subject_id       varchar [ref: > subjects.subject_id]
    section_id       varchar
    exam_date        date
    highest_mark    decimal (6,2) check [highest_marks > 0]
}

9. Table results{
    result_id         varchar [pk]
    exam_id           varchar [ref: > exam.exam_id]
    student_id        varchar [ref: > students.student_id]
    marks_obtained    decimal(6,2) check [marks_obtained >= 0]
    grade             varchar
    remarks           varchar
}

10. Table report_card{
    report_card_id     varchar [pk]
    student_id         varchar [ref: > students.student_id]
    term_id           varchar [ref: > terms.term_id]
    overall_percentage decimal(5,2),
    overall_score      varchar
    subject_grade      int
    generated_at       timestamp CURRENT_TIMESTAMP
    generated_by       varchar [ref: > teachers.teacher_id]        
    is_published       boolean FALSE
}

## How they Connects
One class has many students
One student has many results
One student has many subject
One subject has many student
One result has many subject
One term has many results
One student has one report card

