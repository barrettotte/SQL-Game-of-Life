/*
Game of Life in TSQL
Barrett Otte
Return a table of generation data from running Game of Life.

https://en.wikipedia.org/wiki/Conway%27s_Game_of_Life

*/

USE BARRETT_TEST
GO

CREATE OR ALTER PROCEDURE [dbo].[GameOfLife_Run](
	@Size           INT,
	@Iterations     INT
)
WITH EXECUTE AS CALLER
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @AllGenerations    TABLE (Generation INT, X INT, Y INT, Alive BIT DEFAULT(0));
	DECLARE @CurrentIteration  INT = 0;
	DECLARE @IsAlive           BIT = 0;
	DECLARE @NeighborCount     SMALLINT = 0;
	DECLARE @I                 INT = 0;
	DECLARE @J                 INT = 0;


	-- Seed Generation 0 --
	BEGIN
		SET @J = 0;
		WHILE(@J < @Size) BEGIN
			SET @I = 0;
			WHILE(@I < @Size) BEGIN
				INSERT INTO @AllGenerations (Generation, X, Y, Alive) VALUES (0, @J, @I, 0);
				SET @I = @I + 1;
			END;
			SET @J = @J + 1;
		END;
	END;


	-- TODO: Get generation 0 input from user --

	-- Add Glider --
	UPDATE @AllGenerations 
		SET Alive = 1 
		WHERE Generation = @CurrentIteration AND (
			(X = 1 AND Y = 2) OR
			(X = 2 AND Y = 3) OR
			(X = 3 AND Y = 1) OR
			(X = 3 AND Y = 2) OR
			(X = 3 AND Y = 3)
		);

	-- Add Blinker --
	UPDATE @AllGenerations 
		SET Alive = 1 
		WHERE Generation = @CurrentIteration AND (
			(X = 10 AND Y = 5) OR
			(X = 10 AND Y = 6) OR
			(X = 10 AND Y = 7)
		);

	SET @CurrentIteration = 1;
	WHILE(@CurrentIteration <= @Iterations) BEGIN

		-- Loop over each cell --
		SET @J = 0;
		WHILE(@J < @Size) BEGIN
			SET @I = 0;
			WHILE(@I < @Size) BEGIN
				
				-- Init cell state from previous generation --
				SET @IsAlive = (SELECT Alive 
					FROM @AllGenerations
					WHERE X = @J
						AND Y = @I
						AND Generation = @CurrentIteration - 1
				);

				-- Find alive adjacent neighbor cells --
				SET @NeighborCount = (
					SELECT COUNT(*)
					FROM @AllGenerations
					WHERE Alive = 1
						AND (
							(X = ((@J-1) % @Size) AND Y = ((@I-1) % @Size)) OR
							(X = ((@J  ) % @Size) AND Y = ((@I-1) % @Size)) OR
							(X = ((@J+1) % @Size) AND Y = ((@I-1) % @Size)) OR
							(X = ((@J-1) % @Size) AND Y = ((@I  ) % @Size)) OR
							(X = ((@J+1) % @Size) AND Y = ((@I  ) % @Size)) OR
							(X = ((@J-1) % @Size) AND Y = ((@I+1) % @Size)) OR
							(X = ((@J  ) % @Size) AND Y = ((@I+1) % @Size)) OR
							(X = ((@J+1) % @Size) AND Y = ((@I+1) % @Size))
						)
						AND Generation = @CurrentIteration - 1
				);

				SET @IsAlive = CASE
					WHEN @IsAlive = 1 THEN
						CASE
							WHEN @NeighborCount < 2 THEN 0
							WHEN @NeighborCount > 3 THEN 0
							ELSE 1 
						END
					WHEN @IsAlive = 0 AND @NeighborCount = 3 THEN 1
					ELSE 0 
				END;

				INSERT INTO @AllGenerations (Generation, X, Y, Alive)
					VALUES (@CurrentIteration, @J, @I, @IsAlive);
				
				SET @I = @I + 1;
			END;
			SET @J = @J + 1;
		END;
		SET @CurrentIteration = @CurrentIteration + 1;
	END;

	SELECT * FROM @AllGenerations
		WHERE Alive = 1;
END;


-- EXEC [dbo].[GameOfLife_Run] 25,5;

