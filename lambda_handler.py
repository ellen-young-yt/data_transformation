import json
import os
import subprocess
import sys
from typing import Dict, Any

def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    AWS Lambda handler for dbt data transformation.
    
    Args:
        event: Lambda event data
        context: Lambda context object
        
    Returns:
        Dict containing execution results
    """
    
    try:
        # Set environment variables from event or environment
        env_vars = {
            'SNOWFLAKE_ACCOUNT': event.get('snowflake_account', os.environ.get('SNOWFLAKE_ACCOUNT')),
            'SNOWFLAKE_USER': event.get('snowflake_user', os.environ.get('SNOWFLAKE_USER')),
            'SNOWFLAKE_PASSWORD': event.get('snowflake_password', os.environ.get('SNOWFLAKE_PASSWORD')),
            'SNOWFLAKE_ROLE': event.get('snowflake_role', os.environ.get('SNOWFLAKE_ROLE', 'ACCOUNTADMIN')),
            'SNOWFLAKE_DATABASE': event.get('snowflake_database', os.environ.get('SNOWFLAKE_DATABASE')),
            'SNOWFLAKE_WAREHOUSE': event.get('snowflake_warehouse', os.environ.get('SNOWFLAKE_WAREHOUSE')),
            'SNOWFLAKE_SCHEMA': event.get('snowflake_schema', os.environ.get('SNOWFLAKE_SCHEMA')),
        }
        
        # Set environment variables
        for key, value in env_vars.items():
            if value:
                os.environ[key] = value
        
        # Determine target environment
        target = event.get('target', 'prod')
        
        # Determine dbt command
        command = event.get('command', 'run')
        
        # Build dbt command
        dbt_cmd = ['dbt', command, '--target', target]
        
        # Add additional flags if specified
        if event.get('full_refresh', False):
            dbt_cmd.append('--full-refresh')
        
        if event.get('select', None):
            dbt_cmd.extend(['--select', event['select']])
        
        if event.get('exclude', None):
            dbt_cmd.extend(['--exclude', event['exclude']])
        
        # Execute dbt command
        print(f"Executing: {' '.join(dbt_cmd)}")
        result = subprocess.run(
            dbt_cmd,
            capture_output=True,
            text=True,
            cwd='/var/task'
        )
        
        # Prepare response
        response = {
            'statusCode': 200 if result.returncode == 0 else 500,
            'body': {
                'command': ' '.join(dbt_cmd),
                'returncode': result.returncode,
                'stdout': result.stdout,
                'stderr': result.stderr,
                'target': target,
                'success': result.returncode == 0
            }
        }
        
        if result.returncode != 0:
            print(f"dbt command failed with return code {result.returncode}")
            print(f"STDOUT: {result.stdout}")
            print(f"STDERR: {result.stderr}")
        
        return response
        
    except Exception as e:
        print(f"Lambda execution failed: {str(e)}")
        return {
            'statusCode': 500,
            'body': {
                'error': str(e),
                'success': False
            }
        }

def run_dbt_models(target: str = 'prod', command: str = 'run') -> Dict[str, Any]:
    """
    Helper function to run dbt models.
    
    Args:
        target: dbt target environment
        command: dbt command to run
        
    Returns:
        Dict containing execution results
    """
    event = {
        'target': target,
        'command': command
    }
    return lambda_handler(event, None)

if __name__ == "__main__":
    # For local testing
    import argparse
    
    parser = argparse.ArgumentParser(description='Run dbt commands')
    parser.add_argument('--target', default='prod', help='dbt target environment')
    parser.add_argument('--command', default='run', help='dbt command to run')
    parser.add_argument('--full-refresh', action='store_true', help='full refresh')
    parser.add_argument('--select', help='select specific models')
    parser.add_argument('--exclude', help='exclude specific models')
    
    args = parser.parse_args()
    
    event = {
        'target': args.target,
        'command': args.command,
        'full_refresh': args.full_refresh,
        'select': args.select,
        'exclude': args.exclude
    }
    
    result = lambda_handler(event, None)
    print(json.dumps(result, indent=2))
