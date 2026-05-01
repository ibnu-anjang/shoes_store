from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# Sesuaikan db_shoes_store dengan nama database yang kamu buat di phpMyAdmin
import os
DB_HOST = os.getenv("DB_HOST", "db")
SQLALCHEMY_DATABASE_URL = f"mysql+pymysql://root:@{DB_HOST}/db_shoes_store"

engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

# Dependency untuk mendapatkan session database


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
