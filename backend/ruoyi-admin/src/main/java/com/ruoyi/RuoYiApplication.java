package com.ruoyi;

import com.ruoyi.common.enums.DataSourceType;
import com.ruoyi.framework.datasource.DynamicDataSourceContextHolder;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.jdbc.core.JdbcTemplate;

/**
 * 启动程序
 * 
 * @author ruoyi
 */
@SpringBootApplication(exclude = { DataSourceAutoConfiguration.class })
public class RuoYiApplication
{
    private static final Logger log = LoggerFactory.getLogger(RuoYiApplication.class);
    private static final int DEFAULT_LEVEL_PASS_SCORE = 60;
    private static final int DEFAULT_LEVEL_EXCELLENT_SCORE = 85;
    private static final int DEFAULT_MAX_ATTEMPTS = 1;

    public static void main(String[] args)
    {
        // System.setProperty("spring.devtools.restart.enabled", "false");
        SpringApplication.run(RuoYiApplication.class, args);
        log.info("若依启动成功");
    }

    @Bean
    public CommandLineRunner trainingSchemaInitializer(JdbcTemplate jdbcTemplate)
    {
        return args -> {
            initializeTrainingSchema(jdbcTemplate, DataSourceType.MASTER);
            initializeTrainingSchema(jdbcTemplate, DataSourceType.SLAVE);
        };
    }

    private void initializeTrainingSchema(JdbcTemplate jdbcTemplate, DataSourceType dataSourceType)
    {
        DynamicDataSourceContextHolder.setDataSourceType(dataSourceType.name());
        try
        {
            ensureTrainAnswerAttemptTable(jdbcTemplate);
            ensureTrainQuizAttemptTable(jdbcTemplate);
            ensureTrainExamResultDisplayModeColumn(jdbcTemplate);
            ensureTrainExamLevelThresholdColumns(jdbcTemplate);
            ensureTrainExamMaxAttemptsColumn(jdbcTemplate);
            backfillTrainQuizAttemptResultDisplayMode(jdbcTemplate);
            backfillTrainQuizAttemptLevelThresholds(jdbcTemplate);
            ensureCourseCategoryPlatformColumn(jdbcTemplate);
            ensureCourseCategoryVideoUrlColumn(jdbcTemplate);
            ensureGreenHotelCourseVideoUrlColumn(jdbcTemplate);
        }
        catch (Exception e)
        {
            log.error("初始化 {} 数据源培训相关表结构失败，将跳过继续启动", dataSourceType.name(), e);
        }
        finally
        {
            DynamicDataSourceContextHolder.clearDataSourceType();
        }
    }

    private void ensureGreenHotelCourseVideoUrlColumn(JdbcTemplate jdbcTemplate)
    {
        if (!tableExists(jdbcTemplate, "green_hotel_course"))
        {
            return;
        }

        try
        {
            if (columnExists(jdbcTemplate, "green_hotel_course", "video_url"))
            {
                return;
            }

            String alterSql = "ALTER TABLE `green_hotel_course` ADD COLUMN `video_url` varchar(500) DEFAULT NULL COMMENT '课程视频地址' AFTER `cover_image`";
            jdbcTemplate.execute(alterSql);
            log.info("已为 green_hotel_course 添加字段 video_url");
        }
        catch (Exception e)
        {
            log.error("初始化 green_hotel_course.video_url 字段失败，将跳过继续启动", e);
        }
    }

    private void ensureCourseCategoryPlatformColumn(JdbcTemplate jdbcTemplate)
    {
        if (!tableExists(jdbcTemplate, "course_category"))
        {
            return;
        }

        try
        {
            if (columnExists(jdbcTemplate, "course_category", "platform"))
            {
                return;
            }

            String alterSql;
            if (columnExists(jdbcTemplate, "course_category", "level"))
            {
                alterSql = "ALTER TABLE `course_category` ADD COLUMN `platform` varchar(50) DEFAULT NULL COMMENT '平台' AFTER `level`";
            }
            else
            {
                alterSql = "ALTER TABLE `course_category` ADD COLUMN `platform` varchar(50) DEFAULT NULL COMMENT '平台'";
            }

            jdbcTemplate.execute(alterSql);
            log.info("已为 course_category 添加字段 platform");
        }
        catch (Exception e)
        {
            log.error("初始化 course_category.platform 字段失败，将跳过继续启动", e);
        }
    }

