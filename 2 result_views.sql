USE school_result_system;

CREATE VIEW v_enrolment_detail AS
SELECT e.enrolment_id, e.student_id, st.admission_no,
       UPPER(CONCAT_WS(' ', st.surname, st.first_name, st.other_names)) AS full_name,
       st.date_of_birth, st.gender,
       cl.class_id, cl.class_name, sct.section_id, sct.section_name,
       CONCAT(cl.class_name, ' ', sct.section_name) AS class_section_name,
       ses.session_id, ses.session_name, e.status AS enrolment_status,
       sct.class_teacher_id
FROM student_enrolment e
JOIN student st          ON st.student_id  = e.student_id
JOIN class_section sct   ON sct.section_id = e.section_id
JOIN class_level cl      ON cl.class_id    = sct.class_id
JOIN academic_session ses ON ses.session_id = e.session_id;


CREATE VIEW v_student_profile AS
SELECT st.student_id, st.admission_no,
       UPPER(CONCAT_WS(' ', st.surname, st.first_name, st.other_names)) AS full_name,
       st.date_of_birth, st.gender, st.admission_date, st.status,
       d.class_section_name, d.session_name,
       (SELECT GROUP_CONCAT(CONCAT_WS(' ', pg.surname, pg.first_name, CONCAT('(', l.relationship, ')')) SEPARATOR '; ')
          FROM student_parent_link l JOIN parent_guardian pg ON pg.parent_id = l.parent_id
         WHERE l.student_id = st.student_id) AS parents
FROM student st
LEFT JOIN v_enrolment_detail d
       ON d.student_id = st.student_id
      AND d.session_id = (SELECT session_id FROM academic_session WHERE is_current = 1 LIMIT 1);

CREATE VIEW v_report_expected_subject AS
SELECT r.report_id, cs.class_subject_id, cs.display_order,
       sb.subject_name, sb.short_name, cs.counts_in_total, cs.is_optional,
       COALESCE(cs.ca_max, cl.ca_max)     AS ca_max_eff,
       COALESCE(cs.exam_max, cl.exam_max) AS exam_max_eff
FROM report_card r
JOIN student_enrolment e ON e.enrolment_id = r.enrolment_id
JOIN class_section sct   ON sct.section_id = e.section_id
JOIN class_level cl      ON cl.class_id    = sct.class_id
JOIN term t              ON t.term_id      = r.term_id
JOIN class_subject cs    ON cs.class_id = cl.class_id AND cs.session_id = sct.session_id
JOIN subject sb          ON sb.subject_id  = cs.subject_id
WHERE (CASE t.term_no WHEN 1 THEN cs.offered_term1 WHEN 2 THEN cs.offered_term2 ELSE cs.offered_term3 END) = 1
  AND NOT EXISTS (SELECT 1 FROM student_subject_optout o
                   WHERE o.enrolment_id = e.enrolment_id AND o.class_subject_id = cs.class_subject_id);

CREATE VIEW v_report_scores AS
SELECT x.report_id, x.class_subject_id, x.display_order, x.subject_name, x.short_name,
       x.counts_in_total, x.is_optional, x.ca_max_eff, x.exam_max_eff,
       s.ca_score, s.exam_score, s.total_score, s.grade, s.remark
FROM v_report_expected_subject x
LEFT JOIN report_score s ON s.report_id = x.report_id AND s.class_subject_id = x.class_subject_id;

CREATE VIEW v_report_habits AS
SELECT r.report_id, h.habit_id, h.trait_name, h.sort_order,
       rh.rating_value, rs.rating_grade, rs.rating_label
FROM report_card r
JOIN student_enrolment e ON e.enrolment_id = r.enrolment_id
JOIN class_section sct   ON sct.section_id = e.section_id
JOIN class_level cl      ON cl.class_id = sct.class_id AND cl.has_habits = 1
JOIN habit_trait h       ON h.is_active = 1
LEFT JOIN report_habit rh ON rh.report_id = r.report_id AND rh.habit_id = h.habit_id
LEFT JOIN rating_scale rs ON rs.rating_value = rh.rating_value;

