# 安装依赖

    python setup.py bdist_wheel sdist

# 启动服务

    pip install --force-reinstall dist/demo15-0.1.0-py3-none-any.whl && pip install -r requirements.txt && demo15

# 查看 swagger ui

    http://localhost:8080/ui