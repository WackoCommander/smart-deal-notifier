from pydantic import BaseModel, Field
from typing import Optional

class Deal(BaseModel):
    """
    Pydantic model for Deal data from DynamoDB
    """
    DealID: str
    DealName: str
    DealURL: str
    VoteUp: int = 0
    VoteDown: int = 0
    UserNotified: bool = False
    UserRelevant: Optional[bool] = False
    RelevanceAssessed: Optional[bool] = False
    
    class Config:
        schema_extra = {
            "example": {
                "DealID": "deal123",
                "DealName": "50% off MacBook Pro",
                "DealURL": "https://example.com/deal123",
                "VoteUp": 42,
                "VoteDown": 5,
                "UserNotified": False,
                "UserRelevant": True,
                "RelevanceAssessed": True
            }
        }