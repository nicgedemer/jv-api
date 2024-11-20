# Simpson Simulator Integration Tests
These tests verify the behavior of the Simpsons Simulator application.  They
currently test the simulations of Homer and Lisa, but only Homer is currently
implemented.

## Running locally against a local application

Prequisites:
  * The version of Python specified in the `.python-version` file installed and on your path
  * A version of the Simpsons Simulator API accessible at `http://localhost:4567`

```
$ make test
python -m venv env
env/bin/pip install -U -r requirements.txt
Collecting requests==2.24.0 (from -r requirements.txt (line 1))

(a bunch of stuff about installing packages)

env/bin/python -m unittest tests.py
....FFFFF
======================================================================
FAIL: test_lisa_bad_gift (tests.LisaTest)
----------------------------------------------------------------------
Traceback (most recent call last):
  File "/Users/danfuchs/src/danfuchs/senior_sre_interview/integration_tests/tests.py", line 59, in test_lisa_bad_gift
    self.assertEqual(res.status_code, 400)
AssertionError: 404 != 400

(a bunch more stuff about failing tests)

FAILED (failures=5)
make: *** [test] Error 1
```

## Running locally against a remote application

The base URL that these tests exercise can be specified in the `SIMPSONS_URL`
environment variable.  For example, if you want to run them against a version
of the API accessible at `https://simpsons.jv-magic.com`:

    $ SIMPSONS_BASE_URL=https://simpsons.jv-magic.com make test

## Running against the 'production' environment

A shortcut for running against the environment where you will deploy your code:

    $ make test-production
