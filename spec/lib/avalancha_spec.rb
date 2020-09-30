# frozen_string_literal: true

require 'spec_helper'
require 'json'
require_relative '../../lib/avalancha'

describe Avalancha do
  let(:instance) { Avalancha.build }

  it 'passes test00' do
    assert_works_with_test_file('test00')
  end

  it 'passes test01' do
    assert_works_with_test_file('test01')
  end

  it 'passes test02' do
    assert_works_with_test_file('test02')
  end

  it 'passes test03' do
    assert_works_with_test_file('test03')
  end

  it 'passes test04' do
    assert_works_with_test_file('test04')
  end

  def assert_works_with_test_file(test_name)
    expected = JSON.parse(File.read(build_path(test_name, 'expected')))

    result = instance.parse(build_path(test_name, 'input'))

    expect(result).to eq(expected)
  end

  def build_path(test_name, ext)
    "examples/#{test_name}.#{ext}"
  end
end
