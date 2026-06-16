package com.ruoyi.web.controller.train;

import com.ruoyi.common.annotation.Log;
import com.ruoyi.common.annotation.DataSource;
import com.ruoyi.common.enums.DataSourceType;
import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.core.page.PageDomain;
import com.ruoyi.common.core.page.TableDataInfo;
import com.ruoyi.common.core.page.TableSupport;
import com.ruoyi.common.enums.BusinessType;
import com.ruoyi.common.utils.poi.ExcelUtil;
import com.ruoyi.system.domain.TrainExam;
import com.ruoyi.system.domain.TrainExamAssign;
import com.ruoyi.system.service.ITrainExamService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import com.ruoyi.system.service.ITrainExamAssignService;
import com.ruoyi.system.service.ITrainQuestionService;
import com.ruoyi.system.mapper.TrainQuestionMapper;
import com.ruoyi.system.mapper.TrainExamQuestionMapper;
import com.ruoyi.system.domain.TrainQuestion;
import com.ruoyi.system.domain.TrainExamQuestion;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import javax.servlet.http.HttpServletResponse;
import java.sql.SQLSyntaxErrorException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 培训考试管理控制器
 */
@RestController
@RequestMapping("/train/exam")
public class TrainExamController extends BaseController {


    private static final Logger logger = LoggerFactory.getLogger(TrainExamController.class);

    @Autowired
    private ITrainExamService trainExamService;

    @Autowired
    private ITrainExamAssignService trainExamAssignService;

    @Autowired
    private TrainQuestionMapper trainQuestionMapper;

    @Autowired
    private ITrainQuestionService trainQuestionService;

    @Autowired
    private TrainExamQuestionMapper trainExamQuestionMapper;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @PreAuthorize("isAuthenticated()")
    @GetMapping("/list")
    @DataSource(DataSourceType.SLAVE)
    public TableDataInfo list(TrainExam trainExam) {
        try {
            startPage();
            List<TrainExam> list = trainExamService.selectTrainExamList(trainExam);
            return getDataTable(list);
        } catch (Exception e) {
            if (!isMissingExamTypeColumn(e)) {
                throw e;
            }

            PageDomain pageDomain = TableSupport.buildPageRequest();
            int pageNum = pageDomain.getPageNum() != null ? pageDomain.getPageNum() : 1;
            int pageSize = pageDomain.getPageSize() != null ? pageDomain.getPageSize() : 10;
            int offset = Math.max(pageNum - 1, 0) * pageSize;

            StringBuilder where = new StringBuilder(" where 1=1 ");
            List<Object> args = new ArrayList<>();

            if (trainExam != null) {
                if (trainExam.getName() != null && !trainExam.getName().trim().isEmpty()) {
                    where.append(" and name like ? ");
                    args.add("%" + trainExam.getName().trim() + "%");
                }
                if (trainExam.getStatus() != null && !trainExam.getStatus().trim().isEmpty()) {
                    where.append(" and status = ? ");
                    args.add(trainExam.getStatus().trim());
                }
            }

            Long total = jdbcTemplate.queryForObject(
                    "select count(1) from train_exam" + where,
                    args.toArray(),
                    Long.class
            );

            List<Object> pageArgs = new ArrayList<>(args);
            pageArgs.add(offset);
            pageArgs.add(pageSize);

            List<Map<String, Object>> rows = jdbcTemplate.queryForList(
                    "select id, name, status, start_time, end_time, create_time, remark, result_display_mode, " +
                            "level_pass_score, level_excellent_score, max_attempts from train_exam" + where + " order by id desc limit ?, ?",
                    pageArgs.toArray()
            );

            List<TrainExam> list = new ArrayList<>();
            for (Map<String, Object> r : rows) {
                list.add(mapTrainExamWithoutExamType(r));
            }

            TableDataInfo rspData = new TableDataInfo();
            rspData.setCode(200);
            rspData.setMsg("查询成功");
            rspData.setRows(list);
            rspData.setTotal(total != null ? total : 0L);
            return rspData;
        }
    }

