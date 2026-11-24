bit32 = {}

local N = 32
local P = 2 ^ N

function bit32.bnot(x)
    x = x % P
    return P - 1 - x
end

function bit32.band(x, y)
    -- Common usecases, they deserve to be optimized
    if y == 0xff then
        return x % 0x100
    end
    if y == 0xffff then
        return x % 0x10000
    end
    if y == 0xffffffff then
        return x % 0x100000000
    end

    x, y = x % P, y % P
    local r = 0
    local p = 1
    for i = 1, N do
        local a, b = x % 2, y % 2
        x, y = math.floor(x / 2), math.floor(y / 2)
        if a + b == 2 then
            r = r + p
        end
        p = 2 * p
    end
    return r
end

function bit32.bor(x, y)
    -- Common usecases, they deserve to be optimized
    if y == 0xff then
        return x - (x % 0x100) + 0xff
    end
    if y == 0xffff then
        return x - (x % 0x10000) + 0xffff
    end
    if y == 0xffffffff then
        return 0xffffffff
    end

    x, y = x % P, y % P
    local r = 0
    local p = 1
    for i = 1, N do
        local a, b = x % 2, y % 2
        x, y = math.floor(x / 2), math.floor(y / 2)
        if a + b >= 1 then
            r = r + p
        end
        p = 2 * p
    end
    return r
end

function bit32.bxor(x, y)
    local result = 0
    local bitshift = 1

    while x > 0 or y > 0 do
        local a = x % 2
        local b = y % 2

        if (a + b) % 2 == 1 then
            result = result + bitshift
        end

        bitshift = bitshift * 2
        x = math.floor(x / 2)
        y = math.floor(y / 2)
    end

    return result
end

function bit32.lshift(x, s_amount)
    if math.abs(s_amount) >= N then
        return 0
    end
    x = x % P
    if s_amount < 0 then
        return math.floor(x * (2 ^ s_amount))
    else
        return (x * (2 ^ s_amount)) % P
    end
end

function bit32.rshift(x, s_amount)
    if math.abs(s_amount) >= N then
        return 0
    end
    x = x % P
    if s_amount > 0 then
        return math.floor(x * (2 ^ -s_amount))
    else
        return (x * (2 ^ -s_amount)) % P
    end
end

function bit32.arshift(x, s_amount)
    if math.abs(s_amount) >= N then
        return 0
    end
    x = x % P
    if s_amount > 0 then
        local add = 0
        if x >= P / 2 then
            add = P - 2 ^ (N - s_amount)
        end
        return math.floor(x * (2 ^ -s_amount)) + add
    else
        return (x * (2 ^ -s_amount)) % P
    end
end

function bit32.encrypt(key, plaintext)
    if #key ~= 32 then
        err("密钥长度必须为32位")
        return "-"
    end

    local ptlen = #plaintext
    if ptlen < 1 or ptlen > 63 then
        err("明文长度必须在1到63位之间")
    end

    local encrypted = ""
    for i = 1, ptlen do
        local byte = string.byte(plaintext, i)
        if byte >= 48 and byte <= 57 then
            byte = byte + 4 -- 数字 0-9
        elseif byte >= 65 and byte <= 90 then
            byte = byte - 65 -- 大写字母 A-Z
        elseif byte >= 97 and byte <= 122 then
            byte = byte - 71 -- 小写字母 a-z
        else
            err("密文长度必须在1到63位之间")
            return "-"
        end

        local keyidx = ((i - 1) % 32) + 1
        byte = math.fmod(byte + string.byte(key, keyidx), 62)

        if byte < 0 then
            byte = byte + 62
        end
        -- 将加密后的字节转换为数字或大小写字母
        if byte >= 0 and byte <= 25 then
            encrypted = encrypted .. string.char(byte + 65) -- 大写字母 A-Z
        elseif byte >= 26 and byte <= 51 then
            encrypted = encrypted .. string.char(byte + 71) -- 小写字母 a-z
        else
            encrypted = encrypted .. string.char(byte - 4) -- 数字 0-9
        end
    end
    return encrypted
end

function bit32.decrypt(key, ciphertext)
    if #key ~= 32 then
        return "-"
    end

    local ctlen = #ciphertext
    if ctlen < 1 or ctlen > 63 then
        err("密文长度必须在1到63位之间")
        return "-"
    end

    local decrypted = ""
    for i = 1, ctlen do
        local byte = string.byte(ciphertext, i)
        -- 将数字或大小写字母转换为原始字节
        if byte >= 48 and byte <= 57 then
            byte = byte + 4 -- 数字 0-9
        elseif byte >= 65 and byte <= 90 then
            byte = byte - 65 -- 大写字母 A-Z
        elseif byte >= 97 and byte <= 122 then
            byte = byte - 71 -- 小写字母 a-z
        else
            err("密文包含非法字符：" .. ciphertext)
            return "-"
        end
        local keyidx = ((i - 1) % 32) + 1
        byte = math.fmod(byte - string.byte(key, keyidx), 62)
        if byte < 0 then
            byte = byte + 62
        end
        if byte >= 0 and byte <= 25 then
            byte = byte + 65 -- 大写字母 A-Z
        elseif byte >= 26 and byte <= 51 then
            byte = (byte + 71) -- 小写字母 a-z
        else
            byte = (byte - 4) -- 数字 0-9
        end
        decrypted = decrypted .. string.char(byte)
    end
    return decrypted
end
