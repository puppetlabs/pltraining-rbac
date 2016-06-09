require 'puppet/provider/rbac_api'

Puppet::Type.type(:rbac_role).provide(:ruby, :parent => Puppet::Provider::Rbac_api) do
  desc 'RBAC API provider for the rbac_role type'

  mk_resource_methods

  def self.instances
    Puppet::Provider::Rbac_api::get_response('/roles').collect do |role|
      Puppet.debug "RBAC: Inspecting role #{role.inspect}"
      new(:ensure       => role['is_revoked'] ? :absent : :present,
          :id           => role['id'],
          :display_name => role['display_name'],
          :description  => role['description'],
          :permissions  => role['permissions'],
          :user_ids     => role['user_ids'],
          :group_ids    => role['group_ids'],
      )
    end
  end

  def self.prefetch(resources)
    vars = instances
    resources.each do |name, res|
      if provider = vars.find{ |v| v.name == res.name }
        res.provider = provider
      end
    end
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    Puppet.debug "RBAC: Creating new role #{resource[:name]}"

    [ :display_name, :description ].each do |prop|
      raise ArgumentError, 'description, and display_name are required attributes' unless resource[prop]
    end

    role = {
      'description'  => resource[:description],
      'display_name' => resource[:display_name],
    }
    Puppet::Provider::Rbac_api::post_response('/roles', role)

    @property_hash[:ensure] = :present
  end

  def destroy
    @property_hash[:ensure] = :absent
  end

  define_method "display_name=" do |value|
    fail "The display_name parameter cannot be changed after creation."
  end

  define_method "id=" do |value|
    fail "The id parameter is read-only."
  end

  def flush
    # so, flush gets called, even on create()
    return if @property_hash[:id].nil?

    role = {
      'id'           => @property_hash[:id],
      'description'  => @property_hash[:description],
      'display_name' => @property_hash[:display_name],
      'permissions'  => @property_hash[:permissions],
      'user_ids'     => @property_hash[:user_ids],
      'group_ids'    => @property_hash[:group_ids],
    }

    Puppet.debug "RBAC: Updating role #{role.inspect}"
    Puppet::Provider::Rbac_api::put_response("/roles/#{@property_hash[:id]}", role)
  end

  def revoked?
    @property_hash[:ensure] == :absent
  end

end
