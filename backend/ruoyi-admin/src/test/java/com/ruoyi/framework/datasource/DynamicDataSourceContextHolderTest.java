package com.ruoyi.framework.datasource;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

class DynamicDataSourceContextHolderTest
{
    @AfterEach
    void tearDown()
    {
        while (DynamicDataSourceContextHolder.getDataSourceType() != null)
        {
            DynamicDataSourceContextHolder.clearDataSourceType();
        }
    }

    @Test
    void nestedDataSourceContext_restoresOuterContextAfterInnerClear()
    {
        DynamicDataSourceContextHolder.setDataSourceType("SLAVE");
        DynamicDataSourceContextHolder.setDataSourceType("MASTER");

        assertEquals("MASTER", DynamicDataSourceContextHolder.getDataSourceType());

        DynamicDataSourceContextHolder.clearDataSourceType();

        assertEquals("SLAVE", DynamicDataSourceContextHolder.getDataSourceType());

        DynamicDataSourceContextHolder.clearDataSourceType();

        assertNull(DynamicDataSourceContextHolder.getDataSourceType());
    }
}
