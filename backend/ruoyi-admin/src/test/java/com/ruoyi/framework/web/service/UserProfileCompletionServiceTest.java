package com.ruoyi.framework.web.service;

import java.util.Arrays;
import org.junit.jupiter.api.Test;
import com.ruoyi.common.core.domain.entity.SysUser;
import com.ruoyi.common.core.domain.model.ProfileCompletionInfo;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertIterableEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

class UserProfileCompletionServiceTest
{
    private final UserProfileCompletionService service = new UserProfileCompletionService();

    @Test
    void buildProfileCompletion_whenUserMissing_marksAllCoreFieldsIncomplete()
    {
        ProfileCompletionInfo info = service.buildProfileCompletion(null);

        assertFalse(info.isCompleted());
        assertTrue(info.isNeedsProfileCompletion());
        assertFalse(info.isHasDisplayName());
        assertFalse(info.isHasTenant());
        assertFalse(info.isHasDept());
        assertIterableEquals(Arrays.asList("displayName", "tenantId", "deptId"), info.getMissingFields());
    }

    @Test
    void buildProfileCompletion_whenUsingTemporaryDisplayName_requiresProfileCompletion()
    {
        SysUser user = new SysUser();
        user.setUserName(UserProfileCompletionService.buildTemporaryDisplayName("13800000000", null));
        user.setPhonenumber("13800000000");
        user.setTenantId("T1001");
        user.setDeptId(2001L);

        ProfileCompletionInfo info = service.buildProfileCompletion(user);

        assertFalse(info.isCompleted());
        assertTrue(info.isNeedsProfileCompletion());
        assertFalse(info.isHasDisplayName());
        assertTrue(info.isHasTenant());
        assertTrue(info.isHasDept());
        assertIterableEquals(Arrays.asList("displayName"), info.getMissingFields());
    }

    @Test
    void buildProfileCompletion_whenDisplayNameEqualsEmail_requiresProfileCompletion()
    {
        SysUser user = new SysUser();
        user.setUserName("demo@example.com");
        user.setEmail("demo@example.com");
        user.setTenantId("T1001");
        user.setDeptId(2001L);

        ProfileCompletionInfo info = service.buildProfileCompletion(user);

        assertFalse(info.isCompleted());
        assertTrue(info.isNeedsProfileCompletion());
        assertFalse(info.isHasDisplayName());
        assertIterableEquals(Arrays.asList("displayName"), info.getMissingFields());
    }

    @Test
    void buildProfileCompletion_whenAllFieldsPresent_marksCompleted()
    {
        SysUser user = new SysUser();
        user.setUserName("张三");
        user.setNickName("张三");
        user.setEmail("demo@example.com");
        user.setTenantId("T1001");
        user.setDeptId(2001L);

        ProfileCompletionInfo info = service.buildProfileCompletion(user);

        assertTrue(info.isCompleted());
        assertFalse(info.isNeedsProfileCompletion());
        assertTrue(info.isHasDisplayName());
        assertTrue(info.isHasTenant());
        assertTrue(info.isHasDept());
        assertEquals("T1001", info.getTenantId());
        assertEquals(Long.valueOf(2001L), info.getDeptId());
        assertTrue(info.getMissingFields().isEmpty());
    }
}
