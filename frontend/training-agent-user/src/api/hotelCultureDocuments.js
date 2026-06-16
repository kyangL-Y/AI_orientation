import { api } from '@/utils/api'

const BASE_URL = '/train/hotel-culture/documents'

export const getHotelCultureDocumentAccess = () => api.get(`${BASE_URL}/access`)

export const getHotelCultureDocuments = () => api.get(`${BASE_URL}/visible`)

export const getHotelCultureDocumentBlob = (documentId) => api.get(
  `${BASE_URL}/${encodeURIComponent(documentId)}/download`,
  { responseType: 'blob' }
)
