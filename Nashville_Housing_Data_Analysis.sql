
-- DATA CLEANING PROCESS

-- Standardize Date Format

SELECT*
FROM [Portfolio Project]..NashvilleHousing

ALTER TABLE NashvilleHousing
ADD SaleDateConverted DATE

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(DATE,SaleDate)


-- Add column SaleYear

ALTER TABLE [Portfolio Project]..NashvilleHousing
ADD SaleYear FLOAT

UPDATE [Portfolio Project]..NashvilleHousing
SET SaleYear = PARSENAME(REPLACE(SaleDateConverted, '-', '.') , 3)


-- Add column SaleMonth

ALTER TABLE [Portfolio Project]..NashvilleHousing
ADD SaleMonth FLOAT

UPDATE [Portfolio Project]..NashvilleHousing
SET SaleMonth = PARSENAME(REPLACE(SaleDateConverted, '-', '.') , 2)


-- Add column SaleMonthName

ALTER TABLE [Portfolio Project]..NashvilleHousing
ADD SaleMonthName nvarchar(50)

UPDATE [Portfolio Project]..NashvilleHousing
SET SaleMonthName = DATENAME(MONTH, DATEADD(MONTH,SaleMonth,'2022-12-01'))


-- Add column SaleDay

ALTER TABLE [Portfolio Project]..NashvilleHousing
ADD SaleDay FLOAT

UPDATE [Portfolio Project]..NashvilleHousing
SET SaleDay = PARSENAME(REPLACE(SaleDateConverted, '-', '.') , 1)


-- Populate Property Address column

SELECT a.ParcelId, a.PropertyAddress, b.ParcelId, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM [Portfolio Project]..NashvilleHousing a
JOIN [Portfolio Project]..NashvilleHousing b
	ON a.ParcelId = b.ParcelId
	AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress is null

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM [Portfolio Project]..NashvilleHousing a
JOIN [Portfolio Project]..NashvilleHousing b
	ON a.ParcelId = b.ParcelId
	AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress is null


-- Break out Address into Individual Columns (Address, City, State)

SELECT PropertyAddress
FROM [Portfolio Project]..NashvilleHousing


ALTER TABLE NashvilleHousing
ADD PropertySplitAddress Nvarchar(255)

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress,1, CHARINDEX(',', PropertyAddress)-1)


ALTER TABLE NashvilleHousing
ADD PropertySplitCity Nvarchar(255)

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))


ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress Nvarchar(255)

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)


ALTER TABLE NashvilleHousing
ADD OwnerSplitCity Nvarchar(255)

UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)

ALTER TABLE NashvilleHousing
ADD OwnerSplitState Nvarchar(255)

UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)

--  Rename inconsistent names in LandUse column

UPDATE [Portfolio Project]..NashvilleHousing
SET LandUse = REPLACE(LandUse, 'VACANT RESIENTIAL LAND', 'VACANT RESIDENTIAL LAND')

UPDATE [Portfolio Project]..NashvilleHousing
SET LandUse = REPLACE(LandUse, 'VACANT RES LAND', 'VACANT RESIDENTIAL LAND')


-- Change Y and N to Yes and No in "Sold as Vacant" field

SELECT DISTINCT (SoldAsVacant), COUNT(SoldAsVacant)
FROM [Portfolio Project]..NashvilleHousing
GROUP BY SoldAsVacant


UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		   WHEN SoldAsVacant = 'N' THEN 'No'
		   ELSE SoldAsVacant
		   END


-- Remove Duplicates

WITH RowNumCTE AS(
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

FROM [Portfolio Project]..NashvilleHousing
)
DELETE
FROM RowNumCTE
WHERE row_num > 1


-- Delete Unused Columns

Alter Table [Portfolio Project]..NashvilleHousing
DROP COLUMN SaleMonth, OwnerAddress, TaxDistrict, PropertyAddress, SaleDate


-- Checking new columns

SELECT *
FROM [Portfolio Project]..NashvilleHousing


-- DATA EXPLORATION AND ANALYSIS

-- Showing number of sales per day

SELECT SaleDay, COUNT(*) AS Daily_Numb_Sales
FROM [Portfolio Project]..NashvilleHousing
GROUP BY SaleDay
ORDER BY Daily_Numb_Sales DESC



-- Showing number of sales per month

SELECT SaleMonthName, COUNT(*) AS Monthly_Numb_Sales
FROM [Portfolio Project]..NashvilleHousing
GROUP BY SaleMonthName
ORDER BY  Monthly_Numb_Sales DESC



-- Showing number of sales per year

SELECT SaleYear, COUNT(*) AS Yearly_Numb_Sales
FROM [Portfolio Project]..NashvilleHousing
GROUP BY SaleYear
ORDER BY SaleYear DESC



-- Showing number of sales by land use

SELECT LandUse, COUNT(*) AS LandUse_Num_Sales
FROM [Portfolio Project]..NashvilleHousing
GROUP BY LandUse
ORDER BY LandUse_Num_Sales DESC


-- Showing number of sales by property location

SELECT PropertySplitCity, COUNT(*) AS Numb_Sales_by_location
FROM [Portfolio Project]..NashvilleHousing
GROUP BY PropertySplitCity
ORDER BY Numb_Sales_by_location DESC
 

-- Showing homes with highest sale prices

SELECT SaleDateConverted, LandUse, PropertySplitCity, MAX(SalePrice) AS Highest_Sale_Price
, (SELECT ROUND(AVG(SalePrice),0) FROM [Portfolio Project]..NashvilleHousing) AS AllAvgSalePrice
FROM [Portfolio Project]..NashvilleHousing
GROUP BY SaleDateConverted, LandUse, PropertySplitCity, SalePrice
ORDER BY SalePrice DESC 



-- Showing home prices higher than all average sale price in relation to their locations

SELECT LandUse, PropertySplitCity, SalePrice
, COUNT(LandUse) OVER (PARTITION BY LandUse) AS LandUse_Num_Sales
, AVG(SalePrice) OVER (PARTITION BY LandUse) AS AvgSalePrice
FROM [Portfolio Project]..NashvilleHousing
WHERE SalePrice > 327530
GROUP BY LandUse, PropertySplitCity, SalePrice



-- Showing Total revenue generated per year

WITH CTE_Revenue (SaleYear, Yearly_Numb_Sales, Yearly_AvPrice)
AS
(SELECT SaleYear, COUNT(*) AS Yearly_Numb_Sales
, ROUND(AVG(SalePrice),0) AS Yearly_AvPrice
FROM [Portfolio Project]..NashvilleHousing
GROUP BY SaleYear
)
SELECT SaleYear
, Yearly_Numb_Sales
,FORMAT (Yearly_AvPrice,'C','en-us') AS Yearly_AvPrice
,FORMAT (Yearly_Numb_Sales * Yearly_AvPrice,'C','en-us') AS Yearly_Tot_Revenue
FROM CTE_Revenue