    @PreAuthorize("@ss.hasPermi('train:exam:list')")
    @GetMapping("/admin/list")
    @DataSource(DataSourceType.SLAVE)
    public TableDataInfo adminList(TrainExam trainExam) {
        return list(trainExam);
    }

    // @PreAuthorize("@ss.hasPermi('train:exam:query')")
    @PreAuthorize("isAuthenticated()")
    @GetMapping(value = "/{id}")
    public AjaxResult getInfo(@PathVariable Long id) {
        return success(trainExamService.selectTrainExamById(id));
    }

    @PreAuthorize("@ss.hasPermi('train:exam:query')")
    @GetMapping(value = "/admin/{id}")
    @DataSource(DataSourceType.SLAVE)
    public AjaxResult getAdminInfo(@PathVariable Long id) {
        try {
            return success(trainExamService.selectTrainExamById(id));
        } catch (Exception e) {
            if (!isMissingExamTypeColumn(e)) {
                throw e;
            }

            List<Map<String, Object>> rows = jdbcTemplate.queryForList(
                    "select id, name, status, start_time, end_time, create_time, remark, result_display_mode, " +
                            "level_pass_score, level_excellent_score, max_attempts from train_exam where id = ? limit 1",
                    id
            );
            if (rows == null || rows.isEmpty()) {
                return success(null);
            }
            return success(mapTrainExamWithoutExamType(rows.get(0)));
        }
    }

    @PreAuthorize("@ss.hasPermi('train:exam:add')")
    @Log(title = "考试管理", businessType = BusinessType.INSERT)
    @PostMapping
    public AjaxResult add(@RequestBody TrainExam trainExam) {
        trainExam.setCreateBy(getUsername());
        int rows = trainExamService.insertTrainExam(trainExam);
        if (rows <= 0) {
            return error("保存考试失败");
        }
        return success(trainExam);
    }

    @PreAuthorize("@ss.hasPermi('train:exam:edit')")
    @Log(title = "考试管理", businessType = BusinessType.UPDATE)
    @PutMapping
    public AjaxResult edit(@RequestBody TrainExam trainExam) {
        trainExam.setUpdateBy(getUsername());
        int rows = trainExamService.updateTrainExam(trainExam);
        if (rows <= 0) {
            return error("更新考试失败");
        }
        return success(trainExam);
    }

    @PreAuthorize("@ss.hasPermi('train:exam:remove')")
    @Log(title = "考试管理", businessType = BusinessType.DELETE)
    @DeleteMapping("/{ids}")
    public AjaxResult remove(@PathVariable Long[] ids) {
        return toAjax(trainExamService.deleteTrainExamByIds(ids));
    }

    @PreAuthorize("@ss.hasPermi('train:exam:query')")
    @GetMapping("/assign-info/{examId}")
    public AjaxResult getAssign(@PathVariable Long examId) {
        List<TrainExamAssign> assigns = trainExamAssignService.selectByExamId(examId);
        return success(assigns);
    }

    @PreAuthorize("@ss.hasPermi('train:exam:assign')")
    @Log(title = "考试权限管理", businessType = BusinessType.UPDATE)
    @PostMapping("/assign-info/{examId}")
    public AjaxResult saveAssign(@PathVariable Long examId, @RequestBody List<TrainExamAssign> assigns) {
        return toAjax(trainExamAssignService.batchInsert(examId, assigns, getUsername()));
    }

