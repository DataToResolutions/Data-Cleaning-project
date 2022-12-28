-- DATA CLEANING PROJECT IN SQL - NASHVILLE HOUSING DATASET

-- OPEN THE DATA THAT WE'LL BE USING

SELECT *
FROM ProjectPortfolio.dbo.NashvilleHousing


---------------------------------------------------------------------------------------------------------------------------------------------

-- STANDARDIZE DATA FORMAT

-- 1. Add the new column 'SaleDateConverted'

ALTER TABLE NashvilleHousing
ADD SaleDateConverted DATE;

-- 2. Update the table with the new column 'SaleDateConverted'

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(DATE,SaleDate) 

-- 3. Show the new column 'SaleDateConverted' with the DATE format

SELECT SaleDateConverted, CONVERT(DATE,SaleDate)
FROM ProjectPortfolio.dbo.NashvilleHousing

---------------------------------------------------------------------------------------------------------------------------------------------

-- POPULATE PROPERTY ADDRESS DATA

-- 1. Check to see if there are null values in 'Property Address'
SELECT *
FROM ProjectPortfolio.dbo.NashvilleHousing
--WHERE PropertyAddress IS NULL
ORDER BY ParcelID

-- 2. Join the table to itself: The same parcel ID should have the same address but the Unique ID will be different

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress) 
FROM ProjectPortfolio.dbo.NashvilleHousing a
JOIN ProjectPortfolio.dbo.NashvilleHousing b
 ON a.ParcelID = b.ParcelID
 AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL 


-- 3. Use the b.PropertyAddress column to poulate the a.PropertyAddress column based on common ParcelID

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress) 
FROM ProjectPortfolio.dbo.NashvilleHousing a
JOIN ProjectPortfolio.dbo.NashvilleHousing b
 ON a.ParcelID = b.ParcelID
 AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL 


----------------------------------------------------------------------------------------------------------------------------------------

-- BREAKING OUT ADDRESS INTO INDIVIDUAL COLUMNS (ADDRESS, CITY, STATE)


-- 1. Open data
SELECT PropertyAddress
FROM ProjectPortfolio.dbo.NashvilleHousing


-- 2. The PropertyAddress column is split into two parts based on the comma (-1 & +1 refers to the position of the comma)

SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) AS City
FROM ProjectPortfolio.dbo.NashvilleHousing

-- 3. Add two new coloums PropertySplitAddress and PropertySplitCity. Update the table with two new columns 

ALTER TABLE NashvilleHousing  
ADD PropertySplitAddress NVARCHAR(255);


UPDATE NashvilleHousing 
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)


ALTER TABLE ProjectPortfolio.dbo.NashvilleHousing 
ADD PropertySplitCity NVARCHAR(255);


UPDATE NashvilleHousing 
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))

-- 4. Updated table with all the newly added colums at the end 

SELECT *
FROM ProjectPortfolio.dbo.NashvilleHousing


-- LETS SPLIT OWNER ADDRESS INTO (ADDRESS, CITY, STATE)

-- 1. Open data

SELECT OwnerAddress
FROM ProjectPortfolio.dbo.NashvilleHousing

-- 2. Use PARSENAME to separate the OWNER ADDRESS backwards (3,2,1)

SELECT 
PARSENAME(REPLACE(OwnerAddress, ',', '.') ,3),
PARSENAME(REPLACE(OwnerAddress, ',', '.') ,2),
PARSENAME(REPLACE(OwnerAddress, ',', '.') ,1)
FROM ProjectPortfolio.dbo.NashvilleHousing


-- 3. Add three new coloums (OwnerSplitAddress, OwnerSplitCity, OwnerSplitState). Update the table with three new columns 

ALTER TABLE ProjectPortfolio.dbo.NashvilleHousing  
ADD OwnerSplitAddress NVARCHAR(255);

UPDATE NashvilleHousing 
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') ,3)


ALTER TABLE ProjectPortfolio.dbo.NashvilleHousing 
ADD OwnerSplitCity NVARCHAR(255);

UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') ,2)


ALTER TABLE ProjectPortfolio.dbo.NashvilleHousing 
ADD OwnerSplitState NVARCHAR(255);

UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.') ,1)

-- 4. Updated table with all the newly added colums at the end 

SELECT *
FROM ProjectPortfolio.dbo.NashvilleHousing

-------------------------------------------------------------------------------------------------------------------------------------------


-- CHANGE 'Y' AND 'N' TO 'YES' AND 'NO' IN 'SOLD AS VACANT' FIELD

-- Check how many distinct values exist and count their number

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM ProjectPortfolio.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

SELECT SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
     WHEN SoldAsVacant = 'N' THEN 'No'
	 ELSE SoldAsVacant
	 END
FROM ProjectPortfolio.dbo.NashvilleHousing

UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
                   WHEN SoldAsVacant = 'N' THEN 'No'
	               ELSE SoldAsVacant
	               END


--------------------------------------------------------------------------------------------------------------------------------------------


-- REMOVE DUPLICATES

WITH RowNumCTE AS(
SELECT *,
  ROW_NUMBER() OVER (
  PARTITION BY ParcelID, 
               PropertyAddress, 
               SalePrice, 
			   SaleDate,
               LegalReference
			   ORDER BY UniqueID) row_num
FROM ProjectPortfolio.dbo.NashvilleHousing
)

DELETE -- Delete the dublicates
FROM RowNumCTE
WHERE row_num > 1


------------------------------------------------------------------------------------------------------------------------------------------------


-- DELETE UNUSED COLUMNS (We don't do this to raw data. This is only for visualization stage)

SELECT *
FROM ProjectPortfolio.dbo.NashvilleHousing

ALTER TABLE ProjectPortfolio.dbo.NashvilleHousing 
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

ALTER TABLE ProjectPortfolio.dbo.NashvilleHousing 
DROP COLUMN SaleDate