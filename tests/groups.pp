rbac_group { 'contractors':
  ensure => 'present',
  roles  => ['Viewers','Operators'],
}
