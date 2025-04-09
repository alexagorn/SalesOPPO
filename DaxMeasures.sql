## To find solution of tasks i needed to create connection between table i created model
## so I choose table with nessesarily data and then created 1 relationship between FactCustomerSales >> Fact CustomerSalesGoods
## Additionally, I had an opportunity unfolded exsiting rows in table which were inner keys and it help me to get needed information
## So in FactCustomerSales i unfolded DimDivion and selected from there column Name
## and from DimUsers i selected also column Name 

## In FactCustomerSalesGoods I added new column from DimNomenclature table - Name and Sku

## On the first tab :
## To calculate general sales of sku i wrote measure which look like
  
## Загальні продажі OPPO (General Sales of OPPO) = 
1) CALCULATE(
    COUNT(FactCustomerSales[CustomerOrderRef]),  -- Підраховуємо кількість замовлень (Count of order quantity)
    FILTER(
        FactCustomerSalesGoods, 
        FactCustomerSalesGoods[DimNomenclature.Sku] IN {"00000407686", "00000407688", "00000407690", "00000407691", "00000411895"}
    ),
    FactCustomerSales[TotalAmount] <> 0  -- Check, if total amount is not 0
)

## To calculate plan sales of group i used dax formula:
  
2) План продажів для групи (plan sales of group) = 
SUMX(
    VALUES(FactCustomerSales[Група]), 
    SWITCH(
        TRUE(),
        FactCustomerSales[Група] = "ГРУПА 1", DISTINCTCOUNT(FactCustomerSales[DimDivision.Name]) * 20,
        FactCustomerSales[Група] = "ГРУПА 2", DISTINCTCOUNT(FactCustomerSales[DimDivision.Name]) * 15,
        FactCustomerSales[Група] = "ГРУПА 3", DISTINCTCOUNT(FactCustomerSales[DimDivision.Name]) * 10,
        0  -- Default value if none of the conditions match
    )
)

##to calculate prediction of the sales :
  
## First of all i define mesures [Worked Days]
 
  3) Відпрацьовані дні [Worked Days] = 
      DATEDIFF(DATE(YEAR(TODAY()), MONTH(TODAY()), 1), TODAY(), DAY) + 1

##and then calculate main measure
  
  Прогнозне виконання для менеджерів (prediction of the managers' sales) = 
    AVRAGEX(
        VALUES(FactCustomerSales[Group]),  -- Select unique salespeople in a division
        VAR Sales = [Current Performance for Managers]  -- Total OPPO sales for each division
        VAR WorkDays = [Worked Days]  -- Worked Days for each division
        RETURN Sales / WorkDays * 30  -- Forecasted Performance for each division
)

  4) Рейтинг для підрозділів (Ranking for division) = 
    IF(
    ISINSCOPE(FactCustomerSales[DimDivision.Name]),
    RANKX(
        ALLSELECTED(FactCustomerSales[DimDivision.Name], FactCustomerSales[Група]),
        [Поточне виконання для підрозділу],
        ,
        DESC,
        Dense
        )
      )

5) Sales plan for group =
    SUMX(
        VALUES(FactCustomerSales[Group]),
        SWITCH(
            TRUE(),
            FactCustomerSales[Group] = "GROUP 1", DISTINCTCOUNT(FactCustomerSales[DimDivision.Name]) * 20,
            FactCustomerSales[Group] = "GROUP 2", DISTINCTCOUNT(FactCustomerSales[DimDivision.Name]) * 15,
            FactCustomerSales[Group] = "GROUP 3", DISTINCTCOUNT(FactCustomerSales[DimDivision.Name]) * 10,
            0  -- Default value if none of the conditions match
              )
          )  

## On the second tab I need to calculate all the same measure but for managers in the comtext of group and division in this groups
## So
  1)Поточне виконання для менеджерів = 
    AVERAGEX(
    VALUES(FactCustomerSales[Група]),  -- Вибір унікальних підрозділів в межах групи
    VAR Sales = [Загальні продажі OPPO]  -- Загальні продажі OPPO для кожного продавця
    VAR Target = [Прохідний таргет]  -- Прохідний таргет для кожного продавця
    RETURN Sales / Target  -- Поточне виконання для кожного продавця
    )

2) Прогнозне виконання для менеджерів = 
AVERAGEX(
    VALUES(FactCustomerSales[Група]),  -- Вибір унікальних продавців у підрозділі
    VAR Sales = [Поточне виконання для менеджерів]  -- Загальні продажі OPPO для кожного підрозділу
    VAR WorkDays = [Відпрацьовані дні]  -- Відпрацьовані дні для кожного підрозділу
    RETURN Sales / WorkDays * 30  -- Прогнозне виконання для кожного підрозділу
)

  3) Rating for sellers =
  IF(
    ISINSCOPE(FactCustomerSales[DimDivision.Name]),  -- Check if the division is in the context
    RANKX(
        ALLSELECTED(FactCustomerSales[DimUsers.Name], FactCustomerSales[DimDivision.Name]),  -- Need to compare between all products
        [Current execution for managers],  -- Measure or column by which we determine the rating (for example, total sales)
        ,  -- No additional value for sorting (if necessary, you can add another value)
        DESC,  -- Sort in descending order (by higher sales)
        Dense  -- Rating with "dense" counting (the same values ​​receive the same rating)
        ),
        BLANK()  -- If the context is for a group or Total, return empty value
        )
