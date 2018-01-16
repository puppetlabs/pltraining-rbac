require 'spec_helper'

describe 'Ruby provider for rbac_user' do
  let(:resource) { Puppet::Type.type(:rbac_user).new(:name => 'tacocat') }
  let(:provider) { resource.provider }
  let(:instance) { provider.class.instances.first }

  subject { Puppet::Type.type(:rbac_user).provider(:ruby).new(resource) }

  before do
    Puppet::Provider::Rbac_api.expects(:get_response).with('/users').at_least_once.returns(
      [{
        'is_revoked'   => false,
        'id'           => '12345',
        'login'        => 'tacocat',
        'display_name' => 'Taco the Cat',
        'email'        => 'taco@cat.org',
        'role_ids'     => [1,2,3],
        'is_remote'    => false,
        'is_superuser' => false,
        'last_login'   => '2017-04-01 12:00:00 -0800',
      }]
    )
  end

  describe 'self.prefetch' do
    it 'exists' do
      provider.class.instances
      provider.class.prefetch({})
    end
  end

  describe 'set-once-only parameters' do
    [ :name, :display_name, :email ].each do |param|
      it "refuses the #{param} parameter" do
        expect { instance.send("#{param}=", 'test') }.to raise_error(Puppet::Error, %r{parameter cannot be changed after creation})
      end
    end
  end

  describe 'read-only parameters' do
    [ :remote, :superuser, :last_login, :id ].each do |param|
      it "refuses the #{param} parameter" do
        expect { instance.send("#{param}=", 'test') }.to raise_error(Puppet::Error, %r{parameter is read-only})
      end
    end
  end

  describe 'attempting to change password' do
    it 'ignores password changes' do
      expect { instance.password= 'test' }.not_to raise_error
    end
  end

  describe 'existance' do
    it 'checks if user exists' do
      expect(instance).to be_exists
    end

    it 'checks if user exists after revoking' do
      instance.destroy
      expect(instance).not_to be_exists
    end
  end

end
