use lab3

---Part 1

CREATE TABLE Cars (
  CarCode INT IDENTITY PRIMARY KEY NOT NULL,
  CarMake VARCHAR(10) NOT NULL,
  Owners VARCHAR(100) NULL,
  ManufDate DAtE NULL
);
go

CREATE TABLE CarParts (
  PartCode INT IDENTITY PRIMARY KEY NOT NULL,
  CarCode INT NOT NULL,
  Price MONEY NOT NULL,
  Description TEXT NULL,
  
  FOREIGN KEY (CarCode) REFERENCES Cars(CarCode)
);
go

CREATE TABLE Orders (
  OrderCode int IDENTITY PRIMARY KEY NOT NULL,
  PartCode int NOT NULL,
  OrderDate date NOT NULL,
  Quantity int NOT NULL,
  TotalCost money NOT NULL

  FOREIGN KEY (PartCode) REFERENCES CarParts(PartCode)
);
go

--------------

alter table CarParts add InStock int not null DEFAULT 4
alter table Cars alter column CarMake varchar(20)
go

select * from Cars
select * from CarParts
select * from Orders

-------------

insert into Cars (CarMake, Owners, ManufDate)
values ('Audi', 'Yuldash','2022-01-01')
insert into Cars (CarMake, Owners, ManufDate)
values ('BMW', NULL,'2018-03-12')

insert into CarParts(CarCode, Price, Description)
values ( 1, 120, NULL)
insert into CarParts(CarCode, Price, Description)
values ( 2, 250, NULL)
insert into CarParts(CarCode, Price, Description)
values ( 1, 500, 'engine')
insert into CarParts(CarCode, Price, Description)
values ( 2, 1200, 'engine')

insert into Orders(PartCode, OrderDate, Quantity, TotalCost)
values (1, '2020-01-05', 10, 1200)
insert into Orders(PartCode, OrderDate, Quantity, TotalCost)
values (2, '2021-03-09', 4, 1000)
insert into Orders(PartCode, OrderDate, Quantity, TotalCost)
values (3, '2019-6-01', 1, 500)
insert into Orders(PartCode, OrderDate, Quantity, TotalCost)
values (4, '2022-01-05', 1, 1200)

select * from Cars
select * from CarParts
select * from Orders

---Part 2

Alter Procedure orderOfCarParts (@carOwnerName VARCHAR(100), @carMake VARCHAR(20), @noOfPartsNeeded INT)
AS
BEGIN
begin transaction

-----------------------------

	declare @searchedPart table (PartCode int, CarCode int, Price money, Description text, InStock int)
		insert into @searchedPart
		select cp.PartCode, cp.CarCode, cp.Price, cp.Description, cp.InStock from CarParts cp
		join Cars c on cp.CarCode = c.CarCode 
		where c.Owners = @carOwnerName and c.CarMake = @carMake

	if exists (select * from @searchedPart sp where sp.InStock > @noOfPartsNeeded)
	begin
		declare @searchedPartTop1 table (PartCode int, CarCode int, Price money, Description text, InStock int)
		insert into @searchedPartTop1
			select top 1 * from @searchedPart sp where sp.InStock > @noOfPartsNeeded

		insert into Orders(PartCode, OrderDate, Quantity, TotalCost)
		values ( (select PartCode from @searchedPartTop1), (select GetDate()), @noOfPartsNeeded, (@noOfPartsNeeded * (select Price from @searchedPartTop1)))
	
------------------------------
	
		update CarParts set InStock = InStock - @noOfPartsNeeded where PartCode = (select PartCode from @searchedPartTop1)

------------------------------

		select * from Cars
		select * from CarParts
		select * from Orders
	end
-----------------------------

	else
	begin
		declare @sameOwnerCars table (CarName varchar(20), PartCode int, Price money)
		insert into @sameOwnerCars 
			select c.CarMake, cp.PartCode, cp.Price from Cars c 
			join CarParts cp on cp.CarCode = c.CarCode 
			where c.Owners = @carOwnerName and not exists (select * from Cars c where c.CarMake = @carMake)
			order by cp.Price asc

-----------------------------

		select * from @sameOwnerCars
	end

commit
END
go

begin transaction

exec orderOfCarParts @carOwnerName='Yuldash', @carMake='Audi', @noOfPartsNeeded=6
exec orderOfCarParts @carOwnerName='Yuldash', @carMake='Audi', @noOfPartsNeeded=2

rollback

---Part 3

begin transaction

create nonclustered index frequentJoinOfCars on CarParts(InStock)
create unique nonclustered index uniqueCarMake on Cars(CarMake)
create nonclustered index filterPartsByPrice on CarParts(Price)
create nonclustered index compositePrimaryKeyOrders on Orders(OrderCode)
create nonclustered index filterOrderByOrderDateAndTotalCost on Orders(OrderDate, TotalCost)

rollback