import axiosInstance from './axiosInstance'

export function approveItinerary(id) { return axiosInstance.post(`/Approvals/${id}/approve`) }
export function rejectItinerary(id) { return axiosInstance.post(`/Approvals/${id}/reject`) }