    private void ensureTrainAnswerAttemptTable(JdbcTemplate jdbcTemplate)
    {
        if (!tableExists(jdbcTemplate, "train_answer_attempt"))
        {
            jdbcTemplate.execute(
                "CREATE TABLE IF NOT EXISTS `train_answer_attempt` (\n" +
                    "  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',\n" +
                    "  `user_id` bigint(20) NOT NULL COMMENT '用户ID',\n" +
                    "  `question_id` bigint(20) NOT NULL COMMENT '题目ID',\n" +
                    "  `is_correct` tinyint(1) NOT NULL DEFAULT 0 COMMENT '是否正确（0-错误，1-正确）',\n" +
                    "  `attempt_time` datetime NOT NULL COMMENT '作答时间（提交时刻）',\n" +
                    "  `module_id` bigint(20) DEFAULT NULL COMMENT '所属模块/章节ID',\n" +
                    "  `duration` int(11) NOT NULL DEFAULT 0 COMMENT '作答用时（秒）',\n" +
                    "  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',\n" +
                    "  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',\n" +
                    "  `user_answer` varchar(500) DEFAULT NULL COMMENT '用户答案',\n" +
                    "  `question_text` text DEFAULT NULL COMMENT '题目内容',\n" +
                    "  `question_type` varchar(50) DEFAULT NULL COMMENT '题目类型',\n" +
                    "  `option_a` varchar(500) DEFAULT NULL COMMENT '选项A',\n" +
                    "  `option_b` varchar(500) DEFAULT NULL COMMENT '选项B',\n" +
                    "  `option_c` varchar(500) DEFAULT NULL COMMENT '选项C',\n" +
                    "  `option_d` varchar(500) DEFAULT NULL COMMENT '选项D',\n" +
                    "  `correct_answer` varchar(100) DEFAULT NULL COMMENT '正确答案',\n" +
                    "  `explanation` text DEFAULT NULL COMMENT '题目解析',\n" +
                    "  PRIMARY KEY (`id`),\n" +
                    "  KEY `idx_user_id` (`user_id`),\n" +
                    "  KEY `idx_question_id` (`question_id`),\n" +
                    "  KEY `idx_attempt_time` (`attempt_time`),\n" +
                    "  KEY `idx_module_id` (`module_id`)\n" +
                    ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户答题尝试记录表';"
            );
            log.info("已创建表 train_answer_attempt");
            return;
        }

        ensureColumnExists(jdbcTemplate, "train_answer_attempt", "module_id",
            "ALTER TABLE `train_answer_attempt` ADD COLUMN `module_id` bigint(20) DEFAULT NULL COMMENT '所属模块/章节ID'");
        ensureColumnExists(jdbcTemplate, "train_answer_attempt", "duration",
            "ALTER TABLE `train_answer_attempt` ADD COLUMN `duration` int(11) NOT NULL DEFAULT 0 COMMENT '作答用时（秒）'");
        ensureColumnExists(jdbcTemplate, "train_answer_attempt", "user_answer",
            "ALTER TABLE `train_answer_attempt` ADD COLUMN `user_answer` varchar(500) DEFAULT NULL COMMENT '用户答案'");
        ensureColumnExists(jdbcTemplate, "train_answer_attempt", "question_text",
            "ALTER TABLE `train_answer_attempt` ADD COLUMN `question_text` text DEFAULT NULL COMMENT '题目内容'");
        ensureColumnExists(jdbcTemplate, "train_answer_attempt", "question_type",
            "ALTER TABLE `train_answer_attempt` ADD COLUMN `question_type` varchar(50) DEFAULT NULL COMMENT '题目类型'");
        ensureColumnExists(jdbcTemplate, "train_answer_attempt", "option_a",
            "ALTER TABLE `train_answer_attempt` ADD COLUMN `option_a` varchar(500) DEFAULT NULL COMMENT '选项A'");
        ensureColumnExists(jdbcTemplate, "train_answer_attempt", "option_b",
            "ALTER TABLE `train_answer_attempt` ADD COLUMN `option_b` varchar(500) DEFAULT NULL COMMENT '选项B'");
        ensureColumnExists(jdbcTemplate, "train_answer_attempt", "option_c",
            "ALTER TABLE `train_answer_attempt` ADD COLUMN `option_c` varchar(500) DEFAULT NULL COMMENT '选项C'");
        ensureColumnExists(jdbcTemplate, "train_answer_attempt", "option_d",
            "ALTER TABLE `train_answer_attempt` ADD COLUMN `option_d` varchar(500) DEFAULT NULL COMMENT '选项D'");
        ensureColumnExists(jdbcTemplate, "train_answer_attempt", "correct_answer",
            "ALTER TABLE `train_answer_attempt` ADD COLUMN `correct_answer` varchar(100) DEFAULT NULL COMMENT '正确答案'");
        ensureColumnExists(jdbcTemplate, "train_answer_attempt", "explanation",
            "ALTER TABLE `train_answer_attempt` ADD COLUMN `explanation` text DEFAULT NULL COMMENT '题目解析'");
    }

