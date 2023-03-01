
/* 
SQL Data Cleaning

Nashville Housing data set used - 56 477 Rows of data
*/

-----------------------------------------------------------------------------------------------


-- View Dataset

SELECT *
FROM PortfolioProject..NashvilleHousing;


-----------------------------------------------------------------------------------------------


-- Standardize the Date Format


SELECT SaleDate
FROM PortfolioProject..NashvilleHousing;

SELECT SaleDate --, CONVERT(Date, SaleDate)
FROM PortfolioProject..NashvilleHousing;

UPDATE NashvilleHousing
SET SaleDate = CAST(SaleDate AS Date); -- Can also use CONVERT(Date, SaleDate)


-- The previous UPDATE did not work as excpected, so I add a new column, add the new date.

ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date;

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate);

SELECT SaleDateConverted
FROM PortfolioProject..NashvilleHousing;



-----------------------------------------------------------------------------------------------


-- Populate the property address data


SELECT *
FROM PortfolioProject..NashvilleHousing;

SELECT *
FROM PortfolioProject..NashvilleHousing
--WHERE PropertyAddress IS NULL
ORDER BY ParcelID;


/* 
Looking at the data, we can notice that there are NULL values in the Property Address fields.
Going a bit further we can also notice that on the parcel ID field, there are duplicates (Rows 86 & 87, 159 & 160
We can add the correct address where the address field is NULL, and the ParcelID fields are duplicate, providing the correct address for the NULL address
*/


-- We first check to ensure the parcel ID and addresses match with the NULL values. Then Update the NULL Values with the correct address.

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL;

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL


-----------------------------------------------------------------------------------------------


-- Breaking out the Addresses into individual columns (Address, City, State)


SELECT PropertyAddress
FROM PortfolioProject..NashvilleHousing


-- Start off by using Substring to split the address into the address and city fields

SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) AS Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) AS City
FROM PortfolioProject..NashvilleHousing
ORDER BY City;


-- We need to add two new columns for these values and add the data to the columns

ALTER TABLE NashvilleHousing
ADD PropertySplitAddress nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1); -- we -1 to exclude the comma from the address at the end

ALTER TABLE NashvilleHousing
ADD PropertySplitCity nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)); -- We +1 to remove the comma from the beginning of the city values

SELECT PropertyAddress, PropertySplitAddress, PropertySplitCity
FROM PortfolioProject..NashvilleHousing;


-- Next we look at the Owner Address

SELECT OwnerAddress
FROM PortfolioProject..NashvilleHousing;


-- I will use ParseName function to split the address, city and state
-- I will need to replace the comma, with a period as the PARSENAME checks for periods to split on

SELECT
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)
,PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)
,PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM PortfolioProject..NashvilleHousing;


-- Now the three new columns needs to be created and data saved to it

ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

ALTER TABLE NashvilleHousing
ADD OwnerSplitCity nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER TABLE NashvilleHousing
ADD OwnerSplitState nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

SELECT OwnerAddress, OwnerSplitAddress, OwnerSplitCity, OwnerSplitState
FROM PortfolioProject..NashvilleHousing;


-----------------------------------------------------------------------------------------------


-- Change the Y to Yes and the N to No in 'Sold as Vacant' field

SELECT DISTINCT SoldAsVacant, COUNT(SoldAsVacant) AS Totals
FROM PortfolioProject..NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY Totals;


-- Using a Case Statement to change the values accordingly

SELECT SoldAsVacant, 
CASE
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END
FROM PortfolioProject..NashvilleHousing


UPDATE NashvilleHousing
SET SoldAsVacant = CASE
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END


-----------------------------------------------------------------------------------------------


-- Remove Duplicate - Usually would not do this in SQL, but this is to demonstrate how to remove duplicates.


/* NOTE: Identifying the duplicates by ParceID, PropertyAddress, SalePrice, SaleDate, LegalReference. 
		 When looking at the data, if these values are identical, it can be inferred that they are duplicated */


-- First let us check how many are duplicates, then delete using CTE

WITH RowNumCTE AS (
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY 
					UniqueID
					) row_num
FROM PortfolioProject..NashvilleHousing
)
DELETE --SELECT *
FROM RowNumCTE
WHERE row_num > 1
-- ORDER BY PropertyAddress;


-----------------------------------------------------------------------------------------------


-- Delete Unused Columns


SELECT *
FROM PortfolioProject..NashvilleHousing;

-- The SaleDate, PropertyAddress, OwnerAddress & TaxDistrict Columns are not required any more.

ALTER TABLE PortfolioProject..NashvilleHousing
DROP COLUMN SaleDate, PropertyAddress, OwnerAddress, TaxDistrict;


-- Now the Table is much cleaner and useable. Quite a bit more standardized.