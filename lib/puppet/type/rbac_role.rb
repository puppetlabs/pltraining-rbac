Puppet::Type.newtype(:rbac_role) do
  desc "A Puppet Enterprise Console RBAC role"
  ensurable

  newparam(:name) do
    desc 'The displayed name of the role'
  end

  newproperty(:description) do
    desc 'The description of the role'
  end

  newproperty(:permissions, :array_matching =>:all) do
    desc 'Array of permission objects for the role'
  end

  newproperty(:user_ids, :array_matching =>:all) do
    desc 'Array of UUIDs of users assigned to the role'
  end

  newproperty(:group_ids, :array_matching =>:all) do
    desc 'Array of UUIDs of groups assigned to the role'
  end

  newproperty(:id) do
    desc 'The read-only ID of the role'
  end

end
