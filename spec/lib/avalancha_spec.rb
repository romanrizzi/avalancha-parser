# frozen_string_literal: true

require 'spec_helper'
require 'json'
require_relative '../../lib/avalancha'

describe Avalancha do
  let(:instance) { Avalancha.build }

  it { assert_works_with_test_file('test00') }
  it { assert_works_with_test_file('test01') }

  def assert_works_with_test_file(test_name)
    expected = JSON.parse(File.read(build_path(test_name, 'expected')))

    result = instance.parse(build_path(test_name, 'input'))

    expect(result).to eq(expected)
  end

  def build_path(test_name, ext)
    "examples/#{test_name}.#{ext}"
  end
end
