from flask import Flask, request

app = Flask(__name__)

#  curl --data "param1=value1&param2=value2&foo=123{a:b, c:d}" 127.0.0.1:5000/process
@app.route('/process', methods=['POST'])
def result():
    print("called result()")
    print(request.form['gaitData'])  # should display 'bar'
    return 'Received !\n'  # response to your request.

#  curl --header "Content-Type: application/json" --request POST --data '{"username":xyz","password":"xyz"}' 127.0.0.1:5000/processJson
@app.route('/processJson', methods=['POST'])
def processJson():
    print("called processJson()")
    print(request.data.decode("utf-8") )  # should display 'bar'
    return 'Received !\n'  # response to your request.

app.run()  # blocking
