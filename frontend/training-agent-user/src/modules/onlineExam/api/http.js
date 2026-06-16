// Simple HTTP client using fetch
// Reads base URL from VUE_APP_API_BASE, attaches Authorization header if token exists

export interface HttpOptions {
	method?: string;
	body?: any;
	headers?: Record<string, string>;
	query?: Record<string, string | number | boolean | undefined | null>;
}

function buildUrl(path: string, query?: HttpOptions['query']) {
	// Vue CLI uses process.env, not import.meta
	const base = import.meta.env?.VITE_API_BASE || '';
	const url = new URL(path, base || window.location.origin);
	if (query) {
		Object.entries(query).forEach(([k, v]) => {
			if (v !== undefined && v !== null) url.searchParams.set(k, String(v));
		});
	}
	return url.toString();
}

export async function http(path: string, options: HttpOptions = {}) {
	const token = localStorage.getItem('token');
	const headers: Record<string, string> = {
		'Content-Type': 'application/json',
		...(options.headers || {})
	};
	if (token) headers['Authorization'] = `Bearer ${token}`;

	const res = await fetch(buildUrl(path, options.query), {
		method: options.method || (options.body ? 'POST' : 'GET'),
		headers,
		body: options.body ? JSON.stringify(options.body) : undefined,
		credentials: 'include'
	});
	if (!res.ok) {
		const text = await res.text().catch(() => '');
		throw new Error(`HTTP ${res.status}: ${text || res.statusText}`);
	}
	const ct = res.headers.get('content-type') || '';
	if (ct.includes('application/json')) return res.json();
	return res.text();
}


