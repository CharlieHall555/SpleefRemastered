local VectorUtil = {}

function VectorUtil.DeserializeVector3(posString : string) : Vector3
    local x, y, z = posString:match("%(([-%d%.]+),%s*([-%d%.]+),%s*([-%d%.]+)%)")
    if not x or not y or not z then
        error("Invalid Vector3 format: "..tostring(posString))
    end
    return Vector3.new(tonumber(x), tonumber(y), tonumber(z))
end

function VectorUtil.SerializeVector3(vec : Vector3) : string
    return "("
        .. tostring(vec.X) .. ","
        .. tostring(vec.Y) .. ","
        .. tostring(vec.Z)
        .. ")"
end

function VectorUtil.randomVector(min: number, max: number): Vector3
	return Vector3.new(
		math.random() * (max - min) + min,
		math.random() * (max - min) + min,
		math.random() * (max - min) + min
	)
end

return VectorUtil