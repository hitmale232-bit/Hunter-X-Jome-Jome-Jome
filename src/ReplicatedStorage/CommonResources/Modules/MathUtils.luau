local MathUtils = {}

function MathUtils:GetDotProduct(a, b, d)
	local unit = (a - b).Unit
	return unit:Dot(d)
end

function MathUtils:Lerp(a, b, t)
	return a + (b - a) * t
end

function MathUtils:LerpWithOvershoot(a, b, s)
	-- Takes two vectors and let's you offset in studs
	local d = (a - b).Magnitude
	return a:Lerp(b, (d - s) / d) -- nerdface
end

function MathUtils:LerpColor3(a, b, t)
	return Color3.new(
		MathUtils:Lerp(a.R, b.R, t),
		MathUtils:Lerp(a.G, b.G, t),
		MathUtils:Lerp(a.B, b.B, t)
	)
end

function MathUtils:QuadBezier(a, b, c, t)
	local x1 = MathUtils:Lerp(a, b, t)
	local x2 = MathUtils:Lerp(b, c, t)
	return MathUtils:Lerp(x1, x2, t)
end

function MathUtils:BezierVector(a, b, c, t)
	return Vector3.new(
		MathUtils:QuadBezier(a.X, b.X, c.X, t),
		MathUtils:QuadBezier(a.Y, b.Y, c.Y, t),
		MathUtils:QuadBezier(a.Z, b.Z, c.Z, t)
	)
end

return MathUtils