    // 获取考试题目列表
    @PreAuthorize("isAuthenticated()")
    @DataSource(DataSourceType.SLAVE)
    @GetMapping("/questions/{examId}")
    public AjaxResult getQuestions(@PathVariable Long examId) {
        // 从 train_exam_question 表查询考试题目
        List<TrainExamQuestion> examQuestions = trainExamQuestionMapper.selectByExamId(examId);
        if (examQuestions == null || examQuestions.isEmpty()) {
            return success(Collections.emptyList());
        }
        
        // 获取题目ID列表
        List<Long> questionIds = examQuestions.stream()
                .map(TrainExamQuestion::getQuestionId)
                .collect(java.util.stream.Collectors.toList());
        
        // 批量查询题目详情
        List<TrainQuestion> questions = trainQuestionMapper.selectByIds(questionIds);
        
        // 创建题目ID到详情的映射
        Map<Long, TrainQuestion> questionMap = questions.stream()
                .collect(java.util.stream.Collectors.toMap(TrainQuestion::getId, q -> q));
        
        // 转换成前端需要的格式（包含题目详情）
        List<Map<String, Object>> result = new java.util.ArrayList<>();
        for (TrainExamQuestion eq : examQuestions) {
            TrainQuestion question = questionMap.get(eq.getQuestionId());
            if (question != null) {
                Map<String, Object> m = new java.util.HashMap<>();
                m.put("questionId", eq.getQuestionId());
                m.put("sortOrder", eq.getSortOrder());
                m.put("score", eq.getScore());
                // 添加题目详情
                m.put("questionText", question.getQuestionText());
                m.put("questionType", question.getQuestionType());
                m.put("optionA", question.getOptionA());
                m.put("optionB", question.getOptionB());
                m.put("optionC", question.getOptionC());
                m.put("optionD", question.getOptionD());
                m.put("correctAnswer", question.getCorrectAnswer());
                m.put("difficulty", question.getDifficulty());
                m.put("analysis", question.getExplanation());
                result.add(m);
            }
        }
        return success(result);
    }

    @PreAuthorize("@ss.hasPermi('train:exam:query')")
    @DataSource(DataSourceType.SLAVE)
    @GetMapping("/admin/questions/{examId}")
    public AjaxResult getAdminQuestions(@PathVariable Long examId) {
        return getQuestions(examId);
    }

