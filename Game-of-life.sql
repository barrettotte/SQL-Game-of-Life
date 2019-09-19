/*
Game of Life in TSQL
Barrett Otte
Return a table of generation data from running Game of Life.

https://en.wikipedia.org/wiki/Conway%27s_Game_of_Life


Rules:
	1. Any live cell with fewer than two live neighbours dies, as if by underpopulation.
	2. Any live cell with two or three live neighbours lives on to the next generation.
	3. Any live cell with more than three live neighbours dies, as if by overpopulation.
	4. Any dead cell with exactly three live neighbours becomes a live cell, as if by reproduction.

Improvements:
   - Maybe improve performance by only writing data around each automata ?
   - Move @AllGenerations to an actual table so it can be queried in the future
   - Table creation SQL for @AllGenerations when moved to table
   - Separate stored proc to seed data from JSON or flat file (assert @IterationStart > 0)

USE BARRETT_TEST
GO

EXEC [dbo].[GameOfLife_Run] 25,25,0,5;

*/


CREATE OR ALTER PROCEDURE [dbo].[GameOfLife_Run](
	@SizeX          INT,
	@SizeY          INT,
	@IterationStart INT,
	@IterationEnd   INT
)
WITH EXECUTE AS CALLER
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @AllGenerations    TABLE (Id BIGINT, Generation INT, X INT, Y INT, Alive BIT DEFAULT(0));
	DECLARE @CurrentGeneration TABLE (Id BIGINT, Generation INT, X INT, Y INT, Alive BIT DEFAULT(0));
	DECLARE @CurrentIteration  INT = @IterationStart;
	DECLARE @IsAlive           BIT = 0;
	DECLARE @NeighborCount     SMALLINT = 0;
	DECLARE @IdIter            BIGINT = 0;
	DECLARE @I                 INT = 0;
	DECLARE @J                 INT = 0;


	-- Seed Generation 0 --
	BEGIN
		SET @IdIter = 0;
		SET @I = 0;
		SET @J = 0;
		WHILE(@I < @SizeX) BEGIN
			WHILE(@J < @SizeY) BEGIN
				INSERT INTO @AllGenerations (Id, Generation, X, Y, Alive) VALUES (@IdIter, 0, @I, @J, 0);
				SET @J = @J + 1;
				SET @IdIter = @IdIter + 1;
			END;
			SET @I = @I + 1;
			SET @J = 0;
		END;
	END;


	IF @CurrentIteration = 0 BEGIN
		-- Blinker --
		UPDATE @AllGenerations SET Alive = 1 WHERE Generation = @CurrentIteration AND X = 1 AND Y = 0;
		UPDATE @AllGenerations SET Alive = 1 WHERE Generation = @CurrentIteration AND X = 1 AND Y = 1;
		UPDATE @AllGenerations SET Alive = 1 WHERE Generation = @CurrentIteration AND X = 1 AND Y = 2;

		-- Glider --
		/*
		UPDATE @AllGenerations SET Alive = 1 WHERE Generation = @CurrentIteration AND X = 1 AND Y = 0;
		UPDATE @AllGenerations SET Alive = 1 WHERE Generation = @CurrentIteration AND X = 2 AND Y = 1;
		UPDATE @AllGenerations SET Alive = 1 WHERE Generation = @CurrentIteration AND X = 0 AND Y = 2;
		UPDATE @AllGenerations SET Alive = 1 WHERE Generation = @CurrentIteration AND X = 1 AND Y = 2;
		UPDATE @AllGenerations SET Alive = 1 WHERE Generation = @CurrentIteration AND X = 2 AND Y = 2;
		*/
		SET @CurrentIteration = 1;
	END;


	-- Game of life loop --
	WHILE(@CurrentIteration < @IterationEnd) BEGIN
		SET @IdIter = 0;
		SET @I = 0;
		SET @J = 0;

		-- Load previous generation into current --
		INSERT INTO @CurrentGeneration 
			SELECT * 
			FROM @AllGenerations 
			WHERE Generation = @CurrentIteration - 1
		;
		UPDATE @CurrentGeneration SET Generation = @CurrentIteration;

		-- Loop over each cell --
		WHILE(@I < @SizeX) BEGIN
			WHILE(@J < @SizeY) BEGIN
				SET @IsAlive = (
					SELECT Alive 
					FROM @CurrentGeneration 
					WHERE Generation = @CurrentIteration 
					AND Id = @IdIter
				);
				-- Find alive adjacent neighbor cells --
				SET @NeighborCount = (
					SELECT COUNT(*) AS NC 
					FROM @CurrentGeneration 
					WHERE Alive = 1 
						AND (
							(X = @I-1 AND Y = @J-1) OR
							(X = @I-1 AND Y = @J  ) OR
							(X = @I-1 AND Y = @J+1) OR
							(X = @I   AND Y = @J-1) OR
							(X = @I   AND Y = @J+1) OR
							(X = @I+1 AND Y = @J-1) OR
							(X = @I+1 AND Y = @J  ) OR
							(X = @I+1 AND Y = @J+1)
						)
				);

				-- Apply Game of Life rules --
				BEGIN
					IF @IsAlive = 0 AND @NeighborCount = 3
						SET @IsAlive = 1;
					ELSE IF (@IsAlive = 1 AND @NeighborCount < 2)
						SET @IsAlive = 0;
					ELSE IF @IsAlive = 1 AND @NeighborCount > 3
						SET @IsAlive = 0;
					ELSE IF @IsAlive = 1 AND (@NeighborCount = 2 OR @NeighborCount = 3)
						SET @IsAlive = 1;
					ELSE
						SET @IsAlive = 0;
				END;
				UPDATE @CurrentGeneration SET Alive = @IsAlive WHERE Id = @IdIter;
			
				SET @J = @J + 1;
				SET @IdIter = @IdIter + 1;
			END;
			SET @I = @I + 1;
			SET @J = 0;
		END;

		-- Record generation data --
		INSERT INTO @AllGenerations
			SELECT Id, Generation, X, Y, Alive
			FROM @CurrentGeneration;
		DELETE FROM @CurrentGeneration;

		SET @CurrentIteration = @CurrentIteration + 1;
	END;

	-- Return alive cells, empty assumed dead --
	SELECT * FROM @AllGenerations WHERE Alive=1;
END;
