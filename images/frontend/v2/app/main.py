import os
import requests
from flask import Flask
app = Flask(__name__)

@app.route("/")
def hello():
    try:
        r = requests.get("http://%s" % os.environ['BACKEND'])
        if r.status_code == 200:
            return "frontend:v2 - %s\n" % r.text
        else:
            return "frontend:v2 failed to contact %s" % os.get('BACKEND')
    except:
        return "frontend:v2 failed to contact %s" % os.get('BACKEND')

if __name__ == "__main__":
    # Only for debugging while developing
    app.run(host='0.0.0.0', debug=True, port=80)