CREATE VIEW v_report_checklist AS
SELECT r.report_id, ci.checklist_item_id, ck.section_title,
       ck.sort_order AS section_order, ci.sort_order AS item_order,
       ci.item_text, rc.rating
FROM report_card r
JOIN student_enrolment e ON e.enrolment_id = r.enrolment_id
JOIN class_section sct   ON sct.section_id = e.section_id
JOIN checklist_item ci   ON ci.class_id = sct.class_id AND ci.term_id = r.term_id AND ci.is_active = 1
JOIN checklist_section ck ON ck.checklist_section_id = ci.checklist_section_id
LEFT JOIN report_checklist rc ON rc.report_id = r.report_id AND rc.checklist_item_id = ci.checklist_item_id;

CREATE VIEW v_report_header AS
SELECT r.report_id, r.status,
       d.enrolment_id, d.student_id, d.admission_no, d.full_name, d.date_of_birth, d.gender,
       d.class_name, d.section_name, d.class_section_name, d.session_name,
       t.term_id, t.term_name, t.term_no,
       CASE WHEN cl.level_group = 'preschool'
            THEN CONCAT('PRESCHOOL SUMMATIVE REPORT, TERM ', UPPER(t.term_word), ' ', d.session_name, ' ACADEMIC SESSION.')
            ELSE CONCAT(UPPER(t.term_name), ' SUMMATIVE REPORT. TERM ', UPPER(t.term_word), ' ', d.session_name, ' SESSION.')
       END AS report_title,
       r.date_of_issue, r.times_school_opened, r.times_present, r.next_term_begins,
       r.general_comment, r.total_score, r.average_score,
       (SELECT MAX(r2.average_score) FROM report_card r2
          JOIN student_enrolment e2 ON e2.enrolment_id = r2.enrolment_id
          JOIN class_section s2 ON s2.section_id = e2.section_id
         WHERE r2.status = 'submitted' AND r2.term_id = r.term_id
           AND s2.session_id = d.session_id AND s2.class_id = d.class_id)   AS highest_average_class,
       (SELECT MIN(r2.average_score) FROM report_card r2
          JOIN student_enrolment e2 ON e2.enrolment_id = r2.enrolment_id
          JOIN class_section s2 ON s2.section_id = e2.section_id
         WHERE r2.status = 'submitted' AND r2.term_id = r.term_id
           AND s2.session_id = d.session_id AND s2.class_id = d.class_id)   AS lowest_average_class,
       (SELECT MAX(r2.average_score) FROM report_card r2
          JOIN student_enrolment e2 ON e2.enrolment_id = r2.enrolment_id
         WHERE r2.status = 'submitted' AND r2.term_id = r.term_id
           AND e2.section_id = d.section_id)                                AS highest_average_section,
       (SELECT MIN(r2.average_score) FROM report_card r2
          JOIN student_enrolment e2 ON e2.enrolment_id = r2.enrolment_id
         WHERE r2.status = 'submitted' AND r2.term_id = r.term_id
           AND e2.section_id = d.section_id)                                AS lowest_average_section,
       cl.show_class_averages, cl.has_habits, cl.has_checklist, cl.level_group,
       CASE WHEN t.term_no = 3 AND cl.show_promotion = 1 THEN
              CASE WHEN r.promoted_to_class_id IS NOT NULL
                   THEN UPPER(CONCAT('PROMOTED TO ', pc.class_name, IFNULL(CONCAT(' ', ps.section_name), '')))
                   WHEN cl.next_class_id IS NULL THEN 'PROMOTED TO THE NEXT CLASS'
              END
       END AS promotion_text,
       sp.school_name, sp.rc_number, sp.tagline, sp.logo_path,
       sp.head_of_school_name, sp.head_signature_path,
       CONCAT_WS(' ', tc.surname, tc.first_name) AS class_teacher_name,
       tc.signature_path AS class_teacher_signature
