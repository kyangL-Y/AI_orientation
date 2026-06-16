export default {
	name: 'onlineExam',
	title: '在线考试',
	icon: 'fas fa-edit',
	route: {
		path: '/online-exam',
		component: () => import('./views/OnlineExamContainer.vue')
	}
};
