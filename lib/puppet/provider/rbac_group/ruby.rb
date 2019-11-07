require 'puppet/provider/rbac_api'

Puppet::Type.type(:rbac_group).provide(:ruby, :parent => Puppet::Provider::Rbac_api) do
  desc 'RBAC API provider for the rbac_group type'

  mk_resource_methods

  def self.instances
    $roles = roles
    Puppet::Provider::Rbac_api::get_response('/groups').collect do |group|
      # Turn role ids into role names
      role_names = group['role_ids'].map { |id| $roles[id] }
      Puppet.debug "RBAC: Inspecting group #{group.inspect}"
      new(:ensure => group['is_revoked'] ? :absent : :present,
          :id     => group['id'],
          :name   => group['login'],
          :roles  => role_names,
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

  def self.roles
    roles = {}
    Puppet::Provider::Rbac_api::get_response('/roles').collect do |role|
      roles[role['id']] = role['display_name']
    end
    roles
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    Puppet.debug "RBAC: Creating new group #{resource[:name]}"

    [ :name ].each do |prop|
      raise ArgumentError, 'name is required attribute' unless resource[prop]
    end

    # Transform role names into role ids
    role_ids = resource['roles'].map { |name| $roles.key(name) }

    group = {
      'login'    => resource[:name],
      'role_ids' => role_ids,
    }
    Puppet::Provider::Rbac_api::post_response('/groups', group)

    @property_hash[:ensure] = :present
  end

  def destroy
    Puppet::Provider::Rbac_api::delete_response("/groups/#{@property_hash[:id]}")
    @property_hash[:ensure] = :absent
  end

  define_method "name=" do |value|
    fail "The name parameter cannot be changed after creation."
  end

  define_method "id=" do |value|
    fail "The id parameter is read-only."
  end

  def flush
    # so, flush gets called, even on create() and delete()
    return if @property_hash[:id].nil?
    return if @property_hash[:ensure] == :absent

    # Turn role names into ids
    role_ids = @property_hash[:roles].map { |name| $roles.key(name) }

    # Fun fact, only role_ids is updatable
    group = {
      'id'           => @property_hash[:id],
      'login'        => @property_hash[:name],
      'display_name' => @property_hash[:name],
      'is_group'     => true,
      'is_remote'    => true,
      'is_superuser' => false,
      'user_ids'     => [],
      'role_ids'     => role_ids,
    }

    Puppet.debug "RBAC: Updating group #{group.inspect}"
    Puppet::Provider::Rbac_api::put_response("/groups/#{@property_hash[:id]}", group)
  end

  def revoked?
    @property_hash[:ensure] == :absent
  end

end
