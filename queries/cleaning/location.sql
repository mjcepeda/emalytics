/*relevant data from locations are type of location (categories column), rating, longitude and latitude*/
/*number of rows*/
select count(*) from :tableName;

/*Checking for null values in those columns*/
select * from :tableName where categories is null or rating is null or longitude is null or latitude is null;

/*Checking rating values (0 - 5)*/
select distinct(rating) from :tableName;

/*Checking categories values*/
select distinct(categories) from :tableName;

/*Checking latitude and longitude values*/
select TRIM(TRAILING '0' FROM cast (longitude as text)), TRIM(TRAILING '0' FROM cast (latitude as text)) from :tableName;

/*Inserting airport locations*/
insert into location (type, rating, latitude, longitude)
    select 'Airport', rating, cast (TRIM(TRAILING '0' FROM cast (latitude as text)) as numeric),
      cast (TRIM(TRAILING '0' FROM cast (longitude as text)) as numeric)
    from airports
    where categories = 'Airports' or categories ='Airport Terminals';

/*Inserting water locations*/
insert into location (type, rating, latitude, longitude)
    select 'Water', 5, cast (TRIM(TRAILING '0' FROM cast (latitude as text)) as numeric),
      cast (TRIM(TRAILING '0' FROM cast (longitude as text)) as numeric)
    from :tableName
where trim(color) ='#A3CBFF';

/*Inserting police department locations*/
insert into location (type, rating, latitude, longitude)
    select 'Police_department', rating, cast (TRIM(TRAILING '0' FROM cast (latitude as text)) as numeric),
      cast (TRIM(TRAILING '0' FROM cast (longitude as text)) as numeric)
    from police_departments
    where categories ='Police Departments';
	
/*Inserting rest of locations*/
insert into location (type, rating, latitude, longitude)
    select :typeLocation, rating, cast (TRIM(TRAILING '0' FROM cast (latitude as text)) as numeric),
      cast (TRIM(TRAILING '0' FROM cast (longitude as text)) as numeric)
    from :tableName;