    /**
     * 结业考试自动分配题目（非随机，按规则分配）
     * 规则来源：
     * - 请求体可传 limit（总题数）、typeDistribution（题型占比/数量）、difficultyDistribution（难度占比/数量）、categories（可选分类列表）
     * - 如不传规则，采用默认分配：题型(单选50%、多选30%、判断20%)；难度(易40%、中40%、难20%)
     * - 选题顺序：按 sort_order ASC, id DESC，避免随机
     * - 已存在题目的结业考试跳过
     * 返回：{ totalExams, updatedExams, skippedExams }
     */
    @Log(title = "结业考试自动分题", businessType = BusinessType.UPDATE)
    @PreAuthorize("@ss.hasPermi('train:exam:edit')")
    @PostMapping("/graduation/auto-assign")
    @DataSource(DataSourceType.SLAVE)
    public AjaxResult autoAssignGraduation(@RequestBody Map<String, Object> req) {
        int limit = parseInt(req.get("limit"), 20);
        Map<String, Object> typeDist = safeMap(req.get("typeDistribution"));
        Map<String, Object> diffDist = safeMap(req.get("difficultyDistribution"));
        List<String> categories = parseStringList(req.get("categories"));
        
        // 查找结业考试（兼容 exam_type = final_exam / graduation_exam，或名称包含“结业”）
        List<TrainExam> exams = new ArrayList<>();
        try {
            TrainExam q1 = new TrainExam();
            q1.setExamType("final_exam");
            exams.addAll(nullSafe(trainExamService.selectTrainExamList(q1)));
            TrainExam q2 = new TrainExam();
            q2.setExamType("graduation_exam");
            exams.addAll(nullSafe(trainExamService.selectTrainExamList(q2)));
            // 去重并兜底按名称匹配
            Map<Long, TrainExam> map = new HashMap<>();
            for (TrainExam e : exams) { if (e != null && e.getId() != null) map.put(e.getId(), e); }
            List<TrainExam> all = nullSafe(trainExamService.selectTrainExamList(new TrainExam()));
            for (TrainExam e : all) {
                if (e != null && e.getId() != null) {
                    String name = e.getName() != null ? e.getName() : "";
                    if (name.contains("结业")) {
                        map.put(e.getId(), e);
                    }
                }
            }
            exams = new ArrayList<>(map.values());
        } catch (Exception ex) {
            exams = nullSafe(trainExamService.selectTrainExamList(new TrainExam()));
        }
        
        int totalExams = exams.size();
        int updatedExams = 0;
        int skippedExams = 0;
        
        // 题型默认占比
        DistCount typeCount = buildTypeCount(limit, typeDist);
        // 难度默认占比
        DistCount diffCount = buildDiffCount(limit, diffDist);
        
        for (TrainExam exam : exams) {
            if (exam == null || exam.getId() == null) continue;
            Long examId = exam.getId();
            // 已有题目则跳过
            List<TrainExamQuestion> exists = null;
            try {
                exists = trainExamQuestionMapper.selectByExamId(examId);
            } catch (Exception e) { logger.debug("查询考试题目失败: examId={}, {}", examId, e.getMessage()); }
            if (exists != null && !exists.isEmpty()) {
                skippedExams++;
                continue;
            }
            
            // 分配题目（非随机，按题型/难度规则）
            List<Long> picked = new ArrayList<>();
            List<TrainExamQuestion> toInsert = new ArrayList<>();
            
            // 题型映射支持中英
            String[] singleTypes = new String[] {"single", "单选"};
            String[] multipleTypes = new String[] {"multiple", "多选"};
            String[] judgeTypes = new String[] {"judge", "判断", "boolean", "是非"};
            
            int sort = 0;
            // 单选
            sort = pickByTypeAndDifficulty(picked, toInsert, examId, singleTypes, categories, typeCount.single, diffCount, sort);
            // 多选
            sort = pickByTypeAndDifficulty(picked, toInsert, examId, multipleTypes, categories, typeCount.multiple, diffCount, sort);
            // 判断
            sort = pickByTypeAndDifficulty(picked, toInsert, examId, judgeTypes, categories, typeCount.judge, diffCount, sort);
            
            // 如果不足总量，按不区分题型继续补齐（同样按难度顺序）
            if (toInsert.size() < limit) {
                int need = limit - toInsert.size();
                sort = pickAnyByDifficulty(picked, toInsert, examId, categories, need, diffCount, sort);
            }
            
            // 插入
            if (!toInsert.isEmpty()) {
                trainExamQuestionMapper.insertBatch(toInsert);
                updatedExams++;
            } else {
                skippedExams++;
            }
        }
        
        Map<String, Object> result = new HashMap<>();
        result.put("totalExams", totalExams);
        result.put("updatedExams", updatedExams);
        result.put("skippedExams", skippedExams);
        return success(result);
    }
    
    private int pickByTypeAndDifficulty(List<Long> picked, List<TrainExamQuestion> toInsert, Long examId,
                                        String[] typeCandidates, List<String> categories, int totalNeed,
                                        DistCount diffCount, int sort) {
        if (totalNeed <= 0) return sort;
        int remain = totalNeed;
        // 按难度配额依次挑选：easy -> medium -> hard
        int needEasy = Math.min(remain, diffCount.easyFor(totalNeed));
        sort = pickQuestions(picked, toInsert, examId, typeCandidates, "easy", categories, needEasy, sort);
        remain -= needEasy;
        if (remain > 0) {
            int needMedium = Math.min(remain, diffCount.mediumFor(totalNeed));
            sort = pickQuestions(picked, toInsert, examId, typeCandidates, "medium", categories, needMedium, sort);
            remain -= needMedium;
        }
        if (remain > 0) {
            int needHard = remain;
            sort = pickQuestions(picked, toInsert, examId, typeCandidates, "hard", categories, needHard, sort);
            remain -= needHard;
        }
        return sort;
    }
    
