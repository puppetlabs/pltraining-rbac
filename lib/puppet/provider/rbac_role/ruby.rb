require 'puppet/provider/rbac_api'

Puppet::Type.type(:rbac_role).provide(:ruby, :parent => Puppet::Provider::Rbac_api) do
  desc 'RBAC API provider for the rbac_role type'

  mk_resource_methods

  def self.instances
    Puppet::Provider::Rbac_api::get_response('/roles').collect do |role|
      Puppet.debug "RBAC: Inspecting role #{role.inspect}"
      new(:ensure       => role['is_revoked'] ? :absent : :present,
          :id           => role['id'],
          :name         => role['display_name'],
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

    [ :name, :description ].each do |prop|
      raise ArgumentError, 'description, and name are required attributes' unless resource[prop]
    end

    role = {
      'description'  => resource[:description],
      'display_name' => resource[:name],
      'permissions'  => resource[:permissions],
      'user_ids'     => normalize_users(resource[:user_ids]),
      'group_ids'    => resource[:group_ids],
    }
    Puppet::Provider::Rbac_api::post_response('/roles', role)

    @property_hash[:ensure] = :present
  end

  def destroy
    Puppet::Provider::Rbac_api::delete_response("/roles/#{@property_hash[:id]}")
    @property_hash[:ensure] = :absent
  end

  define_method "name=" do |value|
    fail "The name parameter cannot be changed after creation."
  end

  define_method "id=" do |value|
    fail "The id parameter is read-only."
  end

  def normalize_users(list)
    return list unless list.is_a? Array
    users = nil
    list.collect! do |item|
      next item if item =~ /[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}/

      # lazy load the available users. Avoid the API call unless needed
      users ||= Puppet::Provider::Rbac_api::get_response('/users')

      begin
        users.find {|r| r['display_name'].downcase == item.downcase }['id']
      rescue NoMethodError => e
        fail "User #{item} does not exist"
      end
    end
  end

  def flush
    # so, flush gets called, even on create() and delete()
    return if @property_hash[:id].nil?
    return if @property_hash[:ensure] == :absent

    role = {
      'id'           => @property_hash[:id],
      'description'  => @property_hash[:description],
      'display_name' => @property_hash[:name],
      'permissions'  => @property_hash[:permissions],
      'user_ids'     => normalize_users(@property_hash[:user_ids]),
      'group_ids'    => @property_hash[:group_ids],
    }

    Puppet.debug "RBAC: Updating role #{role.inspect}"
    Puppet::Provider::Rbac_api::put_response("/roles/#{@property_hash[:id]}", role)
  end

  def revoked?
    @property_hash[:ensure] == :absent
  end

end
