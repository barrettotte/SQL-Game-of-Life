# Execute Game of Life stored procedure and draw the results
import pyodbc

def db_config():
  return (";".join([
    "DRIVER={ODBC Driver 13 for SQL Server}", "SERVER=" + "BARRETT-MAIN\\BARRETTSQL",
    "DATABASE=" + "BARRETT_TEST", "Trusted_Connection=yes"
  ])) + ";"

def draw(rows, size, gens):
    cells = dict()
    for row in rows:
      cells[str(row[0]) + ',' + str(row[1]) + ',' + str(row[2])] = 'O' # str(row[4])
    print('')
    for g in range(gens+1):
        print(("-" * (size*2)) + '\n' + "Generation: " + str(g))
        for i in range(size):
            s = ''
            for j in range(size):
                key = str(g) + ',' + str(i) + ',' + str(j)
                s += (cells[key] if (key in cells) else '.') + ' '
            print(s)
        
def main():
  size = 25
  end = 10
  conn = pyodbc.connect(db_config())
  cursor = conn.cursor()
  cursor.execute("{CALL [dbo].[GameOfLife_Run] (?,?)}", (size, end))
  draw(cursor.fetchall(), size, end)

if __name__=='__main__': main()