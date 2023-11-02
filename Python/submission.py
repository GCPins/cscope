#!/usr/bin/env python


# import necessary modules
import getpass

from lxml import html
import requests
import sys 
import os

from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By

# main function
def main():

    # start new session w/ spoof & login with provided credentials
    session = requests.Session()
    session.headers.update({'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; rv:109.0) Gecko/20100101 Firefox/118.0'})

    c = login()
    session.cookies.update(c)

    # once logged in, get list of courses/assignments
    course_list = get_courses(session)

    if (not course_list):
        print("You have no courses, entered your credentials incorrectly, or an error occured.")
        sys.exit(1)

    course_name = sys.argv[3]

    assignments = get_course_assignments(session, list(filter(lambda x: x['name'] == course_name, course_list))[0]['path'])
    assignment_name = sys.argv[4]

    # get file/list of files to submit if assignment exists
    if (not assignment_name):
        print("You don't have any assignments for this course, or an error occurred.")
        sys.exit(1)
    	
    
    file_input = sys.argv[5]

    files = []
    if (os.path.isdir(file_input)):
        files = [os.path.join(file_input, f) for f in os.listdir(file_input) if os.path.isfile(os.path.join(file_input, f))]
    else:
        files = file_input.split(' ')
    files = [i.replace("@|@"," ") for i in files]

    # check for valid file entry
    for f in files:
    	if (not os.path.exists(f)):
            print("A file/folder you entered does not exist, or an error occured.", str(f))
            sys.exit(1)

    # upload/submit the file(s) provided to the chosen assignment
    submit_submission(session, list(filter(lambda x: x['title'] == assignment_name, assignments))[0]['path'], files)

def login():
    option = Options()
    #option.headless = True
    option.add_argument("--headless=new")
    option.add_argument("--window-size=1920,1080")
    

    #print("Loading browser (please wait)...")

    option.add_experimental_option('excludeSwitches', ['enable-logging'])


    driver = webdriver.Chrome(options=option) 
    driver.get("https://gradescope.com/auth/saml/clemson")

    passwrd = driver.find_element(By.NAME, "j_password")
    usrname = driver.find_element(By.NAME, "j_username")

    usr = sys.argv[1]
    pss = sys.argv[2]

    passwrd.send_keys(pss)
    usrname.send_keys(usr)

    clickMe = driver.find_element(By.NAME, "_eventId_proceed")
    clickMe.click()

    #print("Logging in, please wait...")
    s_cookies = driver.get_cookies()

    r_cookies = {}
    for c in s_cookies:
        r_cookies[c['name']] = c['value']

    driver.quit()

    return r_cookies


"""
def login(session, username, password):
    session.get('https://www.gradescope.com/auth/saml/clemson')
    idp_page = session.post(
        'https://idp.clemson.edu/idp/profile/SAML2/Redirect/SSO?execution=e1s1',
        data={
            'j_username': username,
            'j_password': password,
            '_eventId_proceed': '',
        }
    )

    doc = html.document_fromstring(idp_page.content)
    saml_response = doc.xpath('//input[@type="hidden"]/@value')
    r = session.post('https://www.gradescope.com/auth/saml/clemson/callback', data={'SAMLResponse': saml_response})
"""

# retrieves courses once logged in
def get_courses(session):
    page = session.get('https://www.gradescope.com')
    doc = html.document_fromstring(page.content)
    courses = doc.xpath('//a[@class="courseBox"]')

    return list(map(lambda course: {
        'path': course.get('href'),
        'short_name': course.find('h3[@class="courseBox--shortname"]').text_content(),
        'name': course.find('div[@class="courseBox--name"]').text_content(),
    }, courses))


# get assignments for the selected course
def get_course_assignments(session, path):
    page = session.get('https://www.gradescope.com' + path)

    doc = html.document_fromstring(page.content)
    elements = doc.xpath('//table/tbody/tr')

    assignments = []

    for e in elements:
        if e.find_class('progressBar'):
            title_element = e.find('th[@class="table--primaryLink"]/a')
            assignments.append({
                'title': title_element.text_content(),
                'path': title_element.get('href'),
            })

    return assignments


# submit/upload file(s) provided to the chosen assignment
def submit_submission(session, path, files):
    page = session.get('https://www.gradescope.com' + path)
    doc = html.document_fromstring(page.content)
    authenticity_token = doc.xpath('//meta[@name="csrf-token"]/@content')[0]

    data = (
        ('utf8', '✓'),
        ('authenticity_token', authenticity_token),
        ('submission[method]', 'upload'),
        ('submission[leaderboard_name]', sys.argv[1]),
    )

    files = (
        *tuple(map(lambda f: ('submission[files][]', ((os.path.basename(f)), open(f, 'rb'), 'application/octet-stream')), files)),
    )

    submission_response = session.post('https://www.gradescope.com' + '/'.join(path.split('/')[:-1]), files=files, data=data, headers={'Accept': 'application/json'}).json()
    if submission_response['success'] == True:
        print('submitted! visit https://www.gradescope.com' + submission_response['url'])
    else:
        print('unsuccesful!')


# python thing 
if __name__ == '__main__':
    main()