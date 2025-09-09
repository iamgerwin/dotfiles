# Salesforce Lightning Best Practices

Comprehensive guide for building modern, responsive applications using Salesforce Lightning Platform and Lightning Web Components (LWC).

## 📚 Official Documentation
- [Salesforce Lightning Platform](https://developer.salesforce.com/docs/platform/lwc/guide/introduction.html)
- [Lightning Web Components](https://lwc.dev/)
- [Salesforce DX Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/)
- [Apex Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/)

## 🏗️ Project Structure

```
salesforce-project/
├── force-app/main/default/
│   ├── lwc/                        # Lightning Web Components
│   │   ├── accountList/
│   │   │   ├── accountList.html
│   │   │   ├── accountList.js
│   │   │   ├── accountList.js-meta.xml
│   │   │   └── accountList.css
│   │   └── contactForm/
│   ├── classes/                    # Apex classes
│   │   ├── AccountController.cls
│   │   ├── AccountController.cls-meta.xml
│   │   ├── AccountService.cls
│   │   └── AccountServiceTest.cls
│   ├── objects/                    # Custom objects
│   ├── flows/                      # Process automation
│   ├── permissionsets/            # Permissions
│   └── staticresources/           # Static resources
├── config/
│   ├── project-scratch-def.json   # Scratch org definition
│   └── user-def.json             # User configuration
├── sfdx-project.json              # Project configuration
└── package.json                   # Dependencies
```

## 🎯 Core Best Practices

### 1. Lightning Web Components Structure

```javascript
// accountList.js
import { LightningElement, wire, track, api } from 'lwc';
import getAccounts from '@salesforce/apex/AccountController.getAccounts';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class AccountList extends LightningElement {
    @api recordId;
    @track accounts = [];
    @track isLoading = false;
    @track error;

    // Wire service to get data reactively
    @wire(getAccounts, { recordId: '$recordId' })
    wiredAccounts({ error, data }) {
        if (data) {
            this.accounts = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.accounts = [];
            this.showToast('Error', error.body.message, 'error');
        }
    }

    // Event handlers
    handleAccountSelect(event) {
        const accountId = event.detail.accountId;
        
        // Fire custom event
        this.dispatchEvent(new CustomEvent('accountselect', {
            detail: { accountId },
            bubbles: true,
            composed: true
        }));
    }

    // Utility methods
    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }
}
```

```html
<!-- accountList.html -->
<template>
    <lightning-card title="Account List" icon-name="standard:account">
        <div class="slds-m-around_medium">
            <template if:true={isLoading}>
                <lightning-spinner alternative-text="Loading..."></lightning-spinner>
            </template>
            
            <template if:true={accounts}>
                <lightning-datatable
                    data={accounts}
                    columns={columns}
                    key-field="Id"
                    onrowselection={handleAccountSelect}>
                </lightning-datatable>
            </template>
            
            <template if:true={error}>
                <div class="slds-text-color_error">
                    Error loading accounts: {error.body.message}
                </div>
            </template>
        </div>
    </lightning-card>
</template>
```

```css
/* accountList.css */
.account-card {
    background-color: var(--lwc-colorBackgroundAlt, #fafaf9);
    border-radius: var(--lwc-borderRadiusMedium, 0.25rem);
    padding: 1rem;
}

.highlight {
    background-color: var(--lwc-colorBackgroundHighlight, #f3f2f2);
}

/* Responsive design */
@media (max-width: 768px) {
    .account-card {
        padding: 0.5rem;
    }
}
```

### 2. Apex Controller Patterns

```apex
// AccountController.cls
public with sharing class AccountController {
    
    @AuraEnabled(cacheable=true)
    public static List<Account> getAccounts(Id recordId) {
        try {
            return [
                SELECT Id, Name, Type, Industry, Phone, Website
                FROM Account 
                WHERE Id = :recordId
                WITH SECURITY_ENFORCED
                ORDER BY Name
                LIMIT 50
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving accounts: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static String createAccount(Account accountRecord) {
        try {
            // Validate input
            if (accountRecord == null || String.isBlank(accountRecord.Name)) {
                throw new AuraHandledException('Account name is required');
            }
            
            // Security check
            if (!Schema.sObjectType.Account.isCreateable()) {
                throw new AuraHandledException('Insufficient permissions to create Account');
            }
            
            insert accountRecord;
            return accountRecord.Id;
            
        } catch (DmlException e) {
            throw new AuraHandledException('Error creating account: ' + e.getDmlMessage(0));
        }
    }
    
    @AuraEnabled
    public static void deleteAccount(Id accountId) {
        try {
            if (!Schema.sObjectType.Account.isDeletable()) {
                throw new AuraHandledException('Insufficient permissions to delete Account');
            }
            
            Account accountToDelete = new Account(Id = accountId);
            delete accountToDelete;
            
        } catch (DmlException e) {
            throw new AuraHandledException('Error deleting account: ' + e.getDmlMessage(0));
        }
    }
}
```

### 3. Service Layer Pattern

```apex
// AccountService.cls
public class AccountService {
    
    public static List<Account> getAccountsByIndustry(String industry) {
        validateIndustryInput(industry);
        
        return [
            SELECT Id, Name, Type, Industry, AnnualRevenue
            FROM Account 
            WHERE Industry = :industry 
            WITH SECURITY_ENFORCED
            ORDER BY AnnualRevenue DESC NULLS LAST
        ];
    }
    
    public static Account createAccountWithContacts(Account newAccount, List<Contact> contacts) {
        Savepoint sp = Database.setSavepoint();
        
        try {
            // Insert account
            insert newAccount;
            
            // Associate contacts with account
            for (Contact contact : contacts) {
                contact.AccountId = newAccount.Id;
            }
            
            insert contacts;
            
            return newAccount;
            
        } catch (Exception e) {
            Database.rollback(sp);
            throw new AccountServiceException('Failed to create account with contacts: ' + e.getMessage());
        }
    }
    
    private static void validateIndustryInput(String industry) {
        if (String.isBlank(industry)) {
            throw new AccountServiceException('Industry parameter cannot be null or empty');
        }
        
        // Get valid industry picklist values
        Schema.DescribeFieldResult fieldResult = Account.Industry.getDescribe();
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
        
        Set<String> validIndustries = new Set<String>();
        for (Schema.PicklistEntry entry : picklistValues) {
            validIndustries.add(entry.getValue());
        }
        
        if (!validIndustries.contains(industry)) {
            throw new AccountServiceException('Invalid industry value: ' + industry);
        }
    }
    
    // Custom exception
    public class AccountServiceException extends Exception {}
}
```

## 🛠️ Useful Libraries & Tools

### Lightning Web Components Libraries
```javascript
// Lightning Base Components
import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { RefreshEvent } from 'lightning/refresh';

// Lightning Message Service
import { MessageContext, publish, subscribe } from 'lightning/messageService';
import ACCOUNT_CHANNEL from '@salesforce/messageChannel/AccountChannel__c';
```

### Salesforce DX Commands
```bash
# Create project
sfdx force:project:create --projectname myproject

# Create scratch org
sfdx force:org:create --setdefaultusername --definitionfile config/project-scratch-def.json

# Deploy to org
sfdx force:source:push

# Run tests
sfdx force:apex:test:run --testlevel RunLocalTests

# Create package
sfdx force:package:create --name "My Package" --packagetype Unlocked
```

## ⚠️ Common Pitfalls to Avoid

### 1. Apex Governor Limits
```apex
// ❌ Bad - SOQL in loop
List<Contact> contacts = new List<Contact>();
for (Account account : accounts) {
    List<Contact> accountContacts = [SELECT Id FROM Contact WHERE AccountId = :account.Id];
    contacts.addAll(accountContacts);
}

// ✅ Good - Bulk query
Map<Id, Account> accountsWithContacts = new Map<Id, Account>(
    [SELECT Id, (SELECT Id FROM Contacts) FROM Account WHERE Id IN :accountIds]
);
```

### 2. Lightning Web Components Anti-patterns
```javascript
// ❌ Bad - Mutating props directly
export default class BadComponent extends LightningElement {
    @api recordData;
    
    handleChange() {
        this.recordData.Name = 'New Name'; // Don't mutate props
    }
}

// ✅ Good - Create new object
export default class GoodComponent extends LightningElement {
    @api recordData;
    
    handleChange() {
        const updatedRecord = { ...this.recordData, Name: 'New Name' };
        this.dispatchEvent(new CustomEvent('recordupdate', { 
            detail: updatedRecord 
        }));
    }
}
```

### 3. Security Issues
```apex
// ❌ Bad - No field-level security check
List<Account> accounts = [SELECT Id, Name, SSN__c FROM Account];

// ✅ Good - Use WITH SECURITY_ENFORCED or manual checks
List<Account> accounts = [SELECT Id, Name FROM Account WITH SECURITY_ENFORCED];

// Or manual field access check
if (!Schema.sObjectType.Account.fields.SSN__c.isAccessible()) {
    throw new AuraHandledException('Access denied to SSN field');
}
```

## 📊 Performance Optimization

### 1. Lightning Web Components
```javascript
// Use wire service for reactive data
@wire(getAccounts, { recordId: '$recordId' })
wiredAccounts;

// Implement caching for expensive operations
@wire(getExpensiveData, { param: '$parameter' })
cachedData;

// Use template directives efficiently
<template for:each={items} for:item="item" for:index="index">
    <div key={item.id}>{item.name}</div>
</template>
```

### 2. Apex Optimization
```apex
// Use selective queries
List<Account> accounts = [
    SELECT Id, Name 
    FROM Account 
    WHERE LastModifiedDate >= :Date.today().addDays(-30)
    AND Industry IN :selectedIndustries
    LIMIT 100
];

// Bulk processing
List<Account> accountsToUpdate = new List<Account>();
for (Account acc : accounts) {
    acc.Description = 'Updated';
    accountsToUpdate.add(acc);
}
update accountsToUpdate;
```

## 🧪 Testing Strategies

### Apex Test Classes
```apex
@isTest
public class AccountControllerTest {
    
    @TestSetup
    static void setupTestData() {
        List<Account> testAccounts = new List<Account>();
        for (Integer i = 0; i < 10; i++) {
            testAccounts.add(new Account(
                Name = 'Test Account ' + i,
                Industry = 'Technology'
            ));
        }
        insert testAccounts;
    }
    
    @isTest
    static void testGetAccounts() {
        // Given
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        // When
        Test.startTest();
        List<Account> result = AccountController.getAccounts(testAccount.Id);
        Test.stopTest();
        
        // Then
        System.assertNotEquals(null, result);
        System.assertEquals(1, result.size());
        System.assertEquals(testAccount.Id, result[0].Id);
    }
    
    @isTest
    static void testCreateAccountWithValidData() {
        // Given
        Account testAccount = new Account(Name = 'New Test Account');
        
        // When
        Test.startTest();
        String accountId = AccountController.createAccount(testAccount);
        Test.stopTest();
        
        // Then
        System.assertNotEquals(null, accountId);
        Account createdAccount = [SELECT Name FROM Account WHERE Id = :accountId];
        System.assertEquals('New Test Account', createdAccount.Name);
    }
    
    @isTest
    static void testCreateAccountWithInvalidData() {
        // Given
        Account invalidAccount = new Account(); // No name
        
        // When/Then
        Test.startTest();
        try {
            AccountController.createAccount(invalidAccount);
            System.assert(false, 'Expected exception was not thrown');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Account name is required'));
        }
        Test.stopTest();
    }
}
```

### Lightning Web Components Testing
```javascript
// accountList.test.js
import { createElement } from 'lwc';
import AccountList from 'c/accountList';
import getAccounts from '@salesforce/apex/AccountController.getAccounts';

// Mock Apex method
jest.mock(
    '@salesforce/apex/AccountController.getAccounts',
    () => ({ default: jest.fn() }),
    { virtual: true }
);

describe('c-account-list', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('renders account data correctly', async () => {
        // Given
        const mockAccounts = [
            { Id: '001xx000003DHPt', Name: 'Test Account 1' },
            { Id: '001xx000003DHPu', Name: 'Test Account 2' }
        ];
        getAccounts.mockResolvedValue(mockAccounts);

        // When
        const element = createElement('c-account-list', { is: AccountList });
        element.recordId = '001xx000003DHPt';
        document.body.appendChild(element);

        // Then
        await Promise.resolve(); // Wait for async operations
        
        const datatable = element.shadowRoot.querySelector('lightning-datatable');
        expect(datatable).toBeTruthy();
        expect(datatable.data).toEqual(mockAccounts);
    });
});
```

## 🚀 Deployment Best Practices

### Package Development
```json
// sfdx-project.json
{
    "packageDirectories": [
        {
            "path": "force-app",
            "default": true,
            "package": "MyPackage",
            "versionName": "ver 1.0",
            "versionNumber": "1.0.0.NEXT"
        }
    ],
    "name": "MyProject",
    "namespace": "mynamespace",
    "sfdcLoginUrl": "https://login.salesforce.com",
    "sourceApiVersion": "58.0"
}
```

### CI/CD Pipeline
```yaml
# GitHub Actions workflow
name: Salesforce CI/CD
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install Salesforce CLI
        run: npm install sfdx-cli --global
      - name: Authorize org
        run: |
          echo ${{ secrets.SFDX_AUTH_URL }} > ./auth.txt
          sfdx auth:sfdxurl:store -f ./auth.txt -a DevHub
      - name: Create scratch org
        run: sfdx force:org:create -f config/project-scratch-def.json -a ScratchOrg
      - name: Deploy source
        run: sfdx force:source:push -u ScratchOrg
      - name: Run tests
        run: sfdx force:apex:test:run -u ScratchOrg --testlevel RunLocalTests --outputdir ./tests/
```

## 📈 Advanced Patterns

### Lightning Message Service
```javascript
// Publisher component
import { publish, MessageContext } from 'lightning/messageService';
import ACCOUNT_CHANNEL from '@salesforce/messageChannel/AccountChannel__c';

export default class AccountPublisher extends LightningElement {
    @wire(MessageContext)
    messageContext;

    handleAccountUpdate(accountId) {
        const message = {
            accountId: accountId,
            action: 'refresh'
        };
        publish(this.messageContext, ACCOUNT_CHANNEL, message);
    }
}

// Subscriber component
import { subscribe, MessageContext } from 'lightning/messageService';
import ACCOUNT_CHANNEL from '@salesforce/messageChannel/AccountChannel__c';

export default class AccountSubscriber extends LightningElement {
    @wire(MessageContext)
    messageContext;

    connectedCallback() {
        this.subscribeToMessageChannel();
    }

    subscribeToMessageChannel() {
        this.subscription = subscribe(
            this.messageContext,
            ACCOUNT_CHANNEL,
            (message) => this.handleMessage(message)
        );
    }

    handleMessage(message) {
        if (message.action === 'refresh') {
            this.refreshData();
        }
    }
}
```

## 🔒 Security Best Practices

### Field-Level Security
```apex
// Always check field accessibility
if (!Schema.sObjectType.Account.fields.Revenue__c.isAccessible()) {
    throw new AuraHandledException('Access denied');
}

// Use WITH SECURITY_ENFORCED in SOQL
List<Account> accounts = [
    SELECT Id, Name FROM Account 
    WITH SECURITY_ENFORCED 
    LIMIT 100
];
```

### Input Validation
```javascript
// Validate input in Lightning Web Components
validateInput(inputValue) {
    const pattern = /^[a-zA-Z0-9\s]+$/;
    return pattern.test(inputValue);
}
```

Remember: Follow Salesforce security guidelines, optimize for governor limits, and maintain clean, testable code. Use Lightning Design System for consistent UI and leverage platform capabilities effectively.