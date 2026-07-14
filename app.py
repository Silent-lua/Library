from flask import Flask, jsonify

app = Flask(__name__)

@app.route("/")
def inicio():
    return "Mi servidor funciona"

@app.route("/api/test")
def test():
    return jsonify({
        "estado": "ok"
    })

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)