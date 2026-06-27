CREATE DATABASE student;
USE student;
-- create student_performance table
CREATE TABLE student_performance (
    student_id VARCHAR(50),
    school_id VARCHAR(50),
    lga VARCHAR(100),
    gender VARCHAR(50),
    age INT,
    course VARCHAR(100),
    term VARCHAR(50),
    academic_year VARCHAR(50),
    attendance_pct DECIMAL(5,2),
    ca_score DECIMAL(5,2),
    exam_score DECIMAL(5,2),
    total_score DECIMAL(5,2),
    grade VARCHAR(50),
    passed VARCHAR(50),
    study_hours_per_week DECIMAL(5,2),
    parent_education VARCHAR(100),
    school_type VARCHAR(50),
    internet_access VARCHAR(50)
    );
    -- load the csv file into the table
    LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/student_performance.csv' 
    INTO TABLE student_performance
    FIELDS TERMINATED BY ','
    IGNORE 1 LINES;
    
    -- 139. Pass rate by subject — ordered from lowest to highest
    SELECT course,
   -- Calculate pass rate for each course
   ROUND( 
   SUM(CASE WHEN passed = "Yes" THEN 1 ELSE 0 END) * 100
    / COUNT(*),2
    ) AS pass_rate
    FROM student_performance
    GROUP BY course
-- Order results from lowest to highest pass rate
    ORDER BY(pass_rate) ASC;
    
    -- 140. Average score by school_type and gender (cross-tab using GROUP BY)
-- Compare average student performance
    SELECT school_type,
    gender,
    ROUND(AVG(total_score),2) AS avg_score
    FROM student_performance
-- Group by school type and gender
    GROUP BY school_type, gender
    ORDER BY school_type, gender;
    
    -- 141. Schools with pass rate below 50% for Maths
    SELECT school_id,
-- Find schools with poor Maths performance
    ROUND(SUM(CASE WHEN passed = "Yes" THEN 1 ELSE 0 END) * 100
    / COUNT(*), 2) AS math_pass_rate
    FROM student_performance
    WHERE course = "math"
    GROUP BY school_id
-- Show schools with pass rate below 50%
    HAVING math_pass_rate < 50;
    
-- 142. Top 10 schools by overall pass rate
-- Rank schools by overall pass rate
SELECT school_id,
ROUND(SUM(CASE WHEN passed = "Yes" THEN 1 ELSE 0 END)*100
/COUNT(*),2) AS pass_rate
FROM student_performance
GROUP BY school_id
-- Return the top 10 performing schools
ORDER BY pass_rate DESC
LIMIT 10;

-- 143. Subjects where female students outperform male students
SELECT course,
-- Compare male and female average scores
ROUND(AVG(CASE WHEN gender = "female" THEN total_score END),2) AS female_avg,
ROUND(AVG(CASE WHEN gender = "male" THEN total_score END),2) AS male_avg
FROM student_performance
GROUP BY course
-- Return subjects where females score higher
HAVING female_avg > male_avg;

-- 144. Attendance impact: avg total score for attendance buckets (0–40, 41–60, 61–80, 81–100)
-- Group students into attendance ranges
-- Measure the effect on average scores
SELECT
	CASE
		WHEN attendance_pct BETWEEN 0 AND 40 THEN '0-40%'
        WHEN attendance_pct BETWEEN 41 AND 60 THEN '41-60%'
        WHEN attendance_pct BETWEEN 61 AND 80 THEN '61-80%'
        ELSE '81-100%'
        END AS attendance_bucket,
        ROUND(AVG(total_score),2) AS avg_score
        FROM student_performance
        GROUP BY attendance_bucket
        ORDER BY attendance_bucket;
        
-- 145. Students who passed all subjects in a given academic year
-- Identify students who passed every subject
-- Filter results for a 2022/2023 academic year
SELECT student_id
FROM student_performance
WHERE academic_year = '2022/2023'
GROUP BY student_id
HAVING SUM(CASE WHEN passed = 'No' THEN 1 ELSE 0 END) = 0;

-- 146. LGA performance ranking using RANK()
SELECT lga,
-- Calculate average score by LGA
ROUND(AVG(total_score),2) AS avg_score,
-- Calculate average score by LGA
RANK() OVER(ORDER BY AVG(total_score) DESC) AS lga_rank
FROM student_performance
GROUP BY lga;

-- 147. Improvement trend: avg score per subject comparing first and last academic year
SELECT
    course,
-- Compare subject performance across years
    ROUND(AVG(CASE WHEN academic_year = '2022/2023' THEN total_score END), 2) AS first_year_avg,
    ROUND(AVG(CASE WHEN academic_year = '2023/2024' THEN total_score END), 2) AS last_year_avg,
-- Measure improvement between first and last year    
    ROUND(
        AVG(CASE WHEN academic_year = '2023/2024' THEN total_score END) -
        AVG(CASE WHEN academic_year = '2022/2023' THEN total_score END), 2) AS improvement
FROM student_performance
GROUP BY course;

-- 148. CTE: Identify bottom 10% of students by average score
-- Calculate average score per student
WITH student_avg AS (
    SELECT
        student_id,
	AVG(total_score) AS avg_score
    FROM student_performance
    GROUP BY student_id),
ranked_students AS (
    SELECT *,
	NTILE(10) OVER (ORDER BY avg_score) AS percentile_group
    FROM student_avg
)
-- Identify students in the lowest 10%
SELECT student_id,
ROUND(avg_score,2) AS avg_score
FROM ranked_students
WHERE percentile_group = 1;