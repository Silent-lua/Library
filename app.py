from flask import Flask, render_template
import os

app = Flask(__name__)


@app.route("/")
def inicio():
    return render_template("index.html")


@app.route("/panel")
def panel():
    return render_template("panel.html")


@app.route("/lobby")
def lobby():
    return render_template("lobby.html")


if __name__ == "__main__":
    app.run(
        host="0.0.0.0",
        port=int(os.environ.get("PORT", 5000))
    )
