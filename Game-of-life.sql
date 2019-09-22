/*
Game of Life in TSQL
Barrett Otte
Return a table of generation data from running Game of Life.

https://en.wikipedia.org/wiki/Conway%27s_Game_of_Life

EXEC [dbo].[GameOfLife] 25,0,10;
EXEC [dbo].[GameOfLife] 25,10,20;

*/

USE BARRETT_TEST
GO

CREATE OR ALTER PROCEDURE [dbo].[GameOfLife](
	@Size           INT,
	@StartIteration INT,
	@EndIteration   INT
)
WITH EXECUTE AS CALLER
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @AllGenerations    TABLE (Generation INT, X INT, Y INT, Alive BIT DEFAULT(0));
	DECLARE @CurrentIteration  INT = @StartIteration;
	DECLARE @IsAlive           BIT = 0;
	DECLARE @NeighborCount     SMALLINT = 0;
	DECLARE @I                 INT = 0;
	DECLARE @J                 INT = 0;


	IF @CurrentIteration = 0 BEGIN

		-- Wipe out previous generation data --
		IF OBJECT_ID('dbo.GameOfLife_Data', 'U') IS NOT NULL BEGIN
			DROP TABLE [dbo].[GameOfLife_Data];
		END;
		CREATE TABLE [dbo].[GameOfLife_Data] (
			Generation INT,
			X INT,
			Y INT,
			Alive BIT DEFAULT(0)
		);

		-- Seed Generation 0 with all dead cells --
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

		-- Testing --
		-- Add Glider --
		UPDATE @AllGenerations SET Alive = 1 WHERE Generation = @CurrentIteration AND ( 
			(X = 1 AND Y = 2) OR (X = 2 AND Y = 3) OR (X = 3 AND Y = 1) OR (X = 3 AND Y = 2) OR (X = 3 AND Y = 3));
		-- Add Blinker --
		UPDATE @AllGenerations SET Alive = 1 WHERE Generation = @CurrentIteration AND (
			(X = 15 AND Y = 5) OR (X = 15 AND Y = 6) OR (X = 15 AND Y = 7));
	END;

	ELSE BEGIN
		INSERT INTO @AllGenerations (Generation, X, Y, Alive)
			SELECT Generation, X, Y, Alive
			FROM [dbo].[GameOfLife_Data]
			WHERE Generation = @CurrentIteration;
	END;
	SET @CurrentIteration = @CurrentIteration + 1;

	-- Loop over each cell of each generation --
	WHILE(@CurrentIteration <= @EndIteration) BEGIN
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

	DELETE FROM [dbo].[GameOfLife_Data]
		WHERE Generation >= @StartIteration 
			AND Generation <= @EndIteration;

	INSERT INTO [dbo].[GameOfLife_Data] (Generation, X, Y, Alive)
		SELECT Generation, X, Y, Alive
		FROM @AllGenerations
		--WHERE Alive = 1;

	SELECT * FROM @AllGenerations
		WHERE Alive = 1;

END;
