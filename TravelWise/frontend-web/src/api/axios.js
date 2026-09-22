import axios from 'axios';

const api = axios.create({
    // Check your backend terminal for the correct localhost port (usually 5000, 5001, or 7000+)
    baseURL: 'http://localhost:5200/api', 
});

// 1. Request Interceptor: Attach the token
api.interceptors.request.use((config) => {
    const token = localStorage.getItem('token');
    if (token) {
        config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
}, (error) => Promise.reject(error));

// 2. Response Interceptor: Handle expired tokens globally
api.interceptors.response.use(
    (response) => response,
    (error) => {
        if (error.response?.status === 401) {
            localStorage.removeItem('token');
            // Force redirect to login
            window.location.href = '/login';
        }
        return Promise.reject(error);
    }
);

export default api;