    private void ensureTrainQuizAttemptTable(JdbcTemplate jdbcTemplate)
    {
        if (!tableExists(jdbcTemplate, "train_quiz_attempt"))
        {
            jdbcTemplate.execute(
                "CREATE TABLE IF NOT EXISTS `train_quiz_attempt` (\n" +
                    "  `attempt_id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT '考试尝试ID',\n" +
                    "  `user_id` BIGINT(20) NOT NULL COMMENT '用户ID',\n" +
                    "  `exam_id` BIGINT(20) DEFAULT NULL COMMENT '考试ID（如果是正式考试）',\n" +
                    "  `result_display_mode` varchar(20) NOT NULL DEFAULT 'score' COMMENT '结果展示方式：score=分数，level=等级',\n" +
                    "  `level_pass_score` int(11) NOT NULL DEFAULT 60 COMMENT '等级模式合格分数线',\n" +
                    "  `level_excellent_score` int(11) NOT NULL DEFAULT 85 COMMENT '等级模式优秀分数线',\n" +
                    "  `exam_name` varchar(255) DEFAULT NULL COMMENT '考试名称',\n" +
                    "  `attempt_type` VARCHAR(20) DEFAULT 'practice' COMMENT '答题类型：exam=考试，practice=测验',\n" +
                    "  `attempt_scene` VARCHAR(20) DEFAULT 'practice' COMMENT '答题场景：exam=正式考试，practice=普通测验，course_quiz=结课测验',\n" +
                    "  `course_quiz_key` VARCHAR(128) DEFAULT NULL COMMENT '结课测验去重键',\n" +
                    "  `score` INT DEFAULT 0 COMMENT '考试总分',\n" +
                    "  `submitted_at` DATETIME DEFAULT NULL COMMENT '提交时间',\n" +
                    "  `is_passed` TINYINT(1) DEFAULT 0 COMMENT '是否通过（0未通过 1通过）',\n" +
                    "  `duration` INT DEFAULT 0 COMMENT '考试总用时（秒）',\n" +
                    "  `duration_seconds` INT DEFAULT 0 COMMENT '考试总用时（秒）兼容字段',\n" +
                    "  `question_count` INT DEFAULT 0 COMMENT '题目总数',\n" +
                    "  `correct_count` INT DEFAULT 0 COMMENT '答对题目数',\n" +
                    "  `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',\n" +
                    "  `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',\n" +
                    "  PRIMARY KEY (`attempt_id`),\n" +
                    "  KEY `idx_user_id` (`user_id`),\n" +
                    "  KEY `idx_exam_id` (`exam_id`),\n" +
                    "  KEY `idx_submitted_at` (`submitted_at`)\n" +
                    ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='考试答题记录表';"
            );
            log.info("已创建表 train_quiz_attempt");
        }

        ensureColumnExists(
            jdbcTemplate,
            "train_quiz_attempt",
            "result_display_mode",
            "ALTER TABLE `train_quiz_attempt` ADD COLUMN `result_display_mode` varchar(20) NOT NULL DEFAULT 'score' COMMENT '结果展示方式：score=分数，level=等级' AFTER `exam_id`"
        );
        ensureColumnExists(
            jdbcTemplate,
            "train_quiz_attempt",
            "level_pass_score",
            "ALTER TABLE `train_quiz_attempt` ADD COLUMN `level_pass_score` int(11) NOT NULL DEFAULT 60 COMMENT '等级模式合格分数线' AFTER `result_display_mode`"
        );
        ensureColumnExists(
            jdbcTemplate,
            "train_quiz_attempt",
            "level_excellent_score",
            "ALTER TABLE `train_quiz_attempt` ADD COLUMN `level_excellent_score` int(11) NOT NULL DEFAULT 85 COMMENT '等级模式优秀分数线' AFTER `level_pass_score`"
        );
        ensureColumnExists(
            jdbcTemplate,
            "train_quiz_attempt",
            "exam_name",
            "ALTER TABLE `train_quiz_attempt` ADD COLUMN `exam_name` varchar(255) DEFAULT NULL COMMENT '考试名称' AFTER `level_excellent_score`"
        );
        ensureColumnExists(
            jdbcTemplate,
            "train_quiz_attempt",
            "attempt_scene",
            "ALTER TABLE `train_quiz_attempt` ADD COLUMN `attempt_scene` varchar(20) DEFAULT 'practice' COMMENT '答题场景：exam=正式考试，practice=普通测验，course_quiz=结课测验' AFTER `attempt_type`"
        );
        ensureColumnExists(
            jdbcTemplate,
            "train_quiz_attempt",
            "course_quiz_key",
            "ALTER TABLE `train_quiz_attempt` ADD COLUMN `course_quiz_key` varchar(128) DEFAULT NULL COMMENT '结课测验去重键' AFTER `attempt_scene`"
        );
        ensureColumnExists(
            jdbcTemplate,
            "train_quiz_attempt",
            "duration_seconds",
            "ALTER TABLE `train_quiz_attempt` ADD COLUMN `duration_seconds` int(11) DEFAULT 0 COMMENT '考试总用时（秒）兼容字段' AFTER `duration`"
        );
        try
        {
            jdbcTemplate.update(
                "UPDATE train_quiz_attempt SET duration_seconds = COALESCE(duration, 0) " +
                    "WHERE duration_seconds IS NULL OR duration_seconds = 0"
            );
            jdbcTemplate.update(
                "UPDATE train_quiz_attempt " +
                    "SET attempt_scene = CASE " +
                    "WHEN attempt_type = 'exam' THEN 'exam' " +
                    "WHEN exam_name LIKE '%结课测验%' THEN 'course_quiz' " +
                    "ELSE 'practice' END " +
                    "WHERE attempt_scene IS NULL OR attempt_scene = ''"
            );
            jdbcTemplate.update(
                "UPDATE train_quiz_attempt " +
                    "SET course_quiz_key = CASE " +
                    "WHEN course_quiz_key IS NOT NULL AND course_quiz_key != '' THEN course_quiz_key " +
                    "WHEN exam_name IS NOT NULL AND exam_name != '' THEN exam_name " +
                    "ELSE CONCAT('attempt-', attempt_id) END " +
                    "WHERE (course_quiz_key IS NULL OR course_quiz_key = '') " +
                    "AND (attempt_scene = 'course_quiz' OR exam_name LIKE '%结课测验%')"
            );
        }
        catch (Exception e)
        {
            log.error("回填 train_quiz_attempt 兼容字段失败，将跳过继续启动", e);
        }
    }

