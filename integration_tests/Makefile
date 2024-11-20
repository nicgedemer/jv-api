env:
	python -m venv env

deps: env
	env/bin/pip install -U -r requirements.txt

test: deps
	env/bin/python -m unittest tests.py

test-production: deps
	SIMPSONS_BASE_URL=https://simpsons.jv-magic.com env/bin/python -m unittest tests.py
