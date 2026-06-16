package com.ruoyi.web.controller.train;

import java.util.Collections;
import java.util.List;
import java.util.Map;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import com.ruoyi.common.annotation.DataSource;
import com.ruoyi.common.annotation.Log;
import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.core.domain.entity.SysUser;
import com.ruoyi.common.enums.BusinessType;
import com.ruoyi.common.enums.DataSourceType;
import com.ruoyi.common.utils.StringUtils;
import com.ruoyi.system.domain.DeptQuestionBankScope;
import com.ruoyi.system.service.IDeptQuestionBankScopeService;

/**
 * 部门题库权限配置Controller
 */
@RestController
@RequestMapping("/train/dept-question-bank-scope")
public class DeptQuestionBankScopeController extends BaseController {

    private static final String DEFAULT_TENANT_ID = "000000";

    @Autowired
    private IDeptQuestionBankScopeService deptQuestionBankScopeService;

    @PreAuthorize("@ss.hasPermi('train:deptQuestionBankScope:list')")
    @GetMapping("/banks")
    @DataSource(DataSourceType.SLAVE)
    public AjaxResult listBanks(@RequestParam(required = false) String tenantId) {
        List<Map<String, Object>> banks = deptQuestionBankScopeService.selectBankStats(resolveOperateTenantId(tenantId));
        return success(banks);
    }

    @PreAuthorize("@ss.hasPermi('train:deptQuestionBankScope:query')")
    @GetMapping("/dept-ids")
    @DataSource(DataSourceType.SLAVE)
    public AjaxResult getVisibleDeptIds(@RequestParam String deptType, @RequestParam(required = false) String tenantId) {
        if (StringUtils.isEmpty(deptType)) {
            return success(Collections.emptyList());
        }
        return success(deptQuestionBankScopeService.selectVisibleDeptIdsByDeptType(resolveOperateTenantId(tenantId), deptType));
    }

    @PreAuthorize("@ss.hasPermi('train:deptQuestionBankScope:edit')")
    @Log(title = "部门题库权限配置", businessType = BusinessType.UPDATE)
    @PostMapping
    @DataSource(DataSourceType.SLAVE)
    public AjaxResult save(@RequestBody DeptQuestionBankScope scope) {
        if (scope == null || StringUtils.isEmpty(scope.getDeptType())) {
            return error("题库分类不能为空");
        }
        deptQuestionBankScopeService.replaceVisibleDeptIds(
                resolveOperateTenantId(scope.getTenantId()),
                scope.getDeptType(),
                scope.getVisibleDeptIds(),
                getUsername());
        return success();
    }

    private String resolveOperateTenantId(String requestedTenantId) {
        try {
            SysUser user = getLoginUser().getUser();
            if (user == null) {
                return normalizeTenantId(requestedTenantId);
            }
            if (user.isSuperAdmin() || user.isPlatformAdmin()) {
                return normalizeTenantId(StringUtils.isNotEmpty(requestedTenantId) ? requestedTenantId : user.getTenantId());
            }
            return normalizeTenantId(user.getTenantId());
        } catch (Exception e) {
            return normalizeTenantId(requestedTenantId);
        }
    }

    private String normalizeTenantId(String tenantId) {
        return StringUtils.isEmpty(tenantId) ? DEFAULT_TENANT_ID : tenantId.trim();
    }
}
