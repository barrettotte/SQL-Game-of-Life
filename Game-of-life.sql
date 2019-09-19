/*
Game of Life in TSQL
Barrett Otte
Return a table of generation data from running Game of Life.

https://en.wikipedia.org/wiki/Conway%27s_Game_of_Life

USE BARRETT_TEST
GO
EXEC [dbo].[GameOfLife_Run] 10,5;

*/

CREATE OR ALTER PROCEDURE [dbo].[GameOfLife_Run](
	@Size           INT,
	@Iterations     INT
)
WITH EXECUTE AS CALLER
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @AllGenerations    TABLE (Id BIGINT, Generation INT, X INT, Y INT, Alive BIT DEFAULT(0));
	DECLARE @CurrentGeneration TABLE (Id BIGINT, Generation INT, X INT, Y INT, Alive BIT DEFAULT(0));
	DECLARE @CurrentIteration  INT = 0;
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
		WHILE(@I < @Size) BEGIN
			WHILE(@J < @Size) BEGIN
				INSERT INTO @AllGenerations (Id, Generation, X, Y, Alive) VALUES (@IdIter, 0, @I, @J, 0);
				SET @J = @J + 1;
				SET @IdIter = @IdIter + 1;
			END;
			SET @I = @I + 1;
			SET @J = 0;
		END;
	END;


	-- TODO: Get generation 0 input from user --
	IF @CurrentIteration = 0 BEGIN
		-- Add Glider --
		UPDATE @AllGenerations SET Alive = 1 WHERE Generation = @CurrentIteration AND X = 1 AND Y = 0;
		UPDATE @AllGenerations SET Alive = 1 WHERE Generation = @CurrentIteration AND X = 2 AND Y = 1;
		UPDATE @AllGenerations SET Alive = 1 WHERE Generation = @CurrentIteration AND X = 0 AND Y = 2;
		UPDATE @AllGenerations SET Alive = 1 WHERE Generation = @CurrentIteration AND X = 1 AND Y = 2;
		UPDATE @AllGenerations SET Alive = 1 WHERE Generation = @CurrentIteration AND X = 2 AND Y = 2;
		
		SET @CurrentIteration = 1;
	END;


	-- Game of life loop --
	WHILE(@CurrentIteration < @Iterations) BEGIN
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
		WHILE(@I < @Size) BEGIN
			WHILE(@J < @Size) BEGIN				

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

				-- Apply rules --
				BEGIN
					IF @IsAlive = 1 
						IF @NeighborCount < 2 OR @NeighborCount > 3
							SET @IsAlive = 0;
					ELSE 
						IF @NeighborCount = 3
							SET @IsAlive = 1;			
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
