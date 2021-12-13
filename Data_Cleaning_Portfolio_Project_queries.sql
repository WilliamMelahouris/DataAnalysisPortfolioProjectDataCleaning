/*

Queries for Data Cleaning Project on Nashville Housing Data
Author: William Melahouris
All Queries were written in Microsoft SQL Server Management Studio

*/

SELECT *
FROM DataCleaningProject.dbo.NashvilleHousing

-----------------------------------------------------------------------------------------

-- Standardize Date Format

UPDATE DataCleaningProject.dbo.NashvilleHousing
SET SaleDate = CONVERT(Date, SaleDate)

SELECT SaleDate
FROM DataCleaningProject.dbo.NashvilleHousing

-- Alternatively, if the UPDATE above doesn't work, we can add a 
-- new column with the converted date using ALTER TABLE and UPDATE

ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date;

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(Date,SaleDate)

SELECT SaleDate, SaleDateConverted
FROM DataCleaningProject.dbo.NashvilleHousing

-----------------------------------------------------------------------------------------

-- Populate Property Address data using ISNULL and Inner Join
-- First run the UPDATE query

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM DataCleaningProject.dbo.NashvilleHousing AS a
JOIN DataCleaningProject.dbo.NashvilleHousing AS b
ON a.ParcelID = b.ParcelID
AND a.UniqueID <> b.UniqueID

-- This should return nothing, meaning there are no 
-- longer any NULL PropertyAddress values
SELECT PropertyAddress
FROM DataCleaningProject.dbo.NashvilleHousing
WHERE PropertyAddress IS NULL
ORDER BY ParcelID

-- See all the PropertyAddress values now
SELECT PropertyAddress
FROM DataCleaningProject.dbo.NashvilleHousing

-----------------------------------------------------------------------------------------

-- Breaking out Address into Individual Columns (Address, City, State)
-- First, break out the PropertyAddress column into Address and City

SELECT PropertyAddress
FROM DataCleaningProject.dbo.NashvilleHousing

-- Use SUBSTRING, CHARINDEX, and LEN
SELECT
    PropertyAddress,
	SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress)-1) AS Address,
	SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress)) AS City
FROM DataCleaningProject.dbo.NashvilleHousing

ALTER TABLE NashvilleHousing
ADD PropertySplitAddress nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress)-1)

ALTER TABLE NashvilleHousing
ADD PropertySplitCity nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress))

-- You should now see two new columns at the end,
-- PropertySplitAddress and PropertySplitCity
SELECT *
FROM DataCleaningProject.dbo.NashvilleHousing

-- Now break out the OwnerAddress column into Address, City, and State

SELECT OwnerAddress
FROM DataCleaningProject.dbo.NashvilleHousing

SELECT
-- Address
PARSENAME(REPLACE(OwnerAddress,',','.'),3),
-- City
PARSENAME(REPLACE(OwnerAddress,',','.'),2),
-- State
PARSENAME(REPLACE(OwnerAddress,',','.'),1)
FROM DataCleaningProject.dbo.NashvilleHousing


-- Address
ALTER TABLE DataCleaningProject.dbo.NashvilleHousing
ADD OwnerSplitAddress nvarchar(255);

UPDATE DataCleaningProject.dbo.NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.'),3)

-- City
ALTER TABLE DataCleaningProject.dbo.NashvilleHousing
ADD OwnerSplitCity nvarchar(255);

UPDATE DataCleaningProject.dbo.NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.'),2)

-- State
ALTER TABLE DataCleaningProject.dbo.NashvilleHousing
ADD OwnerSplitState nvarchar(255);

UPDATE DataCleaningProject.dbo.NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.'),1)

-- Now we should see 3 new columns at the end for the Owner's address, city, and state

SELECT *
FROM DataCleaningProject.dbo.NashvilleHousing

-----------------------------------------------------------------------------------------

-- Change Y and N to Yes and No in "Sold as Vacant" field

SELECT 
	SoldAsVacant,
	CASE 
		WHEN SoldAsVacant = 'N' THEN 'No'
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		ELSE SoldAsVacant
    END
FROM DataCleaningProject.dbo.NashvilleHousing

UPDATE DataCleaningProject.dbo.NashvilleHousing
SET SoldAsVacant = CASE 
						WHEN SoldAsVacant = 'N' THEN 'No'
						WHEN SoldAsVacant = 'Y' THEN 'Yes'
						ELSE SoldAsVacant
				   END

-- Now we should see only 'Yes' and 'No' as values in the SoldAsVacant column
SELECT DISTINCT SoldAsVacant, COUNT(SoldAsVacant)
FROM DataCleaningProject.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2 DESC

-----------------------------------------------------------------------------------------

-- Remove Duplicates

WITH RowNumCTE AS
(
SELECT 
	*,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID, 
			     PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY 
					UniqueID) AS row_num

FROM DataCleaningProject.dbo.NashvilleHousing
)
DELETE
FROM RowNumCTE
WHERE row_num > 1
-- After running the CTE with the DELETE statement above,
-- comment the 3 lines above, and then uncomment the 4 lines
-- below. You will see that the duplicates have been removed.
--SELECT *
--FROM RowNumCTE
--WHERE row_num > 1
--ORDER BY PropertyAddress

-----------------------------------------------------------------------------------------

-- Delete Unused Columns

SELECT *
FROM DataCleaningProject.dbo.NashvilleHousing

ALTER TABLE DataCleaningProject.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

ALTER TABLE DataCleaningProject.dbo.NashvilleHousing
DROP COLUMN SaleDate
