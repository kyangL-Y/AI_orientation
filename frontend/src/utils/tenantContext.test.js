import { beforeAll, beforeEach, describe, expect, it, vi } from 'vitest'
import {
  clearTenantContext,
  extractTenantId,
  getStoredTenantCustomization,
  getTenantId,
  mergeTenantCustomization,
  setTenantCustomization,
  syncTenantContextFromUser
} from '@/utils/tenantContext'

describe('tenantContext', () => {
  beforeAll(() => {
    const storage = (() => {
      const store = new Map()
      return {
        getItem: (key) => (store.has(key) ? store.get(key) : null),
        setItem: (key, value) => {
          store.set(key, String(value))
        },
        removeItem: (key) => {
          store.delete(key)
        },
        clear: () => {
          store.clear()
        }
      }
    })()

    const documentMock = {
      cookie: ''
    }

    vi.stubGlobal('localStorage', storage)
    vi.stubGlobal('document', documentMock)
  })

  beforeEach(() => {
    localStorage.clear()
    document.cookie = 'Tenant-Id=; expires=Thu, 01 Jan 1970 00:00:00 GMT; path=/'
  })

  it('extracts tenant id from user info', () => {
    expect(extractTenantId({ tenantId: 'T100' })).toBe('T100')
    expect(extractTenantId({ tenant_id: 'T200' })).toBe('T200')
  })

  it('syncs tenant id from user info into shared storage', () => {
    syncTenantContextFromUser({ tenantId: 'T300' })

    expect(getTenantId()).toBe('T300')
    expect(localStorage.getItem('tenant_id')).toBe('T300')
    expect(localStorage.getItem('tenantId')).toBe('T300')
  })

  it('merges same-tenant customization without dropping existing logo', () => {
    setTenantCustomization({
      tenantId: 'T400',
      logoUrl: 'https://example.com/logo.png',
      companyName: '示例集团'
    }, { merge: false })

    const merged = mergeTenantCustomization(getStoredTenantCustomization(), {
      tenantId: 'T400',
      companyName: '示例集团升级版'
    })

    expect(merged.logoUrl).toBe('https://example.com/logo.png')
    expect(merged.companyName).toBe('示例集团升级版')
  })

  it('does not leak previous tenant branding into another tenant', () => {
    setTenantCustomization({
      tenantId: 'T500',
      logoUrl: 'https://example.com/t500.png',
      companyName: '集团 A'
    }, { merge: false })

    const merged = mergeTenantCustomization(getStoredTenantCustomization(), {
      tenantId: 'T600',
      companyName: '集团 B'
    })

    expect(merged.tenantId).toBe('T600')
    expect(merged.logoUrl).toBeUndefined()
    expect(merged.companyName).toBe('集团 B')
  })

  it('clears tenant context cleanly', () => {
    syncTenantContextFromUser({ tenantId: 'T700' })
    setTenantCustomization({ tenantId: 'T700', companyName: '集团 C' }, { merge: false })

    clearTenantContext()

    expect(getTenantId()).toBe('')
    expect(getStoredTenantCustomization()).toBeNull()
    expect(localStorage.getItem('tenant_id')).toBeNull()
    expect(localStorage.getItem('tenantId')).toBeNull()
  })
})
