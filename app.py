from flask import Flask, render_template, redirect, url_for
from flask_login import (
    LoginManager,
    UserMixin,
    login_required,
    login_user,
    logout_user,
    current_user
)
import os
from datetime import datetime, timedelta

app = Flask(__name__)

# ==========================================================
# CONFIGURACIÓN
# ==========================================================

app.secret_key = os.environ.get(
    "SECRET_KEY",
    "CAMBIA_ESTO_EN_RENDER"
)

app.config["REMEMBER_COOKIE_DURATION"] = timedelta(days=30)

inicio_servidor = datetime.now()

# ==========================================================
# LOGIN MANAGER
# ==========================================================

login_manager = LoginManager()

login_manager.login_view = "login"

login_manager.init_app(app)

# ==========================================================
# USUARIO TEMPORAL
# ==========================================================

class User(UserMixin):

    def __init__(self, user_id):

        self.id = user_id


@login_manager.user_loader
def load_user(user_id):

    return User(user_id)

# ==========================================================
# RUTAS
# ==========================================================


@app.route("/")
def inicio():

    if current_user.is_authenticated:
        return redirect(url_for("panel"))

    return redirect(url_for("login"))


@app.route("/login")
def login():

    return render_template("login.html")


@app.route("/login/demo")
def login_demo():

    usuario = User("admin")

    login_user(
        usuario,
        remember=True
    )

    return redirect(url_for("panel"))


@app.route("/logout")
@login_required
def logout():

    logout_user()

    return redirect(url_for("login"))


@app.route("/panel")
@login_required
def panel():

    tiempo = datetime.now() - inicio_servidor

    datos = {

        "nombre": "SilentHub",

        "version": "2.0",

        "estado": "Online",

        "tiempo": str(tiempo).split(".")[0],

        "usuario": current_user.id

    }

    return render_template(
        "panel.html",
        datos=datos
    )


# ==========================================================
# INICIO
# ==========================================================

if __name__ == "__main__":

    app.run(
        host="0.0.0.0",
        port=int(
            os.environ.get(
                "PORT",
                5000
            )
        )
    )