    private int pickAnyByDifficulty(List<Long> picked, List<TrainExamQuestion> toInsert, Long examId,
                                    List<String> categories, int totalNeed, DistCount diffCount, int sort) {
        if (totalNeed <= 0) return sort;
        int remain = totalNeed;
        int needEasy = Math.min(remain, diffCount.easyFor(totalNeed));
        sort = pickQuestions(picked, toInsert, examId, null, "easy", categories, needEasy, sort);
        remain -= needEasy;
        if (remain > 0) {
            int needMedium = Math.min(remain, diffCount.mediumFor(totalNeed));
            sort = pickQuestions(picked, toInsert, examId, null, "medium", categories, needMedium, sort);
            remain -= needMedium;
        }
        if (remain > 0) {
            int needHard = remain;
            sort = pickQuestions(picked, toInsert, examId, null, "hard", categories, needHard, sort);
            remain -= needHard;
        }
        return sort;
    }
    
    private int pickQuestions(List<Long> picked, List<TrainExamQuestion> toInsert, Long examId,
                              String[] typeCandidates, String difficulty, List<String> categories,
                              int need, int sort) {
        if (need <= 0) return sort;
        // 依次按候选题型查询，直到满足需要或无更多
        for (int t = 0; t < (typeCandidates == null ? 1 : typeCandidates.length); t++) {
            String type = (typeCandidates == null ? null : typeCandidates[t]);
            int left = need;
            // 按分类逐个查询（如未指定分类，则直接查询全部）
            if (categories != null && !categories.isEmpty()) {
                for (String cat : categories) {
                    left = fetchAndAppend(picked, toInsert, examId, type, difficulty, cat, left, sort);
                    sort += (need - left) - (toInsert.size() - picked.size()); // sort 已在 fetch 内更新，这里仅确保变量推进
                    if (left <= 0) break;
                }
            } else {
                left = fetchAndAppend(picked, toInsert, examId, type, difficulty, null, left, sort);
            }
            need = left;
            if (need <= 0) break;
        }
        return sort;
    }
    
    private int fetchAndAppend(List<Long> picked, List<TrainExamQuestion> toInsert, Long examId,
                               String type, String difficulty, String category,
                               int need, int sort) {
        if (need <= 0) return sort;
        // 组装查询条件（非随机，按 sort_order ASC, id DESC）
        com.ruoyi.system.domain.TrainQuestion q = new com.ruoyi.system.domain.TrainQuestion();
        if (type != null) q.setQuestionType(type);
        if (difficulty != null) q.setDifficulty(difficulty);
        if (category != null) q.setCategory(category);
        q.setStatus(1);
        List<com.ruoyi.system.domain.TrainQuestion> list = nullSafe(trainQuestionService.selectTrainQuestionList(q));
        for (com.ruoyi.system.domain.TrainQuestion item : list) {
            if (need <= 0) break;
            if (item == null || item.getId() == null) continue;
            Long qid = item.getId();
            if (picked.contains(qid)) continue;
            TrainExamQuestion eq = new TrainExamQuestion();
            eq.setExamId(examId);
            eq.setQuestionId(qid);
            eq.setSortOrder(sort++);
            eq.setScore(1);
            toInsert.add(eq);
            picked.add(qid);
            need--;
        }
        return sort;
    }
    
    private DistCount buildTypeCount(int limit, Map<String, Object> typeDist) {
        // 默认比例：单选50%、多选30%、判断20%
        int single = (int) Math.round(limit * 0.5);
        int multiple = (int) Math.round(limit * 0.3);
        int judge = Math.max(0, limit - single - multiple);
        if (typeDist != null && !typeDist.isEmpty()) {
            single = parseInt(typeDist.get("single"), single);
            multiple = parseInt(typeDist.get("multiple"), multiple);
            judge = parseInt(typeDist.get("judge"), judge);
            int sum = single + multiple + judge;
            if (sum != limit && sum > 0) {
                // 按比例归一化到 limit
                double rate = limit * 1.0 / sum;
                single = (int) Math.floor(single * rate);
                multiple = (int) Math.floor(multiple * rate);
                judge = Math.max(0, limit - single - multiple);
            }
        }
        return new DistCount(single, multiple, judge, 0,0,0);
    }
    