    private void ensureCourseCategoryVideoUrlColumn(JdbcTemplate jdbcTemplate)
    {
        if (!tableExists(jdbcTemplate, "course_category"))
        {
            return;
        }

        try
        {
            if (columnExists(jdbcTemplate, "course_category", "video_url"))
            {
                return;
            }

            String alterSql;
            if (columnExists(jdbcTemplate, "course_category", "platform"))
            {
                alterSql = "ALTER TABLE `course_category` ADD COLUMN `video_url` varchar(500) DEFAULT NULL COMMENT '课程视频地址' AFTER `platform`";
            }
            else if (columnExists(jdbcTemplate, "course_category", "cover_image"))
            {
                alterSql = "ALTER TABLE `course_category` ADD COLUMN `video_url` varchar(500) DEFAULT NULL COMMENT '课程视频地址' AFTER `cover_image`";
            }
            else
            {
                alterSql = "ALTER TABLE `course_category` ADD COLUMN `video_url` varchar(500) DEFAULT NULL COMMENT '课程视频地址'";
            }

            jdbcTemplate.execute(alterSql);
            log.info("已为 course_category 添加字段 video_url");
        }
        catch (Exception e)
        {
            log.error("初始化 course_category.video_url 字段失败，将跳过继续启动", e);
        }
    }

