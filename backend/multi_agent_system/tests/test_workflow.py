"""
多智能体系统测试脚本

用于验证系统功能和性能
"""

import asyncio
import time
from datetime import datetime, timedelta
import sys
import os

# 添加项目路径
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from multi_agent_system.workflow import create_learning_report_workflow, initialize_state
from multi_agent_system.utils import CacheManager, DatabaseManager, AIClient
from multi_agent_system.config import settings


async def test_workflow():
    """测试完整工作流"""
    print("=" * 60)
    print("多智能体学习报告系统 - 功能测试")
    print("=" * 60)

    # 初始化依赖
    print("\n[1/5] 初始化系统组件...")
    cache_manager = CacheManager()
    db_manager = DatabaseManager()
    ai_client = AIClient()

    try:
        await cache_manager.connect()
        await db_manager.connect()
        print("✓ 系统组件初始化成功")
    except Exception as e:
        print(f"✗ 系统组件初始化失败: {e}")
        return

    # 创建工作流
    print("\n[2/5] 创建 LangGraph 工作流...")
    try:
        workflow = create_learning_report_workflow(
            cache_manager=cache_manager,
            db_manager=db_manager,
            ai_client=ai_client
        )
        print("✓ 工作流创建成功")
    except Exception as e:
        print(f"✗ 工作流创建失败: {e}")
        return

    # 初始化状态
    print("\n[3/5] 初始化测试数据...")
    test_user_id = 1  # 修改为实际存在的用户ID
    period_end = datetime.now()
    period_start = period_end - timedelta(days=7)

    state = initialize_state(
        user_id=test_user_id,
        period_type="weekly",
        period_start=period_start,
        period_end=period_end,
        tenant_id="000000",
        dept_id=100
    )
    print(f"✓ 测试数据初始化成功")
    print(f"  - 用户ID: {test_user_id}")
    print(f"  - 周期: {period_start.date()} ~ {period_end.date()}")

    # 执行工作流
    print("\n[4/5] 执行多智能体工作流...")
    start_time = time.time()

    try:
        result = await workflow.ainvoke(state)
        execution_time = (time.time() - start_time) * 1000

        print(f"✓ 工作流执行成功")
        print(f"  - 执行时间: {execution_time:.2f}ms")

        # 输出结果摘要
        print("\n[5/5] 报告生成结果:")

        final_report = result.get("final_report")
        if final_report:
            print(f"✓ 报告ID: {final_report.report_id}")
            print(f"✓ 综合得分: {final_report.statistics_data.department_ranking.user_score if final_report.statistics_data.department_ranking else 'N/A'}")
            print(f"✓ 数据完整度: {result.get('data_completeness', 0):.2%}")
            print(f"✓ 缓存命中率: {final_report.cache_hit_rate:.2%}")
            print(f"✓ 参与智能体: {', '.join(result.get('agents_executed', []))}")

            # 智能体执行时间
            print("\n智能体执行时间:")
            for agent_name, timing in result.get('agent_timings', {}).items():
                print(f"  - {agent_name}: {timing:.2f}ms")

            # 错题分布
            if final_report.statistics_data.wrong_question_distribution:
                wrong_dist = final_report.statistics_data.wrong_question_distribution
                print(f"\n错题统计:")
                print(f"  - 总错题数: {wrong_dist.total_wrong_count}")
                if wrong_dist.high_frequency_errors:
                    print(f"  - 高频错误: {', '.join(wrong_dist.high_frequency_errors[:3])}")

            # 薄弱知识点
            if final_report.analysis_result.weak_points:
                print(f"\n薄弱知识点:")
                for wp in final_report.analysis_result.weak_points[:3]:
                    print(f"  - {wp.category}: {wp.error_rate:.1f}% ({wp.severity})")

            # 推荐内容
            if final_report.recommendation_result.review_contents:
                review_count = len(final_report.recommendation_result.review_contents)
                print(f"\n推荐复习内容: {review_count}项")

            if final_report.recommendation_result.next_courses:
                course_count = len(final_report.recommendation_result.next_courses)
                print(f"推荐课程: {course_count}门")

            print("\n" + "=" * 60)
            print("测试完成！系统运行正常 ✓")
            print("=" * 60)
        else:
            print("✗ 未能生成最终报告")
            if result.get('errors'):
                print(f"错误信息: {result['errors']}")

    except Exception as e:
        print(f"✗ 工作流执行失败: {e}")
        import traceback
        traceback.print_exc()

    finally:
        # 清理资源
        await cache_manager.disconnect()
        await db_manager.disconnect()


async def test_performance():
    """性能测试"""
    print("\n" + "=" * 60)
    print("性能测试")
    print("=" * 60)

    cache_manager = CacheManager()
    db_manager = DatabaseManager()
    ai_client = AIClient()

    await cache_manager.connect()
    await db_manager.connect()

    workflow = create_learning_report_workflow(
        cache_manager=cache_manager,
        db_manager=db_manager,
        ai_client=ai_client
    )

    test_user_id = 1
    period_end = datetime.now()
    period_start = period_end - timedelta(days=7)

    # 第一次执行（无缓存）
    print("\n第一次执行（无缓存）...")
    state1 = initialize_state(test_user_id, "weekly", period_start, period_end, "000000")

    start_time = time.time()
    result1 = await workflow.ainvoke(state1)
    time1 = (time.time() - start_time) * 1000

    print(f"✓ 执行时间: {time1:.2f}ms")
    print(f"✓ 缓存命中率: {result1.get('final_report').cache_hit_rate:.2%}")

    # 第二次执行（有缓存）
    print("\n第二次执行（有缓存）...")
    state2 = initialize_state(test_user_id, "weekly", period_start, period_end, "000000")

    start_time = time.time()
    result2 = await workflow.ainvoke(state2)
    time2 = (time.time() - start_time) * 1000

    print(f"✓ 执行时间: {time2:.2f}ms")
    print(f"✓ 缓存命中率: {result2.get('final_report').cache_hit_rate:.2%}")

    # 性能对比
    improvement = ((time1 - time2) / time1) * 100
    print(f"\n性能提升: {improvement:.1f}%")

    if improvement >= 30:
        print("✓ 达到性能目标（30%+ 提升）")
    else:
        print(f"⚠ 未达到性能目标，建议检查缓存配置")

    await cache_manager.disconnect()
    await db_manager.disconnect()


if __name__ == "__main__":
    # 运行功能测试
    asyncio.run(test_workflow())

    # 询问是否运行性能测试
    print("\n是否运行性能测试？(y/n): ", end="")
    if input().lower() == 'y':
        asyncio.run(test_performance())
