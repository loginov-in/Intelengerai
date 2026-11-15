import os
from main import app
from flask import Flask, render_template, request, redirect, url_for, session, jsonify
#from flask_login import LoginManager, UserMixin, login_user, logout_user, login_required, current_user#


# Frontend routes
@app.route('/')
@app.route('/login')
def login():
    return render_template('login.html')


# Приложение, которое будет отображаться после успешного входа в систему (ВАЖНО: Страница должна быть защищена авторизацией)
@app.route("/apps")
def apps():
    return render_template('apps.html')