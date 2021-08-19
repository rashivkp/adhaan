import os
import re
import calendar
from sqlite3 import connect

pdffilename = 'Vengara_A3.pdf'
location = 'Vengara'

filename = 'data.txt'
line_regex = "(\d+)\s+(\d+:\d+)\s+(\d+:\d+)\s+(\d+:\d+)\s+(\d+:\d+)\s+(\d+:\d+)\s+(\d+:\d+)\s+(\d+:\d+)"
dbpath = 'adhaan.db'
conn = connect(dbpath)
curs = conn.cursor()
curs.execute("""CREATE TABLE IF NOT EXISTS adhaan (location text, month integer, day integer,
             dhuhr text, asr text, hanafi_asr text, maghrib text, isha text,
             subh text, fajr text, PRIMARY KEY(location, month, day));""")
conn.commit()

def process():
    os.system("pdftotext -layout {} {}".format(pdffilename, filename))
    os.system("sed -e '/^$/d' -e 's/^ \+//' -e '/^[^0-9]/d' {filename} > 1{filename}".format(filename=filename))

    fp = open("1"+filename)
    counter = 0
    section = -1
    for line in fp:
        day = (counter % 31) + 1
        if day == 1:
            section += 1
        process_line(line, section, day)
        counter += 1


# split line into different months
def process_line(line, section, day):
    column_starts = [0, 55, 110]
    column_length = 55

    for i in range(0, 3):
        start = column_starts[i]
        day_match = re.search(f'{day} ', line[start:start+column_length])
        if day_match is None:
            if i == 2:
                break
            continue
        month = (section * 3) + 1 + i
        process_month_day(month, day, line[start:])

def process_month_day(month, day, text):
    r = re.search(line_regex, text)
    if r is not None:
        print("M/Day = {}/{}, dhuhr {} asr {} sunrise {}".format(calendar.month_abbr[month],
                                                              r.group(1),
                                                              r.group(2),
                                                              r.group(3),
                                                              r.group(8)))
        query = f"""INSERT INTO adhaan VALUES("{location}", {month}, {day}, "{r.group(2)}",
            "{r.group(3)}", "{r.group(4)}", "{r.group(5)}",
            "{r.group(6)}", "{r.group(7)}", "{r.group(8)}");"""
        curs.execute(query)
        conn.commit()

if __name__ == '__main__':
    process();
