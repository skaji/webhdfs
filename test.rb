#!/usr/bin/env ruby
# coding: utf-8

require 'webhdfs'
require 'webhdfs/fileutils'
require 'tempfile'
require 'test/unit'

class WebHDFSTest < Test::Unit::TestCase
  def setup
    @host = ENV['host']
    @port = ENV['port']
    @user = ENV['USER']
    @ca_file = ENV['ca_file']
    @client = WebHDFS::Client.new(@host, @port)
    @client.httpfs_mode = true
    @client.ssl = true
    @client.ssl_ca_file = @ca_file if @ca_file
    @client.kerberos = true
    @client.ssl_verify_mode = :peer
  end
  def teardown
    begin
      @client.delete("/user/#{@user}/test.txt")
    rescue
    end
  end
  def test_stat
    stat = @client.stat("/user/#{@user}")
    assert_equal("DIRECTORY", stat['type'])
  end
  def test_create
    assert_equal(true, @client.create("/user/#{@user}/test.txt", "test"))
    assert_equal("test", @client.read("/user/#{@user}/test.txt"))
  end
  def test_create_io
    path = Tempfile.open("temp") {|fp|
      fp.print("io test")
      fp.path
    }
    @client.create("/user/#{@user}/test.txt", File.open(path, "r"))
    assert_equal("io test", @client.read("/user/#{@user}/test.txt"))
  end
  def test_read
    @client.create("/user/#{@user}/test.txt", "test")
    assert_equal("test", @client.read("/user/#{@user}/test.txt"))
  end
  def test_delete
    @client.create("/user/#{@user}/test.txt", "test")
    assert_equal(true, @client.delete("/user/#{@user}/test.txt"))
    assert_equal(false, @client.delete("/user/#{@user}/test.txt"))
  end
end

class WebHDFSFileUtilsTest < Test::Unit::TestCase
  def setup
    @host = ENV['host']
    @port = ENV['port']
    @user = ENV['USER']
    @ca_file = ENV['ca_file']
    WebHDFS::FileUtils.set_server(@host, @port)
    WebHDFS::FileUtils.set_ssl(true)
    WebHDFS::FileUtils.set_ssl_ca_file(@ca_file) if @ca_file
    WebHDFS::FileUtils.set_ssl_verify_mode(:peer)
    WebHDFS::FileUtils.set_kerberos(true)
    WebHDFS::FileUtils.set_httpfs_mode(true)
  end
  def teardown
    begin
      WebHDFS::FileUtils.rm("/user/#{@user}/test.txt")
    rescue
    end
  end
  def test_copy_from_local
    path = Tempfile.open("temp") {|fp|
      fp.print("test")
      fp.path
    }
    assert_equal(true, WebHDFS::FileUtils.copy_from_local(path, "/user/#{@user}/test.txt"))
  end
  def test_copy_from_local_via_stream
    path = Tempfile.open("temp") {|fp|
      fp.print("test")
      fp.path
    }
    assert_equal(true, WebHDFS::FileUtils.copy_from_local_via_stream(File.open(path, "r"), "/user/#{@user}/test.txt"))
  end
  def test_rm
    path = Tempfile.open("temp") {|fp|
      fp.print("test")
      fp.path
    }
    WebHDFS::FileUtils.copy_from_local(path, "/user/#{@user}/test.txt")

    # what to assert...
    WebHDFS::FileUtils.rm("/user/#{@user}/test.txt", {:verbose => true})
    WebHDFS::FileUtils.rm("/user/#{@user}/test.txt", {:verbose => true})
  end
end