    private void ensureTrainExamResultDisplayModeColumn(JdbcTemplate jdbcTemplate)
    {
        if (!tableExists(jdbcTemplate, "train_exam"))
        {
            return;
        }

        try
        {
            ensureColumnExists(
                jdbcTemplate,
                "train_exam",
                "result_display_mode",
                "ALTER TABLE `train_exam` ADD COLUMN `result_display_mode` varchar(20) NOT NULL DEFAULT 'score' COMMENT '结果展示方式：score=分数，level=等级' AFTER `exam_type`"
            );
        }
        catch (Exception e)
        {
            log.error("初始化 train_exam.result_display_mode 字段失败，将跳过继续启动", e);
        }
    }

    private void ensureTrainExamLevelThresholdColumns(JdbcTemplate jdbcTemplate)
    {
        if (!tableExists(jdbcTemplate, "train_exam"))
        {
            return;
        }

        try
        {
            ensureColumnExists(
                jdbcTemplate,
                "train_exam",
                "level_pass_score",
                "ALTER TABLE `train_exam` ADD COLUMN `level_pass_score` int(11) NOT NULL DEFAULT 60 COMMENT '等级模式合格分数线' AFTER `result_display_mode`"
            );
            ensureColumnExists(
                jdbcTemplate,
                "train_exam",
                "level_excellent_score",
                "ALTER TABLE `train_exam` ADD COLUMN `level_excellent_score` int(11) NOT NULL DEFAULT 85 COMMENT '等级模式优秀分数线' AFTER `level_pass_score`"
            );
            jdbcTemplate.update(
                "UPDATE train_exam SET level_pass_score = ? " +
                    "WHERE level_pass_score IS NULL OR level_pass_score < 1 OR level_pass_score >= 100",
                DEFAULT_LEVEL_PASS_SCORE
            );
            jdbcTemplate.update(
                "UPDATE train_exam SET level_excellent_score = LEAST(100, GREATEST(level_pass_score + 1, ?)) " +
                    "WHERE level_excellent_score IS NULL OR level_excellent_score <= level_pass_score OR level_excellent_score > 100",
                DEFAULT_LEVEL_EXCELLENT_SCORE
            );
        }
        catch (Exception e)
        {
            log.error("初始化 train_exam 等级分数线字段失败，将跳过继续启动", e);
        }
    }

    private void ensureTrainExamMaxAttemptsColumn(JdbcTemplate jdbcTemplate)
    {
        if (!tableExists(jdbcTemplate, "train_exam"))
        {
            return;
        }

        try
        {
            ensureColumnExists(
                jdbcTemplate,
                "train_exam",
                "max_attempts",
                "ALTER TABLE `train_exam` ADD COLUMN `max_attempts` int(11) NOT NULL DEFAULT 1 COMMENT '最多可考次数' AFTER `level_excellent_score`"
            );
            jdbcTemplate.update(
                "UPDATE train_exam SET max_attempts = ? WHERE max_attempts IS NULL OR max_attempts < 1",
                DEFAULT_MAX_ATTEMPTS
            );
        }
        catch (Exception e)
        {
            log.error("初始化 train_exam.max_attempts 字段失败，将跳过继续启动", e);
        }
    }

    private void backfillTrainQuizAttemptResultDisplayMode(JdbcTemplate jdbcTemplate)
    {
        if (!tableExists(jdbcTemplate, "train_quiz_attempt"))
        {
            return;
        }

        try
        {
            if (!tableExists(jdbcTemplate, "train_exam"))
            {
                jdbcTemplate.update(
                    "UPDATE train_quiz_attempt " +
                        "SET result_display_mode = 'score' " +
                        "WHERE result_display_mode IS NULL OR result_display_mode = ''"
                );
                return;
            }

            jdbcTemplate.update(
                "UPDATE train_quiz_attempt tqa " +
                    "LEFT JOIN train_exam te ON tqa.exam_id = te.id " +
                    "SET tqa.result_display_mode = CASE " +
                    "WHEN tqa.exam_id IS NULL OR tqa.exam_id = 0 THEN 'score' " +
                    "ELSE COALESCE(te.result_display_mode, 'score') " +
                    "END " +
                    "WHERE tqa.result_display_mode IS NULL OR tqa.result_display_mode = ''"
            );
        }
        catch (Exception e)
        {
            log.error("回填 train_quiz_attempt.result_display_mode 字段失败，将跳过继续启动", e);
        }
    }

