-- Game of Life --
-- https://en.wikipedia.org/wiki/Conway%27s_Game_of_Life --

/*
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
*/


-- TODO: Convert this to a stored procedure
----- PARAMS START -----
DECLARE @SizeX            INT = 25;
DECLARE @SizeY            INT = 25;
DECLARE @IterationStart   INT =  0;
DECLARE @IterationEnd     INT =  2;
----- PARAMS END -------


-- Variables --
DECLARE @CurrentIteration   INT = @IterationStart;
DECLARE @AllGenerations     TABLE (Id BIGINT, Generation INT, X INT, Y INT, Alive BIT DEFAULT(0), Neighbors SMALLINT);
DECLARE @BlankGeneration    TABLE (Id BIGINT, Generation INT, X INT, Y INT, Alive BIT DEFAULT(0), Neighbors SMALLINT);

DECLARE @IdIter BIGINT = 0;
DECLARE @I INT;
DECLARE @J INT;


-- Create a blank "template" to reuse each generation --
BEGIN
	SET @IdIter = 0;
	SET @I = 0;
	SET @J = 0;
	WHILE(@I < @SizeX) BEGIN
		WHILE(@J < @SizeY) BEGIN
			INSERT INTO @BlankGeneration (Id, Generation, X, Y, Alive, Neighbors) VALUES (@IdIter, 0, @I, @J, 0, 0);
			SET @J = @J + 1;
			SET @IdIter = @IdIter + 1;
		END;
		SET @I = @I + 1;
		SET @J = 0;
	END;
END;



-- Seed generation 0 --
IF @CurrentIteration = 0 BEGIN
	INSERT INTO @AllGenerations SELECT * FROM @BlankGeneration;

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
	DECLARE @CurrentGeneration  TABLE (Id BIGINT, Generation INT, X INT, Y INT, Alive BIT DEFAULT(0), Neighbors SMALLINT);
	DECLARE @PreviousGeneration TABLE (Id BIGINT, Generation INT, X INT, Y INT, Alive BIT DEFAULT(0), Neighbors SMALLINT);
	DECLARE @Alives TABLE (Id BIGINT, Alive SMALLINT);
	DECLARE @NeighborCounts TABLE (Id BIGINT, Neighbors SMALLINT);

	/*
	BEGIN
		IF (@CurrentIteration = 1)
			INSERT INTO @PreviousGeneration SELECT * FROM @BlankGeneration;	
		ELSE
			INSERT INTO @PreviousGeneration SELECT * FROM @AllGenerations WHERE Id = @IdIter - 1;
	END;
	*/
	
	INSERT INTO @CurrentGeneration SELECT * FROM @AllGenerations WHERE Generation=@CurrentIteration-1;
	
	UPDATE @CurrentGeneration SET Generation = @CurrentIteration;


	WHILE(@I < @SizeX) BEGIN
		WHILE(@J < @SizeY) BEGIN
			DECLARE @NeighborCount SMALLINT = 0;
			DECLARE @IsAlive BIT = (SELECT Alive FROM @CurrentGeneration WHERE Id = @IdIter);

			IF @IsAlive = 1 BEGIN
				SET @NeighborCount = 1; -- test
			END;

			INSERT INTO @NeighborCounts (Id, Neighbors) VALUES (@IdIter, @NeighborCount);
			SET @J = @J + 1;
			SET @IdIter = @IdIter + 1;
		END;
		SET @I = @I + 1;
		SET @J = 0;
	END;

	-- Add current generation data to all generations --
	INSERT INTO @AllGenerations
		SELECT 
			NC.Id, Generation, X, Y, Alive, NC.Neighbors 
		FROM 
			@NeighborCounts NC
		FULL JOIN
			@CurrentGeneration CG
		ON CG.Id = NC.Id
	;


	SET @CurrentIteration = @CurrentIteration + 1;
END;


SELECT * FROM @AllGenerations WHERE Id < 50;



