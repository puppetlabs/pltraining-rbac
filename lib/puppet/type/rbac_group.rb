Puppet::Type.newtype(:rbac_group) do
  desc "A Puppet Enterprise Console RBAC group"
  ensurable

  newparam(:name, :namevar => true) do
    desc 'The name of the group'
  end

  newproperty(:role_ids, :array_matching =>:all) do
    desc 'Array of role ids for the group'

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

  newproperty(:id) do
    desc 'The read-only ID of the group'
  end

end
