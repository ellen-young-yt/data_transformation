-- Simple test model to verify connection without external dependencies
select
  'DBT_USER' as username
  , 'DBT_ROLE' as role_name
  , 'STAGING' as database_name
  , 'YOUTUBE' as schema_name
  , 'Connection successful!' as status
  , current_timestamp() as test_timestamp
