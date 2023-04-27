/* 

Cleansing data in SQL Queries 
*/



-------------------------------------------------------------------------------------------------------
--Standardize Date Format
Update NashvilleHousing
SET SaleDate = CONVERT(Date,SaleDate)

Alter TABLE NashvilleHousing
Add SaleDateConverted Date;

Update NashvilleHousing
SET SaleDateConverted = CONVERT(Date,SaleDate)

Select SaleDateConverted, CONVERT(Date, SaleDate)
From Portfolio_Yuen..NashvilleHousing

-------------------------------------------------------------------------------------------------------
-- Populate Property Address data (Self-Join)
--Locate duplicate ParcelIDs and designated property address, 
--then replace the correct property address into any NULL values corresponding to the same ParcelID

Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
From Portfolio_Yuen..NashvilleHousing a
JOIN Portfolio_Yuen..NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null

Update a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
From Portfolio_Yuen..NashvilleHousing a
JOIN Portfolio_Yuen..NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null 

-------------------------------------------------------------------------------------------------------

-- Breaking out Address into Individual Columns (Address, City, State) for PropertyAddress

Select
SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1) as Address
, SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1, LEN(PropertyAddress)) as Address 
From Portfolio_Yuen..NashvilleHousing

Alter TABLE NashvilleHousing
Add PropertySplitAddress Nvarchar(255); 

Update NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress)-1)

Alter TABLE NashvilleHousing
Add PropertySplitCity Nvarchar(255);

Update NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+1, LEN(PropertyAddress))

Select *
From Portfolio_Yuen..NashvilleHousing

--Breaking out Address into Individual Columns (Address, City, State) for OwnerAddress
Select
PARSENAME(REPLACE(OwnerAddress,',','.'),3)
PARSENAME(REPLACE(OwnerAddress,',','.'),2)
PARSENAME(REPLACE(OwnerAddress,',','.'),1)
From Portfolio_Yuen..NashvilleHousing

Alter TABLE NashvilleHousing
Add OwnerSplitAddress Nvarchar(255); 

Alter TABLE NashvilleHousing
Add OwnerSplitCity Nvarchar(255);

Alter TABLE NashvilleHousing
Add OwnerSplitState Nvarchar(255);

Update NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.'),3)

Update NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.'),2)

Update NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.'),1)

-------------------------------------------------------------------------------------------------------
--Change Y and N to Yes and No in "Sold as Vacant" field 

--Identify disparate aggregate values (Y, N, Yes, No) and count for "Sold as Vacant" field
Select Distinct(SoldAsVacant), Count(SoldAsVacant)
From Portfolio_Yuen..NashvilleHousing
Group by SoldAsVacant
order by 2 

Update NashvilleHousing
Set SoldAsVacant = Case When SoldAsVacant = 'Y' Then 'Yes'
	When SoldAsVacant = 'N' Then 'No'
	Else SoldAsVacant
	End 
From Portfolio_Yuen..NashvilleHousing

Select *
From Portfolio_Yuen..NashvilleHousing

-------------------------------------------------------------------------------------------------------
--Remove Duplicates 

WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
	ORDER BY UniqueID
	) as row_num
From Portfolio_Yuen..NashvilleHousing
)
DELETE
From RowNumCTE
Where row_num > 1 

 
-------------------------------------------------------------------------------------------------------
--Delete Unused Columns  

Select *
From Portfolio_Yuen..NashVilleHousing

ALTER TABLE Portfolio_Yuen..NashVilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

ALTER TABLE Portfolio_Yuen..NashVilleHousing
DROP COLUMN SaleDate
