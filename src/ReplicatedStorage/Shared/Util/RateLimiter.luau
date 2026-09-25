--!strict
--[[
	RateLimiter
	Token bucket keyed by any value (usually a Player). Each key refills `ratePerSecond` tokens
	up to `burst`. Used to cap how often a client may fire a given remote.
]]

export type RateLimiter = {
	Allow: (self: RateLimiter, key: any, cost: number?) -> boolean,
	Remove: (self: RateLimiter, key: any) -> (),
}

type Bucket = {
	Tokens: number,
	Updated: number,
}

type RateLimiterImpl = {
	_rate: number,
	_burst: number,
	_buckets: { [any]: Bucket },
}

local RateLimiterMethods = {}
RateLimiterMethods.__index = RateLimiterMethods

function RateLimiterMethods.Allow(self: RateLimiterImpl, key: any, cost: number?): boolean
	local price = cost or 1
	local now = os.clock()
	local bucket = self._buckets[key]
	if not bucket then
		bucket = { Tokens = self._burst, Updated = now }
		self._buckets[key] = bucket
	end
	bucket.Tokens = math.min(self._burst, bucket.Tokens + (now - bucket.Updated) * self._rate)
	bucket.Updated = now
	if bucket.Tokens < price then
		return false
	end
	bucket.Tokens -= price
	return true
end

function RateLimiterMethods.Remove(self: RateLimiterImpl, key: any)
	self._buckets[key] = nil
end

local RateLimiter = {}

function RateLimiter.new(ratePerSecond: number, burst: number): RateLimiter
	local self: RateLimiterImpl = {
		_rate = ratePerSecond,
		_burst = burst,
		_buckets = {},
	}
	return setmetatable(self, RateLimiterMethods) :: any
end

return RateLimiter
