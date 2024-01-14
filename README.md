# Example_Webpage
# start the app
Flask_APP=app.py flask run
# run the tests
coverage run --source=. test.py

coverage report  

# run the container
docker run -d -p 80:80 junglepolice/webpage


# This is a title

**paragraph 1**

*paragraph 2*

paragraph 3
