require 'puppet/provider/rbac_api'

Puppet::Type.type(:rbac_group).provide(:ruby, :parent => Puppet::Provider::Rbac_api) do
  desc 'RBAC API provider for the rbac_group type'

  mk_resource_methods

  def self.instances
    Puppet::Provider::Rbac_api::get_response('/groups').collect do |group|
      Puppet.debug "RBAC: Inspecting group #{group.inspect}"
      new(:ensure   => group['is_revoked'] ? :absent : :present,
          :id       => group['id'],
          :name     => group['login'],
          :role_ids => group['role_ids'],
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
    Puppet.debug "RBAC: Creating new group #{resource[:name]}"

    [ :name ].each do |prop|
      raise ArgumentError, 'name is required attribute' unless resource[prop]
    end

    group = {
      'login'    => resource[:name],
      'role_ids' => resource[:role_ids],
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

    group = {
      'id'       => @property_hash[:id],
      'login'    => @property_hash[:name],
      'role_ids' => @property_hash[:role_ids],
    }

    Puppet.debug "RBAC: Updating group #{group.inspect}"
    Puppet::Provider::Rbac_api::put_response("/groups/#{@property_hash[:id]}", group)
  end

  def revoked?
    @property_hash[:ensure] == :absent
  end

end
