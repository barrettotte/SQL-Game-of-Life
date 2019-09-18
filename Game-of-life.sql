-- Game of Life --
-- https://en.wikipedia.org/wiki/Conway%27s_Game_of_Life --

/*
	1. Any live cell with fewer than two live neighbours dies, as if by underpopulation.
	2. Any live cell with two or three live neighbours lives on to the next generation.
	3. Any live cell with more than three live neighbours dies, as if by overpopulation.
	4. Any dead cell with exactly three live neighbours becomes a live cell, as if by reproduction.
*/


-- TODO: Create table from generation 0 seed data (flat file or JSON) --


-- TODO: Accept this as a stored proc param
DECLARE @SizeX INT;
SET @SizeX = 25;

DECLARE @SizeY INT;
SET @SizeY = 25;

DECLARE @Iterations INT;
SET @Iterations = 3;

DECLARE @CurrentIteration INT;
SET @CurrentIteration = 1;


-- Store each generation --
DECLARE @AllGenerations		TABLE (Generation INT NOT NULL, X INT NOT NULL, Y INT NOT NULL, Alive BIT NOT NULL DEFAULT(1));
DECLARE @CurrentGeneration	TABLE (Generation INT NOT NULL, X INT NOT NULL, Y INT NOT NULL, Alive BIT NOT NULL DEFAULT(1));
DECLARE @LastGeneration		TABLE (Generation INT NOT NULL, X INT NOT NULL, Y INT NOT NULL, Alive BIT NOT NULL DEFAULT(1));
DECLARE @BlankGeneration	TABLE (Generation INT NOT NULL, X INT NOT NULL, Y INT NOT NULL, Alive BIT NOT NULL DEFAULT(1));


-- Create a blank "template" to reuse later -- 
DECLARE @I INT = 0, @J INT = 0;
WHILE(@I < @SizeX) BEGIN
	WHILE(@J < @SizeY) BEGIN
		INSERT INTO @BlankGeneration (Generation, X, Y, Alive) VALUES (0, @I, @J, 0);
		SET @J = @J + 1
	END
	SET @I = @I + 1
	SET @J = 0
END


-- Seed generation 0
INSERT INTO @AllGenerations SELECT * FROM @BlankGeneration;
UPDATE @AllGenerations SET Alive = 1 WHERE Generation = 0 AND X = 1 AND Y = 2;  --[ 
UPDATE @AllGenerations SET Alive = 1 WHERE Generation = 0 AND X = 1 AND Y = 3;	--   Blinker 
UPDATE @AllGenerations SET Alive = 1 WHERE Generation = 0 AND X = 0 AND Y = 3;  --]


-- 
WHILE(@CurrentIteration < @Iterations) BEGIN
	UPDATE @BlankGeneration SET Generation = @CurrentIteration;
	INSERT INTO @AllGenerations SELECT * FROM @BlankGeneration;
	SET @CurrentIteration = @CurrentIteration + 1
END;


SELECT * FROM @AllGenerations;




-- TODO: Return X and Y bounds as out parameters (for screen drawing at correct size)



