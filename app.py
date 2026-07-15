from flask import Flask, render_template, redirect, url_for, request, flash
from flask_login import (
    LoginManager,
    UserMixin,
    login_user,
    logout_user,
    login_required,
    current_user
)
from datetime import datetime, timedelta
import os
import hashlib


app = Flask(__name__)


# ==================================================
# CONFIGURACIÓN
# ==================================================

app.secret_key = os.environ.get(
    "SECRET_KEY",
    "silenthub-change-this-secret"
)

app.config["REMEMBER_COOKIE_DURATION"] = timedelta(days=30)
app.config["REMEMBER_COOKIE_HTTPONLY"] = True
app.config["REMEMBER_COOKIE_SECURE"] = True


inicio_servidor = datetime.now()


# ==================================================
# LOGIN SYSTEM
# ==================================================

login_manager = LoginManager()

login_manager.login_view = "login"

login_manager.init_app(app)



# ==================================================
# USUARIO ADMIN
# ==================================================

# En producción estos valores irán a variables
# de entorno de Render.

ADMIN_USER = os.environ.get(
    "ADMIN_USER",
    "Silent"
)


ADMIN_PASSWORD = os.environ.get(
    "ADMIN_PASSWORD",
    "0024600"
)



class User(UserMixin):

    def __init__(self, username):

        self.id = username



@login_manager.user_loader
def load_user(user_id):

    return User(user_id)



# ==================================================
# RUTAS
# ==================================================


@app.route("/")
def inicio():

    if current_user.is_authenticated:

        return redirect(
            url_for("panel")
        )


    return redirect(
        url_for("login")
    )



# --------------------------
# LOGIN
# --------------------------

@app.route("/login", methods=["GET", "POST"])
def login():


    if current_user.is_authenticated:

        return redirect(
            url_for("panel")
        )


    if request.method == "POST":


        username = request.form.get(
            "username"
        )


        password = request.form.get(
            "password"
        )


        if (
            username == ADMIN_USER
            and password == ADMIN_PASSWORD
        ):


            user = User(username)


            login_user(
                user,
                remember=True
            )


            return redirect(
                url_for("panel")
            )


        else:


            flash(
                "🐀 Rata, Tu IP fue extraída"
            )



    return render_template(
        "login.html"
    )



# --------------------------
# LOGOUT
# --------------------------

@app.route("/logout")
@login_required
def logout():

    logout_user()


    return redirect(
        url_for("login")
    )



# --------------------------
# PANEL
# --------------------------

@app.route("/panel")
@login_required
def panel():


    tiempo = (
        datetime.now()
        -
        inicio_servidor
    )


    datos = {


        "nombre":
        "SilentHub",


        "version":
        "2.0",


        "estado":
        "Online",


        "tiempo":
        str(tiempo).split(".")[0],


        "usuario":
        current_user.id

    }



    return render_template(
        "panel.html",
        datos=datos
    )



# ==================================================
# SECURITY HEADERS
# ==================================================

@app.after_request
def security_headers(response):


    response.headers["X-Frame-Options"] = "DENY"

    response.headers["X-Content-Type-Options"] = "nosniff"

    response.headers["Referrer-Policy"] = "strict-origin"

    return response



# ==================================================
# START SERVER
# ==================================================

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
