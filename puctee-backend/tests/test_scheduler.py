"""
Test script for EventBridge Scheduler integration

This script helps verify that the EventBridge Scheduler is properly configured
to call the Railway backend endpoint.

Usage:
    python test_scheduler.py
"""
import asyncio
import sys
from datetime import datetime, timezone, timedelta

# Add parent directory to path
sys.path.insert(0, '/Users/kj/Documents/code/puctee-mono/puctee-backend')

from app.services.scheduler.eventbridge_scheduler import eventbridge_scheduler
from app.core.config import settings


async def test_lambda_function():
    """Test Lambda function setup"""
    print("=" * 60)
    print("Testing Lambda Function Setup")
    print("=" * 60)
    
    print(f"\n📍 Railway Endpoint: {settings.railway_app_url}/api/scheduler/silent-notification")
    print(f"🔑 API Key Configured: {'Yes' if settings.SCHEDULER_API_KEY else 'No'}")
    print(f"🌍 AWS Region: {settings.AWS_REGION}")
    print(f"🔧 Lambda Function: puctee-scheduler-trigger")
    
    try:
        import boto3
        lambda_client = boto3.client('lambda', region_name=settings.AWS_REGION)
        
        print("\n🔄 Checking Lambda function...")
        response = lambda_client.get_function(FunctionName='puctee-scheduler-trigger')
        print(f"✅ Lambda Function ARN: {response['Configuration']['FunctionArn']}")
        print(f"✅ Runtime: {response['Configuration']['Runtime']}")
        print(f"✅ Last Modified: {response['Configuration']['LastModified']}")
        return True
    except lambda_client.exceptions.ResourceNotFoundException:
        print(f"❌ Lambda function not found. Please deploy it first:")
        print(f"   cd lambda && ./deploy.sh")
        return False
    except Exception as e:
        print(f"❌ Failed to verify Lambda function: {e}")
        return False


async def test_schedule_creation():
    """Test schedule creation for a dummy plan"""
    print("\n" + "=" * 60)
    print("Testing Schedule Creation")
    print("=" * 60)
    
    test_plan_id = 99999  # Dummy plan ID for testing
    test_time = datetime.now(timezone.utc) + timedelta(minutes=2)
    
    print(f"\n📅 Test Plan ID: {test_plan_id}")
    print(f"⏰ Scheduled Time: {test_time.isoformat()}")
    
    try:
        print("\n🔄 Creating test schedule...")
        success = await eventbridge_scheduler.schedule_silent_notification(
            plan_id=test_plan_id,
            when_utc=test_time
        )
        
        if success:
            print(f"✅ Schedule created successfully!")
            print(f"\n⚠️  This will trigger in ~2 minutes. Monitor Railway logs:")
            print(f"   railway logs --follow")
            print(f"\n🧹 To clean up, run:")
            print(f"   python test_scheduler.py cleanup")
            return True
        else:
            print(f"❌ Failed to create schedule")
            return False
            
    except Exception as e:
        print(f"❌ Error creating schedule: {e}")
        import traceback
        traceback.print_exc()
        return False


async def test_schedule_cancellation():
    """Test schedule cancellation"""
    print("\n" + "=" * 60)
    print("Testing Schedule Cancellation")
    print("=" * 60)
    
    test_plan_id = 99999
    
    print(f"\n📅 Test Plan ID: {test_plan_id}")
    
    try:
        print("\n🔄 Cancelling test schedule...")
        success = await eventbridge_scheduler.cancel_silent_notification(test_plan_id)
        
        if success:
            print(f"✅ Schedule cancelled successfully!")
            return True
        else:
            print(f"❌ Failed to cancel schedule")
            return False
            
    except Exception as e:
        print(f"❌ Error cancelling schedule: {e}")
        return False


async def verify_configuration():
    """Verify all required configuration"""
    print("\n" + "=" * 60)
    print("Configuration Verification")
    print("=" * 60)
    
    checks = []
    
    # Check Railway domain
    if settings.RAILWAY_PUBLIC_DOMAIN:
        print(f"✅ RAILWAY_PUBLIC_DOMAIN: {settings.RAILWAY_PUBLIC_DOMAIN}")
        checks.append(True)
    else:
        print(f"❌ RAILWAY_PUBLIC_DOMAIN: Not configured")
        checks.append(False)
    
    # Check API key
    if settings.SCHEDULER_API_KEY:
        print(f"✅ SCHEDULER_API_KEY: Configured (length: {len(settings.SCHEDULER_API_KEY)})")
        checks.append(True)
    else:
        print(f"⚠️  SCHEDULER_API_KEY: Not configured (optional)")
        checks.append(True)  # Optional
    
    # Check AWS credentials
    if settings.AWS_ACCESS_KEY_ID:
        print(f"✅ AWS_ACCESS_KEY_ID: Configured")
        checks.append(True)
    else:
        print(f"❌ AWS_ACCESS_KEY_ID: Not configured")
        checks.append(False)
    
    if settings.AWS_SECRET_ACCESS_KEY:
        print(f"✅ AWS_SECRET_ACCESS_KEY: Configured")
        checks.append(True)
    else:
        print(f"❌ AWS_SECRET_ACCESS_KEY: Not configured")
        checks.append(False)
    
    if settings.AWS_REGION:
        print(f"✅ AWS_REGION: {settings.AWS_REGION}")
        checks.append(True)
    else:
        print(f"❌ AWS_REGION: Not configured")
        checks.append(False)
    
    return all(checks)


async def main():
    """Main test function"""
    import sys
    
    if len(sys.argv) > 1 and sys.argv[1] == "cleanup":
        await test_schedule_cancellation()
        return
    
    print("\n🧪 EventBridge Scheduler Integration Test")
    print("=" * 60)
    
    # Step 1: Verify configuration
    config_ok = await verify_configuration()
    if not config_ok:
        print("\n❌ Configuration check failed. Please fix the issues above.")
        return
    
    # Step 2: Test Lambda Function
    lambda_ok = await test_lambda_function()
    if not lambda_ok:
        print("\n❌ Lambda function test failed. Cannot proceed.")
        return
    
    # Step 3: Test schedule creation
    print("\n⚠️  About to create a test schedule that will trigger in 2 minutes.")
    print("   This will attempt to call your Railway endpoint.")
    response = input("\nProceed? (yes/no): ")
    
    if response.lower() in ['yes', 'y']:
        schedule_ok = await test_schedule_creation()
        if schedule_ok:
            print("\n✅ All tests passed!")
            print("\n📝 Next steps:")
            print("   1. Monitor Railway logs: railway logs --follow")
            print("   2. Wait ~2 minutes for the schedule to trigger")
            print("   3. Verify the endpoint receives the request")
            print("   4. Clean up: python test_scheduler.py cleanup")
    else:
        print("\n⏭️  Skipped schedule creation test")


if __name__ == "__main__":
    asyncio.run(main())
