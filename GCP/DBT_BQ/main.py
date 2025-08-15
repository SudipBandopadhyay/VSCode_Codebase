from flask import Flask, request
import subprocess
import os

app = Flask(__name__)

@app.route("/", methods=["POST"])
def run_dbt():
    try:
        dbt_command = request.json.get("command", "run")  # default: dbt run
        result = subprocess.run(
            ["dbt", dbt_command],
            capture_output=True,
            text=True
        )
        return {
            "stdout": result.stdout,
            "stderr": result.stderr,
            "returncode": result.returncode
        }, 200
    except Exception as e:
        return {"error": str(e)}, 500

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8080))
    app.run(host="0.0.0.0", port=port)
