# Execute Game of Life stored procedure and draw the results
import pyodbc, sys, time, colorama

def db_config():
  return (";".join([
    "DRIVER={ODBC Driver 13 for SQL Server}", "SERVER=" + "BARRETT-MAIN\\BARRETTSQL",
    "DATABASE=" + "BARRETT_TEST", "Trusted_Connection=yes"
  ])) + ";"

def draw_generations(rows, size, start, end):
  cells = dict()
  for row in rows: 
    cells["{0};{1};{2}".format(row[0], row[1], row[2])] = 'X'
  for g in range(start, end+1):
    s = "\rGeneration:  {0}\n".format(g)
    for i in range(size):
      for j in range(size):
        key = "{0};{1};{2}".format(g, i, j)
        s += (cells[key] if (key in cells) else '.') + ' '
      s += '\n'
    sys.stdout.write("\x1b[{0}A".format(size+1) + s)
    sys.stdout.flush()
    time.sleep(0.50)

def main():
  size = 25
  start = 0
  total = 50
  batch_size = 10
  
  colorama.init()
  conn = pyodbc.connect(db_config())
  rows = []

  for i in range(0, total // batch_size):
    rows += conn.cursor().execute(
      "{CALL [dbo].[GameOfLife] (?,?,?)}", size, i * batch_size, (i+1) * batch_size
    ).fetchall()
  draw_generations(rows, size, start, total)


if __name__=='__main__': main()