FROM report_card r
JOIN v_enrolment_detail d ON d.enrolment_id = r.enrolment_id
JOIN class_level cl       ON cl.class_id = d.class_id
JOIN term t               ON t.term_id = r.term_id
LEFT JOIN class_level pc   ON pc.class_id = r.promoted_to_class_id
LEFT JOIN class_section ps ON ps.section_id = r.promoted_to_section_id
LEFT JOIN teacher tc       ON tc.teacher_id = r.class_teacher_id
CROSS JOIN school_profile sp;

CREATE VIEW v_report_progress AS
SELECT r.report_id, d.admission_no, d.full_name, d.class_section_name, d.session_name,
       t.term_name, r.status,
       IF(r.date_of_issue IS NOT NULL AND r.times_school_opened IS NOT NULL
          AND r.times_present IS NOT NULL AND r.next_term_begins IS NOT NULL, 1, 0) AS attendance_done,
       (SELECT COUNT(*) FROM v_report_expected_subject x WHERE x.report_id = r.report_id) AS subjects_expected,
       (SELECT COUNT(*) FROM report_score s WHERE s.report_id = r.report_id AND s.total_score IS NOT NULL) AS subjects_scored,
       IF(cl.has_habits = 1, (SELECT COUNT(*) FROM habit_trait WHERE is_active = 1), 0) AS habits_expected,
       (SELECT COUNT(*) FROM report_habit rh WHERE rh.report_id = r.report_id) AS habits_done,
       (SELECT COUNT(*) FROM v_report_checklist c WHERE c.report_id = r.report_id) AS checklist_expected,
       (SELECT COUNT(*) FROM v_report_checklist c WHERE c.report_id = r.report_id AND c.rating IS NOT NULL) AS checklist_done,
       IF(r.general_comment IS NOT NULL AND r.general_comment <> '', 1, 0) AS comment_done
FROM report_card r
JOIN v_enrolment_detail d ON d.enrolment_id = r.enrolment_id
JOIN class_level cl       ON cl.class_id = d.class_id
JOIN term t               ON t.term_id = r.term_id;

CREATE VIEW v_mid_term_expected_subject AS
SELECT m.mid_term_id, cs.class_subject_id, cs.display_order,
       COALESCE(cs.mid_term_label, sb.subject_name) AS subject_label
FROM mid_term_report m
JOIN student_enrolment e ON e.enrolment_id = m.enrolment_id
JOIN class_section sct   ON sct.section_id = e.section_id
JOIN term t              ON t.term_id = m.term_id
JOIN class_subject cs    ON cs.class_id = sct.class_id AND cs.session_id = sct.session_id AND cs.in_mid_term = 1
JOIN subject sb          ON sb.subject_id = cs.subject_id
WHERE (CASE t.term_no WHEN 1 THEN cs.offered_term1 WHEN 2 THEN cs.offered_term2 ELSE cs.offered_term3 END) = 1
  AND NOT EXISTS (SELECT 1 FROM student_subject_optout o
                   WHERE o.enrolment_id = e.enrolment_id AND o.class_subject_id = cs.class_subject_id);

CREATE VIEW v_mid_term_scores AS
SELECT x.mid_term_id, x.class_subject_id, x.display_order, x.subject_label, s.score
FROM v_mid_term_expected_subject x
LEFT JOIN mid_term_score s ON s.mid_term_id = x.mid_term_id AND s.class_subject_id = x.class_subject_id;

CREATE VIEW v_mid_term_header AS
SELECT m.mid_term_id, m.status, d.student_id, d.admission_no, d.full_name, d.class_section_name,
       d.session_name, t.term_name,
       CONCAT('MID TERM EXAMINATION RESULT, ', UPPER(t.term_ordinal), ' TERM ', d.session_name, ' SESSION.') AS report_title,
       m.test_date, m.total_score,
       sp.school_name, sp.logo_path, sp.rc_number, sp.head_signature_path,
       tc.signature_path AS class_teacher_signature
FROM mid_term_report m
JOIN v_enrolment_detail d ON d.enrolment_id = m.enrolment_id
JOIN term t               ON t.term_id = m.term_id
LEFT JOIN teacher tc      ON tc.teacher_id = m.class_teacher_id
CROSS JOIN school_profile sp;
