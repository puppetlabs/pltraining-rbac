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

    def insync?(is)
      # The current value may be nil and we don't
      # want to call sort on it so make sure we have arrays
      if is.is_a?(Array) and @should.is_a?(Array)
        # if all the elements are hashes then we can compare them using this
        # nice method. If  not we are going to have to rely on ==
        if (is + @should).all? { |x| x.is_a?(Hash) }
          diff = (is - @should) + (@should - is)
          diff.empty?
        else
          is.sort == @should.sort
        end
      else
        is == @should
      end
    end
  end

  newproperty(:user_ids, :array_matching =>:all) do
    desc 'Array of UUIDs of users (or names) assigned to the role'

    def insync?(is)
      # The current value may be nil and we don't
      # want to call sort on it so make sure we have arrays
      if is.is_a?(Array) and @should.is_a?(Array)
        is.sort == provider.normalize_users(@should).sort
      else
        is == @should
      end
    end
  end

  newproperty(:group_ids, :array_matching =>:all) do
    desc 'Array of UUIDs of groups assigned to the role'

    def insync?(is)
      # The current value may be nil and we don't
      # want to call sort on it so make sure we have arrays
      if is.is_a?(Array) and @should.is_a?(Array)
        is.sort == @should.sort
      else
        is == @should
      end
    end
  end

  newproperty(:id) do
    desc 'The read-only ID of the role'
  end

end
