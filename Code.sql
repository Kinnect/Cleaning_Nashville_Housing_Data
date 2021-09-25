#Looking at all data

SELECT *
FROM clean_data.house_data;

#Standardize date format
#https://database.guide/list-of-date-format-specifiers-in-mysql/

UPDATE clean_data.house_data
SET SaleDate = STR_TO_DATE(SaleDate, '%m/%d/%Y');

#Alternative method without replacing column instantly

ALTER TABLE clean_data.house_data
ADD SaleDateConverted Date;

UPDATE clean_data.house_data
SET SaleDateConverted = CONVERT(SaleDate, DATE);

#Look at SaleDate column

SELECT SaleDate
FROM clean_data.house_data;

#View nulls in property address column

SELECT PropertyAddress
FROM clean_data.house_data
WHERE PropertyAddress is null;

#Populate property address

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress,
IFNULL(a.PropertyAddress, b.PropertyAddress)
FROM clean_data.house_data a
JOIN clean_data.house_data b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress is null;

#Update property address

UPDATE clean_data.house_data a
JOIN clean_data.house_data b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
SET a.PropertyAddress = IFNULL(a.PropertyAddress, b.PropertyAddress)
WHERE a.PropertyAddress is null;

#View PropertyAddress column

SELECT PropertyAddress
FROM clean_data.house_data;

#Breaking out address into seperate columns (Address, City, State)

SELECT SUBSTRING(PropertyAddress, 1, LOCATE(',', PropertyAddress) -1) as UpdatedAddress,
SUBSTRING(PropertyAddress, LOCATE(',', PropertyAddress) + 1, LENGTH(PropertyAddress)) UpdatedAddress2
FROM clean_data.house_data;

#Create address-address column

ALTER Table clean_data.house_data
ADD Propertysplitaddress Nvarchar(255);

UPDATE clean_data.house_data
SET Propertysplitaddress = SUBSTRING(PropertyAddress, 1, LOCATE(',', PropertyAddress) -1);

#Create address-city column 

ALTER Table clean_data.house_data
ADD Propertysplitcity Nvarchar(255);

UPDATE clean_data.house_data
SET Propertysplitcity = SUBSTRING(PropertyAddress, LOCATE(',', PropertyAddress) + 1, LENGTH(PropertyAddress));

#View OwnerAddress column

SELECT OwnerAddress
FROM clean_data.house_data;

#Breaking out address into seperate columns using SPLIT_STR function (Address, City, State)

SET GLOBAL log_bin_trust_function_creators = 1;
DELIMITER $$
DROP FUNCTION IF EXISTS `SPLIT_STR` $$
CREATE FUNCTION `SPLIT_STR`(
  x VARCHAR(255),
  delim VARCHAR(12),
  pos INT
)
RETURNS varchar(255)
RETURN REPLACE(SUBSTRING(SUBSTRING_INDEX(x, delim, pos),
       LENGTH(SUBSTRING_INDEX(x, delim, pos -1)) + 1),
       delim, '') $$
DELIMITER ;

#Viewing the seprated OwnerAddress columns

SELECT 
SPLIT_STR(OwnerAddress, ',', 1),
SPLIT_STR(OwnerAddress, ',', 2),
SPLIT_STR(OwnerAddress, ',', 3)
FROM clean_data.house_data;

#Creating three new seprated columns 

ALTER Table clean_data.house_data
ADD Ownersplitaddress Nvarchar(255);

UPDATE clean_data.house_data
SET Ownersplitaddress = SPLIT_STR(OwnerAddress, ',', 1);

ALTER Table clean_data.house_data
ADD Ownersplitcity Nvarchar(255);

UPDATE clean_data.house_data
SET Ownersplitcity = SPLIT_STR(OwnerAddress, ',', 2);

ALTER Table clean_data.house_data
ADD Ownersplitstate Nvarchar(255);

UPDATE clean_data.house_data
SET Ownersplitstate = SPLIT_STR(OwnerAddress, ',', 3);

#Viewing all data

SELECT * 
FROM clean_data.house_data;

#View all distinct values in SoldAsVacant

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM clean_data.house_data
GROUP BY SoldAsVacant
ORDER BY SoldAsVacant;

#Changing all Y and N to corrosponding Yes and No

SELECT SoldAsVacant,
CASE
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END
FROM clean_data.house_data;

#Updating the SoldAsVacant column

UPDATE clean_data.house_data
SET SoldAsVacant = 
CASE
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END;

#View all distinct values in SoldAsVacant to check the changes in the column

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM clean_data.house_data
GROUP BY SoldAsVacant
ORDER BY SoldAsVacant;

#Remove duplicates (Method for SQL Server)

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
FROM clean_data.house_data
)
SELECT * #DELETE
FROM RowNumCTE
WHERE row_num = 1;

##Remove duplicates (Method for MYSQL)

ALTER TABLE clean_data.house_data
ADD id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY FIRST;

WITH RowNumCTE AS(
SELECT id,
	ROW_NUMBER() OVER (
    PARTITION BY ParcelID,
				 PropertyAddress,
                 SalePrice,
                 SaleDate,
                 LegalReference
                 ORDER BY
					UniqueID
                    ) row_num
FROM clean_data.house_data
)
DELETE t
FROM RowNumCTE
JOIN clean_data.house_data t USING(id)
WHERE row_num > 1;

#Delete unsued columns

ALTER TABLE clean_data.house_data
DROP OwnerAddress, 
DROP TaxDistrict, 
DROP PropertyAddress;

#View full table after column drop

SELECT *
FROM clean_data.house_data;