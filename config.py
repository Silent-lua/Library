import os
from datetime import timedelta


class Config:
    # ==========================
    # SEGURIDAD
    # ==========================
    SECRET_KEY = os.environ.get(
        "SECRET_KEY",
        "silenthub-change-this-secret"
    )

    # ==========================
    # BASE DE DATOS
    # ==========================
    SQLALCHEMY_DATABASE_URI = os.environ.get(
        "DATABASE_URL",
        "sqlite:///silenthub.db"
    )

    SQLALCHEMY_TRACK_MODIFICATIONS = False

    # ==========================
    # LOGIN
    # ==========================
    REMEMBER_COOKIE_DURATION = timedelta(days=30)
    REMEMBER_COOKIE_HTTPONLY = True

    # En producción (Render) se activará automáticamente
    REMEMBER_COOKIE_SECURE = os.environ.get(
        "COOKIE_SECURE",
        "False"
    ).lower() == "true"

    SESSION_COOKIE_HTTPONLY = True

    SESSION_COOKIE_SECURE = os.environ.get(
        "COOKIE_SECURE",
        "False"
    ).lower() == "true"
