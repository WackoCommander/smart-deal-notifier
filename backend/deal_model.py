from pydantic import BaseModel

class Deal(BaseModel):
    DealID: str
    DealName: str
    DealURL: str
    VoteUp: int
    VoteDown: int
    UserNotified: bool
    UserRelevant: bool
    RelevanceAssessed: bool