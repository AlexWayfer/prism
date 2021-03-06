require "../src/prism"

RESPONSE = HTTP::Server::Response.new(IO::Memory.new)

static_path_request = HTTP::Server::Context.new(HTTP::Request.new("GET", "/bar"), RESPONSE)

# Paths are likely to never repeat
def random_path_request
  HTTP::Server::Context.new(HTTP::Request.new("GET", "/foo/#{rand}"), RESPONSE)
end

DYNAMIC_ROUTES_NUMBER = 10_000

# One of known paths
def dynamic_path_request
  HTTP::Server::Context.new(HTTP::Request.new("GET", "/foo/#{rand(DYNAMIC_ROUTES_NUMBER)}"), RESPONSE)
end

simple_cacher = Prism::Router::SimpleCacher.new(100_000)

simply_cached_router = Prism::Router.new(simple_cacher) do
  get "/foo/:number" do |env|
  end

  get "/bar" do |env|
  end
end

non_cached_router = Prism::Router.new do
  get "/foo/:number" do |env|
  end

  get "/bar" do |env|
  end
end

require "benchmark"

puts "\nBegin benchmarking router..."
puts "Running static paths...\n\n"

Benchmark.ips do |x|
  x.report("simply cached router with static path") do
    simply_cached_router.call(static_path_request)
  end

  x.report("non-cached router with static path") do
    non_cached_router.call(static_path_request)
  end
end

puts "\nRunning dynamic paths (random from #{DYNAMIC_ROUTES_NUMBER} known paths)...\n\n"

Benchmark.ips do |x|
  x.report("simply cached router with dynamic paths") do
    simply_cached_router.call(dynamic_path_request)
  end

  x.report("non-cached router with dynamic paths") do
    non_cached_router.call(dynamic_path_request)
  end
end

puts "\nRunning absolutely random paths (caching is useless)...\n\n"

Benchmark.ips do |x|
  x.report("simply cached router with random paths") do
    simply_cached_router.call(random_path_request)
  end

  x.report("non-cached router with random paths") do
    non_cached_router.call(random_path_request)
  end
end

puts "\n✔️ Done benchmarking router"
