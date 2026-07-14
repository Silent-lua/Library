from flask import Flask, render_template
import os
from datetime import datetime

app = Flask(__name__)

inicio_servidor = datetime.now()


@app.route("/")
def inicio():
    return render_template("index.html")


@app.route("/panel")
def panel():

    tiempo = datetime.now() - inicio_servidor

    datos = {
        "nombre": "SilentHub",
        "version": "1.0",
        "estado": "Online",
        "tiempo": str(tiempo).split(".")[0]
    }

    return render_template(
        "panel.html",
        datos=datos
    )


if __name__ == "__main__":
    app.run(
        host="0.0.0.0",
        port=int(os.environ.get("PORT", 5000))
    )