    private DistCount buildDiffCount(int limit, Map<String, Object> diffDist) {
        // 默认比例：易40%、中40%、难20%
        double e = 0.4, m = 0.4, h = 0.2;
        if (diffDist != null && !diffDist.isEmpty()) {
            e = parseDouble(diffDist.get("easy"), e);
            m = parseDouble(diffDist.get("medium"), m);
            h = parseDouble(diffDist.get("hard"), h);
            double sum = e + m + h;
            if (sum <= 0) { e = 0.4; m = 0.4; h = 0.2; }
        }
        return new DistCount(0,0,0, e, m, h);
    }
    
    private static class DistCount {
        int single, multiple, judge;
        double easyRate, mediumRate, hardRate;
        DistCount(int s, int m, int j, double er, double mr, double hr) {
            this.single = s; this.multiple = m; this.judge = j;
            this.easyRate = er; this.mediumRate = mr; this.hardRate = hr;
        }
        int easyFor(int total) { return (int) Math.round(total * easyRate); }
        int mediumFor(int total) { return (int) Math.round(total * mediumRate); }
        int hardFor(int total) { return Math.max(0, total - easyFor(total) - mediumFor(total)); }
    }
    
    private static int parseInt(Object o, int def) {
        try { return o == null ? def : Integer.valueOf(String.valueOf(o)); } catch (Exception e) { return def; }
    }
    private static double parseDouble(Object o, double def) {
        try { return o == null ? def : Double.valueOf(String.valueOf(o)); } catch (Exception e) { return def; }
    }
    private static Map<String, Object> safeMap(Object o) {
        try { return (Map<String, Object>) o; } catch (Exception e) { return null; }
    }
    private static List<String> parseStringList(Object o) {
        List<String> r = new ArrayList<>();
        if (o instanceof List) {
            for (Object x : (List<?>) o) { if (x != null) r.add(String.valueOf(x)); }
        }
        return r;
    }
    private static <T> List<T> nullSafe(List<T> list) { return list != null ? list : new ArrayList<>(); }
    private boolean isMissingExamTypeColumn(Exception e) {
        if (e == null) return false;
        Throwable cause = e.getCause();
        return (cause instanceof SQLSyntaxErrorException || e instanceof SQLSyntaxErrorException)
                && String.valueOf(e.getMessage()).contains("exam_type");
    }
    // 保存/替换考试题目：使用 train_exam_question 关联表
    @DataSource(DataSourceType.SLAVE)
    @PreAuthorize("@ss.hasPermi('train:exam:edit')")
    @PostMapping("/questions/{examId}")
    public AjaxResult saveQuestions(@PathVariable Long examId, @RequestBody List<Map<String, Object>> list) {
        // 先删除该考试的所有题目
        trainExamQuestionMapper.deleteByExamId(examId);
        
        // 如果没有新题目，直接返回
        if (list == null || list.isEmpty()) {
            return success();
        }
        
        // 插入新的题目关联
        List<TrainExamQuestion> examQuestions = new java.util.ArrayList<>();
        for (int i = 0; i < list.size(); i++) {
            Map<String, Object> m = list.get(i);
            if (m == null) continue;
            TrainExamQuestion eq = new TrainExamQuestion();
            eq.setExamId(examId);
            Object questionIdObj = m.get("questionId");
            if (questionIdObj == null) continue;
            eq.setQuestionId(Long.valueOf(String.valueOf(questionIdObj)));
            Object sortOrderObj = m.get("sortOrder");
            eq.setSortOrder(sortOrderObj != null ? Integer.valueOf(String.valueOf(sortOrderObj)) : i);
            Object scoreObj = m.get("score");
            eq.setScore(scoreObj != null ? Integer.valueOf(String.valueOf(scoreObj)) : 1);
            examQuestions.add(eq);
        }
        
        if (examQuestions.isEmpty()) {
            return success();
        }
        trainExamQuestionMapper.insertBatch(examQuestions);
        return success();
    }

