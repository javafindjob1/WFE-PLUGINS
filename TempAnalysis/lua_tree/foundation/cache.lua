---@class cache
hcache = {_c_ = {}, _p_ = {}, _dh_ = {}}

---@param handle any
---@param key any
---@return boolean
function hcache.exist(handle, key)
    if (handle == nil) then
        return false
    end
    if (hcache._c_[handle] == nil) then
        return false
    end
    if (key ~= nil and hcache._c_[handle][key] == nil) then
        return false
    end
    return true
end

---@param handle any
---@return void
function hcache.alloc(handle)
    if (handle == nil) then
        stack()
        return
    end
    if (hcache._c_[handle] == nil) then
        hcache._c_[handle] = {}
    end
end

---@param handle any
---@return void
function hcache.protect(handle)
    if (hcache._p_[handle] == nil) then
        hcache._p_[handle] = true
    end
end

---@protected
---@param handle any
---@return boolean
function hcache.protected(handle)
    return hcache._p_[handle] ~= nil
end

---@param handle any
---@param key any
---@return void
function hcache.free(handle, key)
    if (handle == nil) then
        return
    end
    if (hcache._c_[handle] ~= nil) then
        if (key ~= nil) then
            hcache._c_[handle][key] = nil
        elseif (hcache.protected(handle) ~= true) then
            hcache._c_[handle] = nil
        end
    end
end

---@param handle any
---@param key any
---@param value any|nil
---@return void
function hcache.set(handle, key, value)
    if (handle == nil) then
        return
    end
    if (hcache._c_[handle] ~= nil) then
        hcache._c_[handle][key] = value
    end
end

---@param handle any
---@param key any
---@param default any|nil
---@return any
function hcache.get(handle, key, default)
    if (handle == nil) then
        return
    end
    if (hcache._c_[handle] == nil) then
        return default
    end
    return hcache._c_[handle][key] or default
end

---@param handleA any
---@param handleB any
---@param key string
---@return any
function hcache.get_dh_data(handleA, handleB, key)
    if
        key == nil or handleA == nil or handleB == nil or hcache._dh_[handleA] == nil or
            hcache._dh_[handleA][handleB] == nil or
            hcache._dh_[handleA][handleB][key] == nil
     then
        return nil
    end
    return hcache._dh_[handleA][handleB][key]
end

---@param handleA any
---@param handleB any
---@param key string
---@param data any
---@return void
function hcache.set_dh_data(handleA, handleB, key, data)
    if handleA == nil or handleB == nil or key == nil then
        return
    end
    if hcache._dh_[handleA] == nil then
        hcache._dh_[handleA] = {}
    end
    if hcache._dh_[handleA][handleB] == nil then
        hcache._dh_[handleA][handleB] = {}
    end
    hcache._dh_[handleA][handleB][key] = data
end

---@param handleA any
---@param handleB any
---@param key string
---@return void
function hcache.free_dh_data(handleA, handleB, key)
    if handleA == nil or handleB == nil or key == nil then
        return
    end
    if hcache._dh_[handleA] ~= nil and hcache._dh_[handleA][handleB] ~= nil then
        hcache._dh_[handleA][handleB][key] = nil
        if #hcache._dh_[handleA][handleB] == 0 then
            hcache._dh_[handleA][handleB] = nil
            if #hcache._dh_[handleA] == 0 then
                hcache._dh_[handleA] = nil
            end
        end
    end
end
