require 'spec_helper'
describe 'sqlserver' do

  context 'with defaults for all parameters' do
    it { should contain_class('sqlserver') }
  end
end
