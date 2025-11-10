import asyncio
from app.core.config import Settings
from app.services.referrals import InviteReferralService

# Mock database class for testing
class MockDatabase:
    async def select(self, table, *, filters=None, limit=None, order_by=None):
        return []
    
    async def insert(self, table: str, data: dict):
        return {}
    
    async def update(self, table: str, data: dict, *, filters: dict):
        return {}
    
    async def upsert(self, table: str, data: dict, *, on_conflict: str):
        return {}
    
    async def get_profile(self, user_id):
        return None

async def test_invite_code_setting():
    # Test with invite_code_required = False
    settings = Settings(INVITE_CODE="False")
    database = MockDatabase()
    service = InviteReferralService(settings=settings, database=database)
    
    # This should not raise an exception when invite_code_required is False
    try:
        context = await service.enforce_signup_policy("test@example.com", None)
        print(f"Success: {context.mode}")
        assert context.mode == "bypass"
        print("Test passed: invite_code_required=False allows signup without invite code")
    except Exception as e:
        print(f"Test failed: {e}")
        return False
    
    # Test with invite_code_required = True
    settings = Settings(INVITE_CODE="True")
    service = InviteReferralService(settings=settings, database=database)
    
    # This should raise an exception when invite_code_required is True
    try:
        context = await service.enforce_signup_policy("test@example.com", None)
        print("Test failed: Should have raised an exception")
        return False
    except Exception as e:
        print(f"Success: Correctly raised exception - {e}")
        print("Test passed: invite_code_required=True requires invite code")
    
    return True

if __name__ == "__main__":
    asyncio.run(test_invite_code_setting())