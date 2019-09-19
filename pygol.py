# Test implementation of game of life in python
# https://www.geeksforgeeks.org/conways-game-life-python-implementation/

import numpy as np 
import matplotlib.pyplot as plt  
import matplotlib.animation as animation   
  
def update(f, img, grid, size):  
    newGrid = grid.copy() 
    for i in range(size): 
        for j in range(size): 
            total = int((
                grid[i, (j-1)%size]          + grid[i, (j+1)%size] + 
                grid[(i-1)%size, j]          + grid[(i+1)%size, j] + 
                grid[(i-1)%size, (j-1)%size] + grid[(i-1)%size, (j+1)%size] + 
                grid[(i+1)%size, (j-1)%size] + grid[(i+1)%size, (j+1)%size]
            )/255) 
            if grid[i, j] == 255:
                if total < 2 or total > 3: newGrid[i, j] = 0
            else: 
                if total == 3: newGrid[i, j] = 255
    img.set_data(newGrid)
    grid[:] = newGrid[:]
    return img

def main(): 
    size = 30
    updateInterval = 250
   
    grid = np.zeros(size * size).reshape(size, size) 
    grid[3,1]=255 ; grid[1,2]=255 ; grid[3,2]=255 ; grid[2,3]=255 ; grid[3,3]=255 # Add glider
  
    fig, ax = plt.subplots() 
    img = ax.imshow(grid, interpolation='nearest') 
    frame = animation.FuncAnimation(fig, update, fargs=(img, grid, size), frames=10, interval=updateInterval, save_count=50) 
    plt.show() 
  
if __name__ == '__main__': main() 
