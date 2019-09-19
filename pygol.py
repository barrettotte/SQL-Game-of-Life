# Test implementation of Game of Life
# https://nostarch.com/download/samples/PythonPlayground_sampleCh3.pdf

import numpy as np
import matplotlib.pyplot as plt 
import matplotlib.animation as animation

def randomGrid(N): return np.random.choice([255,0], N*N, p=[0.2, 0.8]).reshape(N, N)

def addGlider(i, j, grid): grid[i:i+3, j:j+3] = np.array([[0, 0, 255], [255, 0, 255], [0, 255, 255]])

def update(frameNum, img, grid, N):
    newGrid = grid.copy()
    for i in range(N):
        for j in range(N):
            total = int((grid[i, (j-1)%N] + grid[i, (j+1)%N] + 
                         grid[(i-1)%N, j] + grid[(i+1)%N, j] + 
                         grid[(i-1)%N, (j-1)%N] + grid[(i-1)%N, (j+1)%N] + 
                         grid[(i+1)%N, (j-1)%N] + grid[(i+1)%N, (j+1)%N])/255)
            if grid[i, j]  == 255:
                if (total < 2) or (total > 3):
                    newGrid[i, j] = 0
            else:
                if total == 3:
                    newGrid[i, j] = 255
    img.set_data(newGrid)
    grid[:] = newGrid[:]
    return img,

def main():
    N = 25
    updateInterval = 250
    grid = np.array([])
    grid = np.zeros(N*N).reshape(N, N)
    addGlider(1, 1, grid)
    #grid = randomGrid(N)
    fig, ax = plt.subplots()
    img = ax.imshow(grid, interpolation='nearest')
    ani = animation.FuncAnimation(fig, update, fargs=(img, grid, N, ), frames=10, interval=updateInterval, save_count=50)
    plt.show()

if __name__ == '__main__': main()