require 'spec_helper'

describe Puppet::Type.type(:rbac_role) do
  subject { Puppet::Type.type(:rbac_role).new(:name => 'tacocat') }

  # not really a lot we can test here
  it 'should accept ensure' do
    subject[:ensure] = :present
    expect(subject[:ensure]).to eq :present
  end

end
