public with sharing class TC_InventoryConformance extends TC_ExperienceCloud {
    /**
* getSuppliersForBrand Get a set of suppliers for Inventory Conformance,
* determined by the current context, for user types:
*   Brand Administrators & Brand Standard Users, a list of related
*   'Suppliers with Active Subscription's facilities.
* @return Set<Id>: A set of Ids for Supplier Accounts.
*/
    public Set<Id> getSuppliersForBrand(Id brandAccountId) {
        List<Brand_Supplier_Connection__c> bsc = [
            SELECT Id, Supplier_Account__c
            FROM Brand_Supplier_Connection__c
            WHERE
            Brand_Account__c = :brandAccountId
            AND Active__c = TRUE
            AND Status__c = 'Approved'
        ];
        Set<Id> suppliers = new Set<Id>();
        for (Brand_Supplier_Connection__c i : bsc) {
            suppliers.add(i.Supplier_Account__c);
        }
        return suppliers;
    }
    
    public Set<Id> getSuppliersSet() {
        return isBrandUser
            ? getSuppliersForBrand(user.Contact?.AccountId)
            : isSupplierAdminUser &&
                user.Contact?.Account?.ToxClear_Account_Type__c == 'Supplier'
                ? new Set<Id>{ user.Contact?.AccountId }
        : null;
    }
    
    public List<Account> getSuppliers() {
        Set<Id> suppliers = getSuppliersSet();
        return suppliers != null
            ? [SELECT Id,Country__c,Type_of_Supplier__c,Name FROM Account WHERE Id IN :suppliers]
            : null;
    }
    
    public List<Account> getFacilities(
        String filterBySupplier,
        Set<Id> suppliers,
        String location,
        String suppType 
    ) {
        // * As a Brand Administrator or Brand Standard User,
        //   I'm interested in all my supplier's active facilities.
        // * As a Supplier Administrator, I'm interested in all my active facilities.
        if (suppliers == null) {
            // * As a Supplier Standard User, I'm interested in this one main facility.
            return isSupplierStandardUser &&
                String.isNotBlank(user.Contact?.Main_Facility__c)
                ? [
                    SELECT Id, Name
                    FROM Account
                    WHERE
                    Id = :user.Contact.Main_Facility__c
                    AND Is_ToxClear_Account__c = TRUE
                    AND ToxClear_Account_Type__c = 'Facility'
                ]
                : new List<Account>();
        }
        // When filtered.
        if (
            isBrandUser &&
            String.isNotBlank(filterBySupplier) &&
            filterBySupplier != 'ALL' &&
            suppliers.contains(filterBySupplier)
        ) {
            suppliers = new Set<Id>{ filterBySupplier };
                }
        if(isBrandUser && String.isNotBlank(location) && (location != 'null' && location != 'All Locations' && location != 'All')){
            suppliers =  new Map<Id,Account>([
                SELECT Id,Country__c,Name
                FROM Account 
                WHERE 
                Country__c =: location
                AND ID IN:suppliers
            ]).KeySet();
        }
        
        if(isBrandUser && String.isNotBlank(suppType) && (suppType != 'null' && suppType != 'All Types' && suppType != 'All')){
            suppliers =  new Map<Id,Account>([
                SELECT Id,Country__c,Type_of_Supplier__c,Name
                FROM Account 
                WHERE 
                Type_of_Supplier__c =: suppType
                AND ID IN:suppliers
            ]).KeySet();
        } 
        
        return [
            SELECT Id, Name
            FROM Account
            WHERE
            ParentId IN :suppliers
            AND Is_ToxClear_Account__c = TRUE
            AND ToxClear_Account_Type__c = 'Facility'
            AND ToxClear_Subscription_Status__c = 'Active'
        ];
    }
    
    public List<Inventory__c> getInventories(
        Set<Id> facilities,
        Date startingFrom,
        Date until
    ) {
        return [
            SELECT
            Facility__c,
            Facility__r.Name,
            Facility__r.ParentId,
            Facility__r.Parent.Name,
            Inventory_Name__c,
            Inventory_Date__c
            FROM Inventory__c
            WHERE
            Facility__c IN :facilities
            AND Inventory_Date__c >= :startingFrom
            AND Inventory_Date__c < :until
            ORDER BY Facility__r.Name, Inventory_Date__c
        ];
    }
    
    /**
* getCounts returns an array of integers.
*           [0] is a count of conformant line items.
*           [1] is a count of non-conformant line items.
* CR-12 06.22 - Updates the logic of which chemical products are counted for conformance.
*  If the field Commodity_Chemical_Standard_Name__c  is populated 
*  then the line is excluded from calculation. 
* @param facilities (Set<Id>): A set of facilities to count conformance for.
* @param month (Integer): Which month?
*              0 = this month, -1 = last month, -2 = month before last.
*
* @return List<Integer>: Count for [ conformant, non-conformant ]
*/
    
    public static List<Inventory_Line_Item__c> getAllInditexCount(Date startOfMonth,Date startOfNextMonth,Set<Id> facilities) {
        List<Inventory_Line_Item__c> invListofInditexProducts = [SELECT Id,Inditex_Classification_for_Babies__c,Inditex_Classification_for_Child_Adult__c
                                                                 FROM Inventory_Line_Item__c 
                                                                 WHERE 
                                                                 Inventory__r.Inventory_Date__c >= :startOfMonth
                                                                 AND Inventory__r.Inventory_Date__c < :startOfNextMonth
                                                                 AND Inventory__r.Facility__c IN :facilities];
        
        return invListofInditexProducts;
    }
    
    public static List<Inventory_Line_Item__c> getAllInditexCountForBrand(Date startOfMonth,Date startOfNextMonth,Set<Id> facilities,String invType) {
        List<Inventory_Line_Item__c> invListofInditexProductsByInvType = [SELECT Id,Inditex_Classification_for_Babies__c,Inditex_Classification_for_Child_Adult__c
                                                                 FROM Inventory_Line_Item__c 
                                                                 WHERE 
                                                                 Inventory__r.Inventory_Date__c >= :startOfMonth
                                                                 AND Inventory__r.Inventory_Date__c < :startOfNextMonth
                                                                 AND Inventory__r.Facility__c IN :facilities
                                                                 AND recordType.developerName =: invType];
        
        return invListofInditexProductsByInvType;
    }
    
    public List<Integer> getCounts(Set<Id> facilities, Integer month, String invType, String confType, String classfType) {
        Date startOfMonth = Date.today()
            .toStartOfMonth()
            .addMonths(month == null ? 0 : month);
        Date startOfNextMonth = startOfMonth.addMonths(1);
        
        if(invType != null && invType != 'All Types' && invType != 'All') {
            if(confType == 'Inditex The List') {
                if(classfType == 'All Types' || classfType == 'All') {
                    List<Inventory_Line_Item__c> invListofInditexProductsList = TC_InventoryConformance.getAllInditexCountForBrand(startOfMonth,startOfNextMonth,facilities,invType);
                    
                    Integer countA = 0;
                    Integer countB = 0;
                    Integer countC = 0;
                    Integer nullCount = 0;
                    
                    for(Inventory_Line_Item__c inv: invListofInditexProductsList) {
                        if(inv.Inditex_Classification_for_Babies__c == 'A') {
                            countA++; 
                        }
                        if(inv.Inditex_Classification_for_Child_Adult__c == 'A') {
                            countA++; 
                        }
                        if(inv.Inditex_Classification_for_Babies__c == 'B') {
                            countB++; 
                        }
                        if(inv.Inditex_Classification_for_Child_Adult__c == 'B') {
                            countB++; 
                        }
                        if(inv.Inditex_Classification_for_Babies__c == 'C') {
                            countC++;  
                        }
                        if(inv.Inditex_Classification_for_Child_Adult__c == 'C') {
                            countC++; 
                        }
                        if(inv.Inditex_Classification_for_Babies__c == null) {
                            nullCount++; 
                        }
                        if(inv.Inditex_Classification_for_Child_Adult__c == null) {
                            nullCount++; 
                        }
                    }
                    return new List<Integer>{countA,countB,countC,nullCount}; 
                        }
                if(classfType == 'Babies') {
                    return new List<Integer>{
                        [
                            SELECT COUNT()
                            FROM Inventory_Line_Item__c
                            WHERE
                            Inventory__r.Inventory_Date__c >= :startOfMonth
                            AND Inventory__r.Inventory_Date__c < :startOfNextMonth
                            AND Inventory__r.Facility__c IN :facilities
                            AND Inditex_Classification_for_Babies__c = 'A'
                            AND recordType.developerName =: invType
                        ],
                            [
                                SELECT COUNT()
                                FROM Inventory_Line_Item__c
                                WHERE
                                Inventory__r.Inventory_Date__c >= :startOfMonth
                                AND Inventory__r.Inventory_Date__c < :startOfNextMonth
                                AND Inventory__r.Facility__c IN :facilities
                                AND Inditex_Classification_for_Babies__c = 'B'
                                AND recordType.developerName =: invType
                            ],
                            [
                                SELECT COUNT()
                                FROM Inventory_Line_Item__c
                                WHERE
                                Inventory__r.Inventory_Date__c >= :startOfMonth
                                AND Inventory__r.Inventory_Date__c < :startOfNextMonth
                                AND Inventory__r.Facility__c IN :facilities
                                AND Inditex_Classification_for_Babies__c = 'C'
                                AND recordType.developerName =: invType
                            ],
                            [
                                SELECT COUNT()
                                FROM Inventory_Line_Item__c
                                WHERE
                                Inventory__r.Inventory_Date__c >= :startOfMonth
                                AND Inventory__r.Inventory_Date__c < :startOfNextMonth
                                AND Inventory__r.Facility__c IN :facilities
                                AND Inditex_Classification_for_Babies__c = null
                                AND recordType.developerName =: invType
                            ]
                            };  
                                }
                if(classfType == 'Children & Adults') {
                    return new List<Integer>{
                        [
                            SELECT COUNT()
                            FROM Inventory_Line_Item__c
                            WHERE
                            Inventory__r.Inventory_Date__c >= :startOfMonth
                            AND Inventory__r.Inventory_Date__c < :startOfNextMonth
                            AND Inventory__r.Facility__c IN :facilities
                            AND Inditex_Classification_for_Child_Adult__c = 'A'
                            AND recordType.developerName =: invType
                        ],
                            [
                                SELECT COUNT()
                                FROM Inventory_Line_Item__c
                                WHERE
                                Inventory__r.Inventory_Date__c >= :startOfMonth
                                AND Inventory__r.Inventory_Date__c < :startOfNextMonth
                                AND Inventory__r.Facility__c IN :facilities
                                AND Inditex_Classification_for_Child_Adult__c = 'B'
                                AND recordType.developerName =: invType
                            ],
                            [
                                SELECT COUNT()
                                FROM Inventory_Line_Item__c
                                WHERE
                                Inventory__r.Inventory_Date__c >= :startOfMonth
                                AND Inventory__r.Inventory_Date__c < :startOfNextMonth
                                AND Inventory__r.Facility__c IN :facilities
                                AND Inditex_Classification_for_Child_Adult__c = 'C'
                                AND recordType.developerName =: invType
                            ],
                            [
                                SELECT COUNT()
                                FROM Inventory_Line_Item__c
                                WHERE
                                Inventory__r.Inventory_Date__c >= :startOfMonth
                                AND Inventory__r.Inventory_Date__c < :startOfNextMonth
                                AND Inventory__r.Facility__c IN :facilities
                                AND Inditex_Classification_for_Child_Adult__c = null
                                AND recordType.developerName =: invType
                            ]
                            };  
                                }
            }
            return new List<Integer>{
                [
                    SELECT COUNT()
                    FROM Inventory_Line_Item__c
                    WHERE
                    Inventory__r.Inventory_Date__c >= :startOfMonth
                    AND Inventory__r.Inventory_Date__c < :startOfNextMonth
                    AND Inventory__r.Facility__c IN :facilities
                    AND Conformant__c = TRUE
                    AND ZDHC_MRSL_v2_0__c = 'Level 3'
                    //AND Commodity_Chemical_Standard_Name__c = null
                    AND recordType.developerName =: invType
                ],
                    [
                        SELECT COUNT()
                        FROM Inventory_Line_Item__c
                        WHERE
                        Inventory__r.Inventory_Date__c >= :startOfMonth
                        AND Inventory__r.Inventory_Date__c < :startOfNextMonth
                        AND Inventory__r.Facility__c IN :facilities
                        AND Conformant__c = TRUE
                        AND ZDHC_MRSL_v2_0__c = 'Level 2'
                        //AND Commodity_Chemical_Standard_Name__c = null
                        AND recordType.developerName =: invType
                    ],
                    [
                        SELECT COUNT()
                        FROM Inventory_Line_Item__c
                        WHERE
                        Inventory__r.Inventory_Date__c >= :startOfMonth
                        AND Inventory__r.Inventory_Date__c < :startOfNextMonth
                        AND Inventory__r.Facility__c IN :facilities
                        AND Conformant__c = TRUE
                        AND ZDHC_MRSL_v2_0__c = 'Level 1'
                        //AND Commodity_Chemical_Standard_Name__c = null
                        AND recordType.developerName =: invType
                    ],
                    [
                        SELECT COUNT()
                        FROM Inventory_Line_Item__c
                        WHERE
                        Inventory__r.Inventory_Date__c >= :startOfMonth
                        AND Inventory__r.Inventory_Date__c < :startOfNextMonth
                        AND Inventory__r.Facility__c IN :facilities
                        AND Conformant__c = FALSE
                        //AND Commodity_Chemical_Standard_Name__c = null
                        AND recordType.developerName =: invType
                    ]
                    };
                        }
        
        if(confType == 'Inditex The List') {
            if(classfType == 'All Types' || classfType == 'All') {
                List<Inventory_Line_Item__c> invListofInditexProductsList = TC_InventoryConformance.getAllInditexCount(startOfMonth,startOfNextMonth,facilities);
                
                Integer countA = 0;
                Integer countB = 0;
                Integer countC = 0;
                Integer nullCount = 0;
                
                for(Inventory_Line_Item__c inv: invListofInditexProductsList) {
                    if(inv.Inditex_Classification_for_Babies__c == 'A') {
                        countA++; 
                    }
                    if(inv.Inditex_Classification_for_Child_Adult__c == 'A') {
                        countA++; 
                    }
                    if(inv.Inditex_Classification_for_Babies__c == 'B') {
                        countB++; 
                    }
                    if(inv.Inditex_Classification_for_Child_Adult__c == 'B') {
                        countB++; 
                    }
                    if(inv.Inditex_Classification_for_Babies__c == 'C') {
                        countC++;  
                    }
                    if(inv.Inditex_Classification_for_Child_Adult__c == 'C') {
                        countC++; 
                    }
                    if(inv.Inditex_Classification_for_Babies__c == null) {
                        nullCount++; 
                    }
                    if(inv.Inditex_Classification_for_Child_Adult__c == null) {
                        nullCount++; 
                    }
                }
                return new List<Integer>{countA,countB,countC,nullCount};  
                    }
            if(classfType == 'Babies') {
                return new List<Integer>{
                    [
                        SELECT COUNT()
                        FROM Inventory_Line_Item__c
                        WHERE
                        Inventory__r.Inventory_Date__c >= :startOfMonth
                        AND Inventory__r.Inventory_Date__c < :startOfNextMonth
                        AND Inventory__r.Facility__c IN :facilities
                        AND Inditex_Classification_for_Babies__c = 'A'
                    ],
                        [
                            SELECT COUNT()
                            FROM Inventory_Line_Item__c
                            WHERE
                            Inventory__r.Inventory_Date__c >= :startOfMonth
                            AND Inventory__r.Inventory_Date__c < :startOfNextMonth
                            AND Inventory__r.Facility__c IN :facilities
                            AND Inditex_Classification_for_Babies__c = 'B'
                        ],
                        [
                            SELECT COUNT()
                            FROM Inventory_Line_Item__c
                            WHERE
                            Inventory__r.Inventory_Date__c >= :startOfMonth
                            AND Inventory__r.Inventory_Date__c < :startOfNextMonth
                            AND Inventory__r.Facility__c IN :facilities
                            AND Inditex_Classification_for_Babies__c = 'C'
                        ],
                        [
                            SELECT COUNT()
                            FROM Inventory_Line_Item__c
                            WHERE
                            Inventory__r.Inventory_Date__c >= :startOfMonth
                            AND Inventory__r.Inventory_Date__c < :startOfNextMonth
                            AND Inventory__r.Facility__c IN :facilities
                            AND Inditex_Classification_for_Babies__c = null
                        ]
                        };  
                            }
            if(classfType == 'Children & Adults') {
                return new List<Integer>{
                    [
                        SELECT COUNT()
                        FROM Inventory_Line_Item__c
                        WHERE
                        Inventory__r.Inventory_Date__c >= :startOfMonth
                        AND Inventory__r.Inventory_Date__c < :startOfNextMonth
                        AND Inventory__r.Facility__c IN :facilities
                        AND Inditex_Classification_for_Child_Adult__c = 'A'
                    ],
                        [
                            SELECT COUNT()
                            FROM Inventory_Line_Item__c
                            WHERE
                            Inventory__r.Inventory_Date__c >= :startOfMonth
                            AND Inventory__r.Inventory_Date__c < :startOfNextMonth
                            AND Inventory__r.Facility__c IN :facilities
                            AND Inditex_Classification_for_Child_Adult__c = 'B'
                        ],
                        [
                            SELECT COUNT()
                            FROM Inventory_Line_Item__c
                            WHERE
                            Inventory__r.Inventory_Date__c >= :startOfMonth
                            AND Inventory__r.Inventory_Date__c < :startOfNextMonth
                            AND Inventory__r.Facility__c IN :facilities
                            AND Inditex_Classification_for_Child_Adult__c = 'C'
                        ],
                        [
                            SELECT COUNT()
                            FROM Inventory_Line_Item__c
                            WHERE
                            Inventory__r.Inventory_Date__c >= :startOfMonth
                            AND Inventory__r.Inventory_Date__c < :startOfNextMonth
                            AND Inventory__r.Facility__c IN :facilities
                            AND Inditex_Classification_for_Child_Adult__c = null
                        ]
                        };  
                            }
        }
        
        return new List<Integer>{
            [
                SELECT COUNT()
                FROM Inventory_Line_Item__c
                WHERE
                Inventory__r.Inventory_Date__c >= :startOfMonth
                AND Inventory__r.Inventory_Date__c < :startOfNextMonth
                AND Inventory__r.Facility__c IN :facilities
                AND Conformant__c = TRUE
                AND ZDHC_MRSL_v2_0__c = 'Level 3'
                //AND Commodity_Chemical_Standard_Name__c = null
            ],
                [
                    SELECT COUNT()
                    FROM Inventory_Line_Item__c
                    WHERE
                    Inventory__r.Inventory_Date__c >= :startOfMonth
                    AND Inventory__r.Inventory_Date__c < :startOfNextMonth
                    AND Inventory__r.Facility__c IN :facilities
                    AND Conformant__c = TRUE
                    AND ZDHC_MRSL_v2_0__c = 'Level 2'
                    //AND Commodity_Chemical_Standard_Name__c = null
                ],
                [
                    SELECT COUNT()
                    FROM Inventory_Line_Item__c
                    WHERE
                    Inventory__r.Inventory_Date__c >= :startOfMonth
                    AND Inventory__r.Inventory_Date__c < :startOfNextMonth
                    AND Inventory__r.Facility__c IN :facilities
                    AND Conformant__c = TRUE
                    AND ZDHC_MRSL_v2_0__c = 'Level 1'
                    //AND Commodity_Chemical_Standard_Name__c = null
                ],
                [
                    SELECT COUNT()
                    FROM Inventory_Line_Item__c
                    WHERE
                    Inventory__r.Inventory_Date__c >= :startOfMonth
                    AND Inventory__r.Inventory_Date__c < :startOfNextMonth
                    AND Inventory__r.Facility__c IN :facilities
                    AND Conformant__c = FALSE
                    //AND Commodity_Chemical_Standard_Name__c = null
                ]
                };
                    }
    
    /**
* getCounts returns an array of integers.
*           [0] is a count of conformant line items.
*           [1] is a count of non-conformant line items.
*
* @param accountId (String): The supplierId or facilityId to filter on, or 'ALL'.
* @param month (Integer): count conformance for month;
*              0 = this month, -1 = last month,
*              -2 = month before last, etc...
*
* @return List<Integer>: Count for [ conformant, non-conformant ]
*/
    public List<Integer> getCounts(String accountId, Integer month, String location,String suppType, String invType, String confType, String classfType) {
        // Supplier Users may look at individual facilities.
        Set<Id> facilities = isSupplierUser &&
            String.isNotBlank(accountId) &&
            accountId != 'ALL'
            ? new Set<Id>{ accountId } // Otherwise when 'ALL' or when accountId is for a supplier, gather the set of facilities.
        : new Map<Id, Account>(getFacilities(accountId, getSuppliersSet(), location, suppType))
            .keySet();
        if (facilities.size() > 0) {
            // When recordId is ALL or null discover available facilities.
            // Brand Administrators and Brand Standard Users see all their supplier's facilitiies.
            // Supplier Administrators see all their supplier's facilities.
            // Supplier Standard Users see only their facility.
            return getCounts(facilities, month, invType, confType, classfType);
        }
        // When the specified facility was not recognised.
        return new List<Integer>{ 0, 0, 0, 0 };
            }
}