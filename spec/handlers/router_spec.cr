require "../spec_helper"
require "../../src/prism/handlers/router"
require "../../src/prism/handlers/router/cachers/simple"

class Prism::Handlers::Router
  module Specs
    router = Prism::Handlers::Router.new do |r|
      r.get "/users/:id" do |env|
        env.response.print("id = #{env.request.path_params.not_nil!["id"]}")
      end

      r.post "/foo" do |env|
        env.response.print("foo")
      end

      r.ws "/foo/:bar" do |socket, env|
        socket.send "Hello!"
      end

      r.on "/baz", methods: %w(put options) do |env|
        env.response.print("#{env.request.method} /baz")
      end
    end

    describe Prism::Handlers::Router do
      context "get /users/42" do
        context = dummy_context(Req.new("GET", "/users/42"))
        router.call(context)

        it "updates request action" do
          context.request.action.should be_a(::Proc(HTTP::Server::Context, Nil))
        end

        it "updates path params" do
          context.request.path_params.should eq({"id" => "42"})
        end
      end

      context "post /foo" do
        context = dummy_context(Req.new("POST", "/foo"))
        router.call(context)

        it "updates request action" do
          context.request.action.should be_a(::Proc(HTTP::Server::Context, Nil))
        end

        it "sets empty path params" do
          context.request.path_params.not_nil!.empty?.should be_true
        end
      end

      context "ws /foo/baz" do
        context = dummy_context(Req.new("GET", "/foo/baz", headers: HTTP::Headers{
          "Upgrade" => "websocket",
        }))
        router.call(context)

        it "updates request action" do
          context.request.action.should be_a(HTTP::WebSocketHandler)
        end

        it "sets path params" do
          context.request.path_params.should eq({"bar" => "baz"})
        end
      end

      context "put/options /baz" do
        context = dummy_context(Req.new("PUT", "/baz"))
        router.call(context)

        it "updates request action" do
          context.request.action.should be_a(::Proc(HTTP::Server::Context, Nil))
        end
      end

      context "get /unknown" do
        context = dummy_context(Req.new("GET", "/unknown"))
        router.call(context)

        it "doesn't update request action" do
          context.request.action.should be_nil
        end

        it "doesn't update path params" do
          context.request.path_params.should be_nil
        end
      end

      context "with Simple cacher" do
        cacher = Prism::Handlers::Router::Cachers::Simple.new(10_000)

        router = Prism::Handlers::Router.new(cacher) do |r|
          r.get "/" do |env|
            env.response.print("Hello!")
          end
        end

        context = dummy_context(Req.new("GET", "/"))

        it "works" do
          router.call(context)
        end
      end
    end
  end
end
