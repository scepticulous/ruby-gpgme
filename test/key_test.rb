# -*- encoding: utf-8 -*-
require 'test_helper'

describe GPGME::Key do

  it "has certain attributes" do
    key = GPGME::Key.find(:secret).first
    [:keylist_mode, :protocol, :owner_trust, :issuer_serial,
      :issuer_name, :chain_id, :subkeys, :uids].each do |attrib|
      assert key.respond_to?(attrib), "Key doesn't respond to #{attrib}"
    end
  end

  it "won't allow the creation of GPGME::Key's without the C API" do
    assert_raises NoMethodError do
      GPGME::Key.new
    end
  end

  describe :find do
    it "should return all by default" do
      keys = GPGME::Key.find :secret
      assert_instance_of GPGME::Key, keys.first
      assert 0 < keys.size
    end

    it "returns an array even if you pass only one descriptor" do
      keys_one   = GPGME::Key.find(:secret, KEYS.first[:sha]).map{|key| key.subkeys.map(&:keyid)}
      keys_array = GPGME::Key.find(:secret, [KEYS.first[:sha]]).map{|key| key.subkeys.map(&:keyid)}
      assert_equal keys_one, keys_array
    end

    it "returns only secret keys if told to do so" do
      keys = GPGME::Key.find :secret
      assert keys.all?(&:secret?)
    end

    it "returns only public keys if told to do so" do
      keys = GPGME::Key.find :public
      assert keys.none?(&:secret?)
    end

    it "filters by capabilities" do
      GPGME::Key.any_instance.stubs(:usable_for?).returns(false)
      keys = GPGME::Key.find :public, "", :wadusing
      assert keys.empty?
    end
  end

  describe :export do
    # Testing the lazy way with expectations. I think tests in
    # the Ctx class are enough.
    it "exports any key that matches the pattern" do
      GPGME::Ctx.any_instance.expects(:export_keys).with("", anything)
      GPGME::Key.export("")
    end

    it "exports any key that matches the pattern, can specify output" do
      data = GPGME::Data.new
      GPGME::Ctx.any_instance.expects(:export_keys).with("wadus", data)
      ret = GPGME::Key.export("wadus", :output => data)
      assert_equal data, ret
    end

    it "can specify options for Ctx" do
      GPGME::Ctx.expects(:new).with(:armor => true).yields(mock(:export_keys => true))
      GPGME::Key.export("wadus", :armor => true)
    end
  end

  describe "#export" do
    it "can export from the key instance" do
      key = GPGME::Key.find(:public).first
      GPGME::Key.expects(:export).with(key.sha, {})

      key.export
    end

    it "can export from the key instance passing variables" do
      key = GPGME::Key.find(:public).first
      GPGME::Key.expects(:export).with(key.sha, {:armor => true})

      key.export :armor => true
    end
  end

  describe :import do
    it "can import keys" do
      data = GPGME::Data.new
      GPGME::Ctx.any_instance.expects(:import_keys).with(data)
      GPGME::Ctx.any_instance.expects(:import_result).returns("wadus")

      assert_equal "wadus", GPGME::Key.import(data)
    end

    it "can specify options for Ctx" do
      GPGME::Ctx.expects(:new).with(:armor => true).yields(mock(:import_keys => true, :import_result => true))
      GPGME::Key.import("wadus", :armor => true)
    end
  end

  # describe :trust do
  #   it "returns :revoked if it is so"
  #   it "returns :expired if it is expired"
  #   it "returns :disabled if it is so"
  #   it "returns :invalid if it is so"
  #   it "returns nil otherwise"
  # end

  # describe :capability do
  #   it "returns an array of possible capabilities"
  # end

  # describe :secret? do
  #   "returns true/false depending on the instance variable"
  # end

  describe :usable_for? do
    it "checks for the capabilities of the key and returns true if it matches all" do
      key = GPGME::Key.find(:secret).first

      key.stubs(:capability).returns([:encrypt, :sign])
      assert key.usable_for?([])

      key.stubs(:capability).returns([:encrypt, :sign])
      assert key.usable_for?([:encrypt])

      key.stubs(:capability).returns([:encrypt, :sign])
      refute key.usable_for?([:certify])
    end

    it "returns false if the key is expired or revoked or disabled or disabled" do
      key = GPGME::Key.find(:secret).first
      key.stubs(:trust).returns(:revoked)
      key.stubs(:capability).returns([:encrypt, :sign])
      refute key.usable_for?([:encrypt])
    end
  end

end
