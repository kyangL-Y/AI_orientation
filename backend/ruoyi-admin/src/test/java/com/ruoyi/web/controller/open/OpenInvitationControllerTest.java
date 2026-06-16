package com.ruoyi.web.controller.open;

import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.system.domain.vo.InviteResolveVo;
import com.ruoyi.system.service.ISysInvitationService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class OpenInvitationControllerTest
{
    @InjectMocks
    private OpenInvitationController controller;

    @Mock
    private ISysInvitationService invitationService;

    @Test
    void resolve_defaults_to_register_scenario()
    {
        InviteResolveVo payload = new InviteResolveVo();
        payload.setInviteCode("INV123");
        payload.setTenantId("HZ001");
        payload.setStatus("active");
        when(invitationService.resolveInvitation("INV123", "token-1", "register")).thenReturn(payload);

        AjaxResult result = controller.resolve("INV123", "token-1", null);

        assertEquals(200, result.get("code"));
        assertEquals(payload, result.get("data"));
        verify(invitationService).resolveInvitation("INV123", "token-1", "register");
    }

    @Test
    void resolve_passes_through_explicit_scenario()
    {
        InviteResolveVo payload = new InviteResolveVo();
        payload.setInviteCode("INV123");
        payload.setTenantId("HZ001");
        payload.setStatus("active");
        when(invitationService.resolveInvitation("INV123", "token-1", "join")).thenReturn(payload);

        AjaxResult result = controller.resolve("INV123", "token-1", "join");

        assertEquals(200, result.get("code"));
        assertEquals(payload, result.get("data"));
        verify(invitationService).resolveInvitation("INV123", "token-1", "join");
    }
}
