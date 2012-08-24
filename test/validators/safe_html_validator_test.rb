require 'test_helper'
require 'validators/safe_html'

class SafeHtmlTest < ActiveSupport::TestCase
  class ::Dummy
    include Mongoid::Document

    field "declared", type: String

    validates_with SafeHtml

    embeds_one :dummy_embedded_single
  end

  class ::DummyEmbeddedSingle
    include Mongoid::Document

    validates_with SafeHtml

    embedded_in :dummy
  end

  context "we don't quite trust mongoid (2)" do
    should "embedded documents should be validated automatically" do
      embedded = DummyEmbeddedSingle.new(dirty: "<script>")
      dummy = Dummy.new(dummy_embedded_single: embedded)
      # Can't invoke embedded.valid? because that would run the validations
      assert dummy.invalid?
      assert_includes dummy.errors.keys, :dummy_embedded_single
    end
  end

  context "what to validate" do
    should "test declared fields" do
      dummy = Dummy.new(declared: "<script>alert('XSS')</script>")
      assert dummy.invalid?
      assert_includes dummy.errors.keys, :declared
    end

    should "test undeclared fields" do
      dummy = Dummy.new(undeclared: "<script>")
      assert dummy.invalid?
      assert_includes dummy.errors.keys, :undeclared
    end

    should "allow clean content in nested fields" do
      dummy = Dummy.new(undeclared: { "clean" => ["plain text"] })
      assert dummy.valid?
    end

    should "disallow dirty content in nested fields" do
      dummy = Dummy.new(undeclared: { "dirty" => ["<script>"] })
      assert dummy.invalid?
      assert_includes dummy.errors.keys, :undeclared
    end

    should "allow plain text" do
      dummy = Dummy.new(declared: "foo bar")
      assert dummy.valid?
    end

    should "all models should use this validator" do
      classes = ObjectSpace.each_object(::Module).select do |klass|
        klass < Mongoid::Document
      end

      classes.each do |klass|
        assert_includes klass.validators.map(&:class), SafeHtml, "#{klass} must be validated with SafeHtml"
      end
    end
  end
end