import os
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    API_KEY: str = "secret-api-key"
    MAX_CONCURRENT_SCANS: int = 5
    
    # Scanner Configurations
    NUCLEI_PATH: str = "nuclei"  # Assumes binary is in PATH
    ZAP_API_URL: str = "https://localhost:8081"
    ZAP_API_KEY: str = "c1vlieurbp6muvgdg378g1ehlt"
    ACUNETIX_API_URL: str = "https://kali:3443/"
    ACUNETIX_API_KEY: str = "1986ad8c0a5b3df4d7028d5f3c06e936c95075764856f47789e14841451197eac"
    
    class Config:
        env_file = ".env"

settings = Settings()