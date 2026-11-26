local Color3 = {fromRGB = function() return {} end}
local service = {
    WaitForChild = function(self, name) if name == "Modules" then return self end; return name end,
    PlayerRemoving = {Connect = function() end},
}
local game = {GetService = function() return service end}
local vector = {}
local Vector3 = {new = function(x, y, z) return setmetatable({X = x, Y = y, Z = z}, vector) end}
function vector.__add(a, b) return Vector3.new(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
function vector.__sub(a, b) return Vector3.new(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
function vector.__mul(a, scale) return Vector3.new(a.X * scale, a.Y * scale, a.Z * scale) end
function vector.__index(a, key)
    if key == "Magnitude" then return math.sqrt(a.X * a.X + a.Y * a.Y + a.Z * a.Z) end
    if key == "Dot" then return function(v, b) return v.X * b.X + v.Y * b.Y + v.Z * b.Z end end
    return nil
end
return {game = game, Color3 = Color3, Vector3 = Vector3}
