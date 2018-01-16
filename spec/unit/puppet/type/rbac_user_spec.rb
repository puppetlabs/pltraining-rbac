require 'spec_helper'

describe Puppet::Type.type(:rbac_user) do
  subject { Puppet::Type.type(:rbac_user).new(:name => 'tacocat') }

  it 'should accept ensure' do
    subject[:ensure] = :present
    expect(subject[:ensure]).to eq :present
  end

  it 'should normalize roles to integers' do
    subject[:roles] = [1, '2', 3]
    expect(subject[:roles]).to eq [1,2,3]
  end

  it 'should require an email address' do
    expect {
      Puppet::Type.type(:rbac_user).new(:name => 'tacocat', :email => 'not-an-email')
    }.to raise_error(Puppet::Error, /Parameter email failed/)
  end

end