    private void backfillTrainQuizAttemptLevelThresholds(JdbcTemplate jdbcTemplate)
    {
        if (!tableExists(jdbcTemplate, "train_quiz_attempt"))
        {
            return;
        }

        try
        {
            if (!tableExists(jdbcTemplate, "train_exam"))
            {
                jdbcTemplate.update(
                    "UPDATE train_quiz_attempt " +
                        "SET level_pass_score = ? " +
                        "WHERE level_pass_score IS NULL OR level_pass_score < 1 OR level_pass_score >= 100",
                    DEFAULT_LEVEL_PASS_SCORE
                );
                jdbcTemplate.update(
                    "UPDATE train_quiz_attempt " +
                        "SET level_excellent_score = LEAST(100, GREATEST(COALESCE(level_pass_score, ?) + 1, ?)) " +
                        "WHERE level_excellent_score IS NULL OR level_excellent_score <= COALESCE(level_pass_score, ?) OR level_excellent_score > 100",
                    DEFAULT_LEVEL_PASS_SCORE,
                    DEFAULT_LEVEL_EXCELLENT_SCORE,
                    DEFAULT_LEVEL_PASS_SCORE
                );
                return;
            }

            jdbcTemplate.update(
                "UPDATE train_quiz_attempt tqa " +
                    "LEFT JOIN train_exam te ON tqa.exam_id = te.id " +
                    "SET tqa.level_pass_score = CASE " +
                    "WHEN tqa.exam_id IS NULL OR tqa.exam_id = 0 THEN ? " +
                    "ELSE COALESCE(te.level_pass_score, ?) " +
                    "END " +
                    "WHERE tqa.level_pass_score IS NULL OR tqa.level_pass_score < 1 OR tqa.level_pass_score >= 100",
                DEFAULT_LEVEL_PASS_SCORE,
                DEFAULT_LEVEL_PASS_SCORE
            );
            jdbcTemplate.update(
                "UPDATE train_quiz_attempt tqa " +
                    "LEFT JOIN train_exam te ON tqa.exam_id = te.id " +
                    "SET tqa.level_excellent_score = CASE " +
                    "WHEN tqa.exam_id IS NULL OR tqa.exam_id = 0 THEN LEAST(100, GREATEST(tqa.level_pass_score + 1, ?)) " +
                    "ELSE LEAST(100, GREATEST(tqa.level_pass_score + 1, COALESCE(te.level_excellent_score, ?), ?)) " +
                    "END " +
                    "WHERE tqa.level_excellent_score IS NULL OR tqa.level_excellent_score <= tqa.level_pass_score OR tqa.level_excellent_score > 100",
                DEFAULT_LEVEL_EXCELLENT_SCORE,
                DEFAULT_LEVEL_EXCELLENT_SCORE,
                DEFAULT_LEVEL_EXCELLENT_SCORE
            );
        }
        catch (Exception e)
        {
            log.error("回填 train_quiz_attempt 等级分数线字段失败，将跳过继续启动", e);
        }
    }

    private boolean tableExists(JdbcTemplate jdbcTemplate, String tableName)
    {
        Integer count = jdbcTemplate.queryForObject(
            "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = ?",
            Integer.class,
            tableName
        );
        return count != null && count > 0;
    }

    private boolean columnExists(JdbcTemplate jdbcTemplate, String tableName, String columnName)
    {
        Integer count = jdbcTemplate.queryForObject(
            "SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = ? AND column_name = ?",
            Integer.class,
            tableName,
            columnName
        );
        return count != null && count > 0;
    }

    private void ensureColumnExists(JdbcTemplate jdbcTemplate, String tableName, String columnName, String addColumnSql)
    {
        Integer count = jdbcTemplate.queryForObject(
            "SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = ? AND column_name = ?",
            Integer.class,
            tableName,
            columnName
        );

        if (count != null && count > 0)
        {
            return;
        }

        jdbcTemplate.execute(addColumnSql);
        log.info("已为 {} 添加字段 {}", tableName, columnName);
    }
}
