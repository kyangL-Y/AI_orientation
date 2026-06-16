import { api } from '@/utils/api'

// 课程相关API
export const getCourseData = () => {
  return Promise.resolve({
    data: {
      code: 200,
      data: [
        {
          courseId: 6,
          title: 'Front Desk Service Training',
          description: 'Learn standard front desk service procedures and customer service skills',
          category: '前台服务',
          duration: '120分钟',
          level: '正常',
          icon: 'fa fa-id-card-o',
          isRequired: true,
          students: 45,
          coverImage: null,
          status: 0,
          createTime: '2025-10-15T10:39:27'
        },
        {
          courseId: 7,
          title: 'Dining Service Training',
          description: 'Learn professional dining service etiquette and standards',
          category: '餐饮服务',
          duration: '150分钟',
          level: '正常',
          icon: 'fa fa-cutlery',
          isRequired: true,
          students: 38,
          coverImage: null,
          status: 0,
          createTime: '2025-10-15T10:39:27'
        },
        {
          courseId: 8,
          title: 'OTA Management Training',
          description: 'Learn OTA platform operations management skills',
          category: 'OTA运营',
          duration: '120分钟',
          level: '正常',
          icon: 'fa fa-laptop',
          isRequired: true,
          students: 52,
          coverImage: null,
          status: 0,
          createTime: '2025-10-15T10:39:27'
        },
        {
          courseId: 9,
          title: 'Room Service Training',
          description: 'Master room service procedures and standards',
          category: '客房服务',
          duration: '90分钟',
          level: '正常',
          icon: 'fa fa-bed',
          isRequired: true,
          students: 41,
          coverImage: null,
          status: 0,
          createTime: '2025-10-15T10:39:27'
        },
        {
          courseId: 10,
          title: 'Customer Service Skills',
          description: 'Improve customer communication and service skills',
          category: '客户服务',
          duration: '100分钟',
          level: '正常',
          icon: 'fa fa-users',
          isRequired: true,
          students: 67,
          coverImage: null,
          status: 0,
          createTime: '2025-10-15T10:39:27'
        },
        {
          courseId: 11,
          title: 'Hotel Management Basics',
          description: 'Learn hotel management fundamentals including staff management and cost control',
          category: '管理培训',
          duration: '180分钟',
          level: '正常',
          icon: 'fa fa-cogs',
          isRequired: false,
          students: 29,
          coverImage: null,
          status: 0,
          createTime: '2025-10-15T10:39:27'
        },
        {
          courseId: 12,
          title: 'Team Collaboration Training',
          description: 'Improve team collaboration skills and communication methods',
          category: '管理培训',
          duration: '120分钟',
          level: '正常',
          icon: 'fa fa-users',
          isRequired: false,
          students: 33,
          coverImage: null,
          status: 0,
          createTime: '2025-10-15T10:39:27'
        },
        {
          courseId: 13,
          title: 'Sales Skills Training',
          description: 'Learn hotel sales techniques including customer development and negotiation',
          category: '管理培训',
          duration: '150分钟',
          level: '正常',
          icon: 'fa fa-line-chart',
          isRequired: false,
          students: 25,
          coverImage: null,
          status: 0,
          createTime: '2025-10-15T10:39:27'
        },
        {
          courseId: 14,
          title: 'Emergency Response Training',
          description: 'Learn hotel emergency procedures and safety protocols',
          category: '安全管理',
          duration: '90分钟',
          level: '正常',
          icon: 'fa fa-shield',
          isRequired: true,
          students: 58,
          coverImage: null,
          status: 0,
          createTime: '2025-10-15T10:39:27'
        }
      ]
    }
  })
}

// 获取课程列表（用于学习计划）
export const listCourse = (params = {}) => {
  return api.get('/train/course/list', { params })
}
