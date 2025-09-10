# SharePoint Best Practices

## Overview
SharePoint is Microsoft's collaboration platform that integrates with Microsoft Office. It's primarily used for document management, storage, intranet portals, and team collaboration.

## Documentation
- [Official SharePoint Documentation](https://docs.microsoft.com/en-us/sharepoint)
- [SharePoint Developer Documentation](https://docs.microsoft.com/en-us/sharepoint/dev)
- [SharePoint Framework (SPFx)](https://docs.microsoft.com/en-us/sharepoint/dev/spfx/sharepoint-framework-overview)
- [SharePoint REST API](https://docs.microsoft.com/en-us/sharepoint/dev/sp-add-ins/get-to-know-the-sharepoint-rest-service)
- [PnP SharePoint](https://pnp.github.io)

## Architecture Overview

### SharePoint Components
```
SharePoint Online/On-Premises
├── Site Collections
│   ├── Sites (Webs)
│   │   ├── Lists
│   │   ├── Libraries
│   │   ├── Pages
│   │   └── Apps
│   ├── Content Types
│   ├── Site Columns
│   └── Features
├── Term Store (Managed Metadata)
├── Search Service
├── User Profile Service
└── Workflow Services
```

## SharePoint Framework (SPFx) Development

### Project Structure

```
spfx-webpart/
├── config/
│   ├── config.json
│   ├── package-solution.json
│   ├── serve.json
│   └── write-manifests.json
├── src/
│   ├── webparts/
│   │   └── helloWorld/
│   │       ├── components/
│   │       │   ├── HelloWorld.tsx
│   │       │   ├── HelloWorld.module.scss
│   │       │   └── IHelloWorldProps.ts
│   │       ├── loc/
│   │       ├── HelloWorldWebPart.manifest.json
│   │       └── HelloWorldWebPart.ts
│   └── extensions/
├── teams/
├── sharepoint/
│   └── assets/
├── gulpfile.js
├── package.json
├── tsconfig.json
└── tslint.json
```

### SPFx Web Part Development

```typescript
// HelloWorldWebPart.ts
import { Version } from '@microsoft/sp-core-library';
import {
  IPropertyPaneConfiguration,
  PropertyPaneTextField,
  PropertyPaneCheckbox,
  PropertyPaneDropdown
} from '@microsoft/sp-property-pane';
import { BaseClientSideWebPart } from '@microsoft/sp-webpart-base';
import { SPHttpClient, SPHttpClientResponse } from '@microsoft/sp-http';

import * as strings from 'HelloWorldWebPartStrings';
import HelloWorld from './components/HelloWorld';
import { IHelloWorldProps } from './components/IHelloWorldProps';

export interface IHelloWorldWebPartProps {
  description: string;
  listName: string;
  showItems: boolean;
  maxItems: number;
}

export default class HelloWorldWebPart extends BaseClientSideWebPart<IHelloWorldWebPartProps> {
  
  private _lists: any[] = [];

  public render(): void {
    const element: React.ReactElement<IHelloWorldProps> = React.createElement(
      HelloWorld,
      {
        description: this.properties.description,
        context: this.context,
        listName: this.properties.listName,
        showItems: this.properties.showItems,
        maxItems: this.properties.maxItems,
        onConfigure: () => {
          this.context.propertyPane.open();
        }
      }
    );

    ReactDom.render(element, this.domElement);
  }

  protected onInit(): Promise<void> {
    return super.onInit().then(() => {
      // Initialize services
      this._loadLists();
    });
  }

  private _loadLists(): Promise<void> {
    return this.context.spHttpClient
      .get(
        `${this.context.pageContext.web.absoluteUrl}/_api/web/lists?$select=Title,Id`,
        SPHttpClient.configurations.v1
      )
      .then((response: SPHttpClientResponse) => response.json())
      .then((data) => {
        this._lists = data.value;
      });
  }

  protected onDispose(): void {
    ReactDom.unmountComponentAtNode(this.domElement);
  }

  protected get dataVersion(): Version {
    return Version.parse('1.0');
  }

  protected getPropertyPaneConfiguration(): IPropertyPaneConfiguration {
    return {
      pages: [
        {
          header: {
            description: strings.PropertyPaneDescription
          },
          groups: [
            {
              groupName: strings.BasicGroupName,
              groupFields: [
                PropertyPaneTextField('description', {
                  label: strings.DescriptionFieldLabel
                }),
                PropertyPaneDropdown('listName', {
                  label: 'Select List',
                  options: this._lists.map(list => ({
                    key: list.Title,
                    text: list.Title
                  }))
                }),
                PropertyPaneCheckbox('showItems', {
                  text: 'Show list items'
                }),
                PropertyPaneTextField('maxItems', {
                  label: 'Maximum items to show'
                })
              ]
            }
          ]
        }
      ]
    };
  }
}
```

### React Component

```typescript
// components/HelloWorld.tsx
import * as React from 'react';
import styles from './HelloWorld.module.scss';
import { IHelloWorldProps } from './IHelloWorldProps';
import { SPHttpClient } from '@microsoft/sp-http';
import {
  PrimaryButton,
  DefaultButton,
  Stack,
  MessageBar,
  MessageBarType,
  Spinner,
  DetailsList,
  IColumn
} from '@fluentui/react';

interface IHelloWorldState {
  items: any[];
  loading: boolean;
  error: string;
}

export default class HelloWorld extends React.Component<IHelloWorldProps, IHelloWorldState> {
  
  constructor(props: IHelloWorldProps) {
    super(props);
    
    this.state = {
      items: [],
      loading: false,
      error: ''
    };
  }

  public componentDidMount(): void {
    if (this.props.showItems && this.props.listName) {
      this._loadItems();
    }
  }

  public componentDidUpdate(prevProps: IHelloWorldProps): void {
    if (prevProps.listName !== this.props.listName && this.props.listName) {
      this._loadItems();
    }
  }

  private _loadItems = async (): Promise<void> => {
    this.setState({ loading: true, error: '' });

    try {
      const response = await this.props.context.spHttpClient.get(
        `${this.props.context.pageContext.web.absoluteUrl}/_api/web/lists/getbytitle('${this.props.listName}')/items?$top=${this.props.maxItems}`,
        SPHttpClient.configurations.v1
      );

      if (!response.ok) {
        throw new Error(`Error loading items: ${response.statusText}`);
      }

      const data = await response.json();
      this.setState({ items: data.value, loading: false });
    } catch (error) {
      this.setState({ 
        error: error.message, 
        loading: false 
      });
    }
  }

  private _columns: IColumn[] = [
    {
      key: 'title',
      name: 'Title',
      fieldName: 'Title',
      minWidth: 100,
      maxWidth: 200,
      isResizable: true
    },
    {
      key: 'created',
      name: 'Created',
      fieldName: 'Created',
      minWidth: 100,
      maxWidth: 150,
      onRender: (item) => {
        return new Date(item.Created).toLocaleDateString();
      }
    }
  ];

  public render(): React.ReactElement<IHelloWorldProps> {
    const { description, listName, showItems } = this.props;
    const { items, loading, error } = this.state;

    return (
      <div className={styles.helloWorld}>
        <div className={styles.container}>
          <Stack tokens={{ childrenGap: 15 }}>
            <h2>Welcome to SharePoint Framework!</h2>
            <p>{description}</p>
            
            {!listName && (
              <MessageBar messageBarType={MessageBarType.info}>
                Please configure the web part to select a list.
              </MessageBar>
            )}

            {error && (
              <MessageBar messageBarType={MessageBarType.error}>
                {error}
              </MessageBar>
            )}

            {loading && <Spinner label="Loading items..." />}

            {showItems && items.length > 0 && (
              <DetailsList
                items={items}
                columns={this._columns}
                setKey="set"
                layoutMode={1}
                selectionMode={0}
                isHeaderVisible={true}
              />
            )}

            <Stack horizontal tokens={{ childrenGap: 10 }}>
              <PrimaryButton 
                text="Refresh" 
                onClick={this._loadItems}
                disabled={!listName || loading}
              />
              <DefaultButton 
                text="Configure" 
                onClick={this.props.onConfigure}
              />
            </Stack>
          </Stack>
        </div>
      </div>
    );
  }
}
```

## SharePoint REST API

### Authentication and Headers

```typescript
// Get request digest for POST operations
async function getRequestDigest(siteUrl: string): Promise<string> {
  const response = await fetch(`${siteUrl}/_api/contextinfo`, {
    method: 'POST',
    headers: {
      'Accept': 'application/json;odata=verbose',
      'Content-Type': 'application/json;odata=verbose'
    },
    credentials: 'same-origin'
  });
  
  const data = await response.json();
  return data.d.GetContextWebInformation.FormDigestValue;
}

// Common headers for SharePoint REST API
const getHeaders = (requestDigest?: string) => {
  const headers: HeadersInit = {
    'Accept': 'application/json;odata=nometadata',
    'Content-Type': 'application/json;odata=nometadata'
  };
  
  if (requestDigest) {
    headers['X-RequestDigest'] = requestDigest;
  }
  
  return headers;
};
```

### CRUD Operations

```typescript
class SharePointService {
  private siteUrl: string;
  
  constructor(siteUrl: string) {
    this.siteUrl = siteUrl;
  }

  // Get list items
  async getListItems(listName: string, select?: string, filter?: string, top: number = 100): Promise<any[]> {
    let url = `${this.siteUrl}/_api/web/lists/getbytitle('${listName}')/items?$top=${top}`;
    
    if (select) url += `&$select=${select}`;
    if (filter) url += `&$filter=${filter}`;
    
    const response = await fetch(url, {
      headers: getHeaders(),
      credentials: 'same-origin'
    });
    
    const data = await response.json();
    return data.value;
  }

  // Create list item
  async createListItem(listName: string, item: any): Promise<any> {
    const digest = await getRequestDigest(this.siteUrl);
    
    // Get list item entity type
    const listResponse = await fetch(
      `${this.siteUrl}/_api/web/lists/getbytitle('${listName}')?$select=ListItemEntityTypeFullName`,
      { headers: getHeaders(), credentials: 'same-origin' }
    );
    const listData = await listResponse.json();
    
    const itemData = {
      ...item,
      __metadata: { type: listData.ListItemEntityTypeFullName }
    };
    
    const response = await fetch(
      `${this.siteUrl}/_api/web/lists/getbytitle('${listName}')/items`,
      {
        method: 'POST',
        headers: {
          ...getHeaders(digest),
          'IF-MATCH': '*'
        },
        body: JSON.stringify(itemData),
        credentials: 'same-origin'
      }
    );
    
    return await response.json();
  }

  // Update list item
  async updateListItem(listName: string, itemId: number, updates: any): Promise<void> {
    const digest = await getRequestDigest(this.siteUrl);
    
    // Get list item entity type
    const listResponse = await fetch(
      `${this.siteUrl}/_api/web/lists/getbytitle('${listName}')?$select=ListItemEntityTypeFullName`,
      { headers: getHeaders(), credentials: 'same-origin' }
    );
    const listData = await listResponse.json();
    
    const itemData = {
      ...updates,
      __metadata: { type: listData.ListItemEntityTypeFullName }
    };
    
    await fetch(
      `${this.siteUrl}/_api/web/lists/getbytitle('${listName}')/items(${itemId})`,
      {
        method: 'POST',
        headers: {
          ...getHeaders(digest),
          'IF-MATCH': '*',
          'X-HTTP-Method': 'MERGE'
        },
        body: JSON.stringify(itemData),
        credentials: 'same-origin'
      }
    );
  }

  // Delete list item
  async deleteListItem(listName: string, itemId: number): Promise<void> {
    const digest = await getRequestDigest(this.siteUrl);
    
    await fetch(
      `${this.siteUrl}/_api/web/lists/getbytitle('${listName}')/items(${itemId})`,
      {
        method: 'POST',
        headers: {
          ...getHeaders(digest),
          'IF-MATCH': '*',
          'X-HTTP-Method': 'DELETE'
        },
        credentials: 'same-origin'
      }
    );
  }

  // Upload file to document library
  async uploadFile(libraryName: string, fileName: string, fileContent: ArrayBuffer): Promise<any> {
    const digest = await getRequestDigest(this.siteUrl);
    
    const response = await fetch(
      `${this.siteUrl}/_api/web/lists/getbytitle('${libraryName}')/RootFolder/Files/add(url='${fileName}',overwrite=true)`,
      {
        method: 'POST',
        headers: {
          'X-RequestDigest': digest,
          'Accept': 'application/json;odata=nometadata'
        },
        body: fileContent,
        credentials: 'same-origin'
      }
    );
    
    return await response.json();
  }
}
```

## PnP JS Library

### Installation and Setup

```typescript
// Installation
// npm install @pnp/sp @pnp/logging @pnp/common

import { sp } from "@pnp/sp/presets/all";
import { Web } from "@pnp/sp/webs";
import "@pnp/sp/lists";
import "@pnp/sp/items";
import "@pnp/sp/files";
import "@pnp/sp/folders";

// Setup in SPFx
export default class PnPWebPart extends BaseClientSideWebPart<IPnPWebPartProps> {
  
  protected async onInit(): Promise<void> {
    await super.onInit();
    
    // Initialize PnP JS
    sp.setup({
      spfxContext: this.context
    });
  }
}

// Setup outside SPFx
sp.setup({
  sp: {
    headers: {
      Accept: "application/json;odata=verbose",
    },
    baseUrl: "https://tenant.sharepoint.com/sites/site"
  }
});
```

### PnP JS Operations

```typescript
import { sp } from "@pnp/sp/presets/all";
import { IItemAddResult, IItemUpdateResult } from "@pnp/sp/items";

class PnPService {
  
  // Get all lists
  async getLists(): Promise<any[]> {
    return await sp.web.lists
      .select("Title", "Id", "ItemCount")
      .filter("Hidden eq false")
      .get();
  }

  // Get list items with advanced query
  async getItems(listName: string): Promise<any[]> {
    return await sp.web.lists
      .getByTitle(listName)
      .items
      .select("Title", "Id", "Created", "Modified")
      .filter("Title ne null")
      .top(50)
      .orderBy("Modified", false)
      .get();
  }

  // Get items with expand
  async getItemsWithLookup(listName: string): Promise<any[]> {
    return await sp.web.lists
      .getByTitle(listName)
      .items
      .select("Title", "Id", "Author/Title", "Author/Email")
      .expand("Author")
      .get();
  }

  // Create item
  async createItem(listName: string, item: any): Promise<IItemAddResult> {
    return await sp.web.lists
      .getByTitle(listName)
      .items
      .add(item);
  }

  // Update item
  async updateItem(listName: string, itemId: number, updates: any): Promise<IItemUpdateResult> {
    return await sp.web.lists
      .getByTitle(listName)
      .items
      .getById(itemId)
      .update(updates);
  }

  // Delete item
  async deleteItem(listName: string, itemId: number): Promise<void> {
    await sp.web.lists
      .getByTitle(listName)
      .items
      .getById(itemId)
      .delete();
  }

  // Batch operations
  async batchOperations(listName: string, items: any[]): Promise<void> {
    const batch = sp.web.createBatch();
    const list = sp.web.lists.getByTitle(listName);
    
    for (const item of items) {
      list.items.inBatch(batch).add(item);
    }
    
    await batch.execute();
  }

  // Upload file
  async uploadFile(libraryName: string, fileName: string, fileContent: File): Promise<any> {
    const result = await sp.web
      .getFolderByServerRelativeUrl(`/sites/site/${libraryName}`)
      .files
      .add(fileName, fileContent, true);
      
    // Update file metadata
    const item = await result.file.getItem();
    await item.update({
      Title: fileName,
      Description: "Uploaded via PnP JS"
    });
    
    return result;
  }

  // Search
  async search(query: string): Promise<any> {
    const results = await sp.search({
      Querytext: query,
      RowLimit: 10,
      SelectProperties: ["Title", "Path", "Description", "Author"],
      EnableInterleaving: true
    });
    
    return results.PrimarySearchResults;
  }

  // Get user profile
  async getUserProfile(email: string): Promise<any> {
    return await sp.profiles.getPropertiesFor(email);
  }

  // Create modern page
  async createPage(title: string, content: string): Promise<void> {
    const page = await sp.web.addClientsidePage(title);
    
    // Add text web part
    page.addSection();
    page.sections[0].addControl({
      controlType: 4,
      id: "1",
      innerHTML: content
    });
    
    await page.save();
  }
}
```

## SharePoint Patterns

### Permission Management

```typescript
import { sp } from "@pnp/sp/presets/all";
import { PermissionKind } from "@pnp/sp/security";

class PermissionService {
  
  // Check user permissions
  async checkPermissions(listName: string, permissionKind: PermissionKind): Promise<boolean> {
    const perms = await sp.web.lists
      .getByTitle(listName)
      .getCurrentUserEffectivePermissions();
      
    return sp.web.lists
      .getByTitle(listName)
      .hasPermissions(perms, permissionKind);
  }

  // Break role inheritance
  async breakInheritance(listName: string, itemId: number): Promise<void> {
    await sp.web.lists
      .getByTitle(listName)
      .items
      .getById(itemId)
      .breakRoleInheritance(false, true);
  }

  // Grant permissions
  async grantPermissions(listName: string, itemId: number, userEmail: string, roleDefId: number): Promise<void> {
    const user = await sp.web.ensureUser(userEmail);
    
    await sp.web.lists
      .getByTitle(listName)
      .items
      .getById(itemId)
      .roleAssignments
      .add(user.data.Id, roleDefId);
  }

  // Remove permissions
  async removePermissions(listName: string, itemId: number, principalId: number): Promise<void> {
    await sp.web.lists
      .getByTitle(listName)
      .items
      .getById(itemId)
      .roleAssignments
      .remove(principalId);
  }
}
```

### Taxonomy (Term Store)

```typescript
import { sp } from "@pnp/sp/presets/all";
import { taxonomy, ITermStore, ITermSet, ITerm } from "@pnp/sp-taxonomy";

class TaxonomyService {
  private termStore: ITermStore;

  async init(): Promise<void> {
    const stores = await taxonomy.termStores.get();
    this.termStore = taxonomy.termStores.getById(stores[0].Id);
  }

  async getTermSet(termSetId: string): Promise<ITermSet> {
    return await this.termStore.getTermSetById(termSetId);
  }

  async getTerms(termSetId: string): Promise<ITerm[]> {
    const termSet = await this.getTermSet(termSetId);
    return await termSet.terms.get();
  }

  async createTerm(termSetId: string, name: string, lcid: number = 1033): Promise<ITerm> {
    const termSet = await this.getTermSet(termSetId);
    return await termSet.addTerm(name, lcid);
  }

  async updateFieldWithTerm(listName: string, itemId: number, fieldName: string, termId: string): Promise<void> {
    const term = await this.termStore.getTermById(termId).get();
    
    await sp.web.lists
      .getByTitle(listName)
      .items
      .getById(itemId)
      .update({
        [fieldName]: {
          __metadata: { type: "SP.Taxonomy.TaxonomyFieldValue" },
          Label: term.Name,
          TermGuid: term.Id,
          WssId: -1
        }
      });
  }
}
```

### Custom Actions and Extensions

```typescript
// Site custom action
async function addCustomAction(): Promise<void> {
  await sp.web.userCustomActions.add({
    Title: "Custom Action",
    Description: "My custom action",
    Location: "ScriptLink",
    ScriptSrc: "~site/SiteAssets/custom.js",
    Sequence: 100
  });
}

// List custom action
async function addListCustomAction(listName: string): Promise<void> {
  await sp.web.lists
    .getByTitle(listName)
    .userCustomActions
    .add({
      Title: "Custom List Action",
      Location: "EditControlBlock",
      Url: "javascript:alert('Custom action clicked');",
      Sequence: 100,
      RegistrationType: 1,
      RegistrationId: "101" // Document library
    });
}
```

## Modern SharePoint Customizations

### Application Customizers

```typescript
import { BaseApplicationCustomizer } from '@microsoft/sp-application-base';
import { PlaceholderContent, PlaceholderName } from '@microsoft/sp-application-base';

export default class HeaderFooterApplicationCustomizer extends BaseApplicationCustomizer<{}> {
  private _topPlaceholder: PlaceholderContent | undefined;
  private _bottomPlaceholder: PlaceholderContent | undefined;

  public onInit(): Promise<void> {
    this.context.placeholderProvider.changedEvent.add(this, this._renderPlaceHolders);
    this._renderPlaceHolders();
    return Promise.resolve();
  }

  private _renderPlaceHolders(): void {
    if (!this._topPlaceholder) {
      this._topPlaceholder = this.context.placeholderProvider.tryCreateContent(
        PlaceholderName.Top,
        { onDispose: this._onDispose }
      );

      if (this._topPlaceholder) {
        this._topPlaceholder.domElement.innerHTML = `
          <div style="background-color: #1a1a2e; color: white; padding: 10px;">
            Custom Header
          </div>
        `;
      }
    }

    if (!this._bottomPlaceholder) {
      this._bottomPlaceholder = this.context.placeholderProvider.tryCreateContent(
        PlaceholderName.Bottom,
        { onDispose: this._onDispose }
      );

      if (this._bottomPlaceholder) {
        this._bottomPlaceholder.domElement.innerHTML = `
          <div style="background-color: #1a1a2e; color: white; padding: 10px; text-align: center;">
            © 2024 Company Name
          </div>
        `;
      }
    }
  }

  private _onDispose(): void {
    console.log('Disposed custom placeholders');
  }
}
```

## Performance Optimization

1. **Use selective queries** with `$select` to reduce payload
2. **Implement pagination** with `$top` and `$skip`
3. **Cache data** when appropriate using session/local storage
4. **Batch operations** to reduce HTTP requests
5. **Use CDN** for static assets
6. **Minimize REST calls** by combining queries
7. **Lazy load** components and data
8. **Index columns** used in queries
9. **Use CAML queries** for complex filtering
10. **Implement throttling** for user actions

## Security Best Practices

1. **Validate all input** on server and client side
2. **Use least privilege** principle for permissions
3. **Implement proper authentication** and authorization
4. **Sanitize HTML content** to prevent XSS
5. **Use HTTPS** for all communications
6. **Implement request validation** tokens
7. **Audit sensitive operations**
8. **Regular security reviews** of custom code
9. **Follow OWASP guidelines** for web applications
10. **Keep frameworks updated** to latest versions

## Common Pitfalls

1. **5000 item list view threshold** - Use indexed columns and CAML
2. **Lookup column limitations** - Maximum 12 per query
3. **REST API batch limitations** - 100 operations per batch
4. **URL length limitations** - 2000 characters for GET requests
5. **Concurrent update conflicts** - Implement proper error handling
6. **Permission inheritance** breaking at scale
7. **Search crawl delays** for new content
8. **Custom script restrictions** in modern sites
9. **Browser compatibility** issues with older versions
10. **Migration challenges** from classic to modern

## Useful Tools and Resources

- **SharePoint Designer** - Workflow and site customization (deprecated)
- **PnP PowerShell** - Automation and administration
- **SharePoint Migration Tool** - Content migration
- **SP Editor Chrome Extension** - Developer productivity
- **SharePoint Look Book** - Design inspiration
- **PnP Provisioning Engine** - Site templating
- **Graph Explorer** - Microsoft Graph API testing
- **SharePoint Patterns and Practices** - Community solutions