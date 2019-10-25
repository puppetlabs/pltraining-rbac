rbac_role { 'Viewers':
  ensure      => 'present',
  description => 'Viewers',
  permissions => [
  {
    'object_type' => 'nodes',
    'action' => 'view_data',
    'instance' => '*'
  },
  {
    'object_type' => 'console_page',
    'action' => 'view',
    'instance' => '*'
  }],
}