    @PreAuthorize("@ss.hasPermi('train:exam:export')")
    @Log(title = "考试管理", businessType = BusinessType.EXPORT)
    @PostMapping("/export")
    public void export(HttpServletResponse response, TrainExam trainExam) {
        List<TrainExam> list = trainExamService.selectTrainExamList(trainExam);
        ExcelUtil<TrainExam> util = new ExcelUtil<TrainExam>(TrainExam.class);
        util.exportExcel(response, list, "考试数据");
    }
    
    /**
     * 获取当前用户待参加的考试列表
     */
    @PreAuthorize("isAuthenticated()")
    @GetMapping("/my/upcoming")
    public AjaxResult getMyUpcomingExams(@RequestParam(required = false) Long userId) {
        Long currentUserId = getUserId();
        List<TrainExam> exams = trainExamService.selectUpcomingExamsByUserId(currentUserId);
        return success(exams);
    }
    
    /**
     * 获取当前用户已参加的考试列表
     */
    @PreAuthorize("isAuthenticated()")
    @GetMapping("/my/completed")
    public AjaxResult getMyCompletedExams(@RequestParam(required = false) Long userId) {
        Long currentUserId = getUserId();
        List<TrainExam> exams = trainExamService.selectCompletedExamsByUserId(currentUserId);
        return success(exams);
    }


    private boolean isMissingExamTypeColumn(Throwable t) {
        Throwable cur = t;
        while (cur != null) {
            if (cur instanceof SQLSyntaxErrorException) {
                String msg = cur.getMessage();
                if (msg != null && msg.contains("Unknown column") && msg.contains("exam_type")) {
                    return true;
                }
            }
            cur = cur.getCause();
        }
        return false;
    }

    private TrainExam mapTrainExamWithoutExamType(Map<String, Object> row) {
        TrainExam exam = new TrainExam();
        Object idObj = row.get("id");
        if (idObj instanceof Number) {
            exam.setId(((Number) idObj).longValue());
        } else if (idObj != null) {
            try {
                exam.setId(Long.parseLong(String.valueOf(idObj)));
            } catch (Exception ignored) {
            }
        }
        Object nameObj = row.get("name");
        if (nameObj != null) {
            exam.setName(String.valueOf(nameObj));
        }
        Object statusObj = row.get("status");
        if (statusObj != null) {
            exam.setStatus(String.valueOf(statusObj));
        }
        Object startObj = row.get("start_time");
        if (startObj instanceof java.util.Date) {
            exam.setStartTime((java.util.Date) startObj);
        }
        Object endObj = row.get("end_time");
        if (endObj instanceof java.util.Date) {
            exam.setEndTime((java.util.Date) endObj);
        }
        Object createObj = row.get("create_time");
        if (createObj instanceof java.util.Date) {
            exam.setCreateTime((java.util.Date) createObj);
        }
        Object remarkObj = row.get("remark");
        if (remarkObj != null) {
            exam.setRemark(String.valueOf(remarkObj));
        }
        Object resultDisplayModeObj = row.get("result_display_mode");
        exam.setResultDisplayMode(resultDisplayModeObj != null ? String.valueOf(resultDisplayModeObj) : "score");
        Object levelPassScoreObj = row.get("level_pass_score");
        exam.setLevelPassScore(parseThresholdValue(levelPassScoreObj, 60));
        Object levelExcellentScoreObj = row.get("level_excellent_score");
        exam.setLevelExcellentScore(parseThresholdValue(levelExcellentScoreObj, 85));
        Object maxAttemptsObj = row.get("max_attempts");
        exam.setMaxAttempts(parseThresholdValue(maxAttemptsObj, 1));
        exam.setExamType("final_exam");
        return exam;
    }

    private Integer parseThresholdValue(Object value, int defaultValue) {
        if (value instanceof Number) {
            return ((Number) value).intValue();
        }
        if (value != null) {
            try {
                return Integer.parseInt(String.valueOf(value));
            } catch (Exception ignored) {
            }
        }
        return defaultValue;
    }
}
