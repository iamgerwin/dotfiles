# SAPUI5/OpenUI5 Best Practices

Comprehensive guide for building enterprise-ready web applications using SAP's UI5 framework with modern JavaScript patterns.

## 📚 Official Documentation
- [SAPUI5 Documentation](https://sapui5.hana.ondemand.com/sdk/)
- [OpenUI5 Documentation](https://openui5.org/)
- [UI5 Tooling](https://sap.github.io/ui5-tooling/)
- [UI5 Best Practices](https://sapui5.hana.ondemand.com/sdk/#/topic/28fcd55b04654977b63dacbee0552712)

## 🏗️ Project Structure

```
ui5-project/
├── webapp/
│   ├── controller/
│   │   ├── BaseController.js      # Base controller
│   │   ├── Main.controller.js     # Main view controller
│   │   └── Detail.controller.js   # Detail view controller
│   ├── view/
│   │   ├── Main.view.xml          # XML views
│   │   ├── Detail.view.xml
│   │   └── App.view.xml
│   ├── model/
│   │   ├── models.js              # Model initialization
│   │   └── formatter.js           # Data formatters
│   ├── fragment/
│   │   └── Dialog.fragment.xml    # Reusable fragments
│   ├── css/
│   │   └── style.css              # Custom styles
│   ├── i18n/
│   │   ├── i18n.properties        # Internationalization
│   │   └── i18n_en.properties
│   ├── test/
│   │   ├── unit/
│   │   └── integration/
│   ├── Component.js               # Component definition
│   ├── manifest.json              # App descriptor
│   └── index.html                 # Entry point
├── ui5.yaml                       # UI5 tooling config
└── package.json                   # Dependencies
```

## 🎯 Core Best Practices

### 1. Component Architecture

```javascript
// Component.js
sap.ui.define([
    "sap/ui/core/UIComponent",
    "sap/ui/Device",
    "myapp/model/models"
], function (UIComponent, Device, models) {
    "use strict";

    return UIComponent.extend("myapp.Component", {
        metadata: {
            manifest: "json"
        },

        init: function () {
            // Call the base component's init function
            UIComponent.prototype.init.apply(this, arguments);

            // Enable routing
            this.getRouter().initialize();

            // Set the device model
            this.setModel(models.createDeviceModel(), "device");

            // Create global models
            this.setModel(models.createUserModel(), "user");
        },

        getContentDensityClass: function () {
            if (this._sContentDensityClass === undefined) {
                // Check whether FLP has already set the content density class
                if (jQuery(document.body).hasClass("sapUiSizeCozy") || 
                    jQuery(document.body).hasClass("sapUiSizeCompact")) {
                    this._sContentDensityClass = "";
                } else if (!Device.support.touch) {
                    this._sContentDensityClass = "sapUiSizeCompact";
                } else {
                    this._sContentDensityClass = "sapUiSizeCozy";
                }
            }
            return this._sContentDensityClass;
        }
    });
});
```

### 2. Base Controller Pattern

```javascript
// controller/BaseController.js
sap.ui.define([
    "sap/ui/core/mvc/Controller",
    "sap/ui/core/routing/History",
    "sap/ui/core/UIComponent",
    "sap/m/MessageToast"
], function (Controller, History, UIComponent, MessageToast) {
    "use strict";

    return Controller.extend("myapp.controller.BaseController", {
        
        /**
         * Convenience method for accessing the router in every controller
         * @returns {sap.ui.core.routing.Router} the router instance
         */
        getRouter: function () {
            return this.getOwnerComponent().getRouter();
        },

        /**
         * Convenience method for getting the view model by name
         * @param {string} sName the model name
         * @returns {sap.ui.model.Model} the model instance
         */
        getModel: function (sName) {
            return this.getView().getModel(sName);
        },

        /**
         * Convenience method for setting the view model
         * @param {sap.ui.model.Model} oModel the model instance
         * @param {string} sName the model name
         */
        setModel: function (oModel, sName) {
            return this.getView().setModel(oModel, sName);
        },

        /**
         * Navigation handler
         * @param {string} sRouteName route name
         * @param {object} mParameters route parameters
         */
        navTo: function (sRouteName, mParameters) {
            this.getRouter().navTo(sRouteName, mParameters);
        },

        /**
         * Navigation back handler
         */
        onNavBack: function () {
            var sPreviousHash = History.getInstance().getPreviousHash();

            if (sPreviousHash !== undefined) {
                window.history.go(-1);
            } else {
                this.getRouter().navTo("main", {}, true);
            }
        },

        /**
         * Show message toast
         * @param {string} sMessage message text
         */
        showMessageToast: function (sMessage) {
            MessageToast.show(sMessage, {
                duration: 3000,
                width: "15em"
            });
        },

        /**
         * Error handler
         * @param {object} oError error object
         */
        handleError: function (oError) {
            var sMessage = oError.message || "An error occurred";
            sap.m.MessageBox.error(sMessage);
        }
    });
});
```

### 3. View Controller Implementation

```javascript
// controller/Main.controller.js
sap.ui.define([
    "./BaseController",
    "sap/ui/model/json/JSONModel",
    "sap/ui/model/Filter",
    "sap/ui/model/FilterOperator",
    "myapp/model/formatter"
], function (BaseController, JSONModel, Filter, FilterOperator, formatter) {
    "use strict";

    return BaseController.extend("myapp.controller.Main", {
        formatter: formatter,

        onInit: function () {
            // Initialize view model
            this.oViewModel = new JSONModel({
                busy: false,
                delay: 0,
                itemCount: 0,
                searchQuery: ""
            });
            this.setModel(this.oViewModel, "view");

            // Get data binding
            this._oList = this.byId("list");
            this._oList.attachEventOnce("updateFinished", this._onListUpdateFinished, this);
        },

        onUpdateFinished: function (oEvent) {
            var sTitle = this.getResourceBundle().getText("masterTitleCount", [oEvent.getParameter("total")]);
            this.oViewModel.setProperty("/title", sTitle);
        },

        onSearch: function (oEvent) {
            var sQuery = oEvent.getParameter("newValue") || oEvent.getParameter("query");
            this._filterTable(sQuery);
        },

        onRefresh: function () {
            this._oList.getBinding("items").refresh();
        },

        onPress: function (oEvent) {
            var oItem = oEvent.getSource();
            var oContext = oItem.getBindingContext();
            var sObjectId = oContext.getProperty("ObjectID");
            
            this.navTo("detail", {
                objectId: sObjectId
            });
        },

        _filterTable: function (sQuery) {
            var aFilters = [];
            
            if (sQuery && sQuery.length > 0) {
                var oFilter = new Filter({
                    filters: [
                        new Filter("Name", FilterOperator.Contains, sQuery),
                        new Filter("Description", FilterOperator.Contains, sQuery)
                    ],
                    and: false
                });
                aFilters.push(oFilter);
            }

            var oList = this.byId("list");
            var oBinding = oList.getBinding("items");
            oBinding.filter(aFilters);
        },

        _onListUpdateFinished: function (oEvent) {
            var iTotal = oEvent.getParameter("total");
            this.oViewModel.setProperty("/itemCount", iTotal);
        }
    });
});
```

### 4. XML View Structure

```xml
<!-- view/Main.view.xml -->
<mvc:View
    controllerName="myapp.controller.Main"
    xmlns:mvc="sap.ui.core.mvc"
    xmlns:core="sap.ui.core"
    xmlns="sap.m">

    <Page id="page" title="{i18n>masterTitle}" class="sapUiResponsiveContentPadding">
        <content>
            <VBox class="sapUiMediumMargin">
                <!-- Search Bar -->
                <SearchField
                    id="searchField"
                    width="100%"
                    search="onSearch"
                    placeholder="{i18n>searchPlaceholder}"
                    value="{view>/searchQuery}"/>

                <!-- List -->
                <List
                    id="list"
                    items="{
                        path: '/Products',
                        sorter: {
                            path: 'Name',
                            descending: false
                        }
                    }"
                    mode="SingleSelect"
                    updateFinished="onUpdateFinished">

                    <StandardListItem
                        title="{Name}"
                        description="{Description}"
                        info="{parts: ['Price', 'Currency'], formatter: '.formatter.formatCurrency'}"
                        type="Active"
                        press="onPress"/>

                </List>
            </VBox>
        </content>
        
        <footer>
            <Toolbar>
                <ToolbarSpacer/>
                <Button text="{i18n>refresh}" icon="sap-icon://refresh" press="onRefresh"/>
            </Toolbar>
        </footer>
    </Page>
</mvc:View>
```

## 🛠️ Useful Libraries & Patterns

### Model Management
```javascript
// model/models.js
sap.ui.define([
    "sap/ui/model/json/JSONModel",
    "sap/ui/Device"
], function (JSONModel, Device) {
    "use strict";

    return {
        createDeviceModel: function () {
            var oModel = new JSONModel(Device);
            oModel.setDefaultBindingMode("OneWay");
            return oModel;
        },

        createUserModel: function () {
            var oModel = new JSONModel({
                name: "",
                role: "",
                preferences: {}
            });
            return oModel;
        }
    };
});
```

### Formatter Utilities
```javascript
// model/formatter.js
sap.ui.define([], function () {
    "use strict";

    return {
        /**
         * Format currency value
         * @param {number} sValue price value
         * @param {string} sCurrency currency code
         * @returns {string} formatted currency
         */
        formatCurrency: function (sValue, sCurrency) {
            if (!sValue) {
                return "";
            }
            
            var oCurrencyFormat = sap.ui.core.format.NumberFormat.getCurrencyInstance();
            return oCurrencyFormat.format(sValue, sCurrency);
        },

        /**
         * Format date
         * @param {Date} oDate date object
         * @returns {string} formatted date
         */
        formatDate: function (oDate) {
            if (!oDate) {
                return "";
            }

            var oDateFormat = sap.ui.core.format.DateFormat.getDateInstance({
                pattern: "dd.MM.yyyy"
            });
            return oDateFormat.format(oDate);
        },

        /**
         * Status state formatter
         * @param {string} sStatus status value
         * @returns {string} state value
         */
        statusState: function (sStatus) {
            switch (sStatus) {
                case "Active":
                    return "Success";
                case "Inactive":
                    return "Error";
                case "Pending":
                    return "Warning";
                default:
                    return "None";
            }
        }
    };
});
```

## ⚠️ Common Pitfalls to Avoid

### 1. Memory Leaks
```javascript
// ❌ Bad - Not destroying models/controls
onExit: function() {
    // Missing cleanup
}

// ✅ Good - Proper cleanup
onExit: function() {
    if (this._oDialog) {
        this._oDialog.destroy();
        this._oDialog = null;
    }
    
    if (this.oViewModel) {
        this.oViewModel.destroy();
    }
}
```

### 2. Inefficient Data Binding
```xml
<!-- ❌ Bad - Binding to large datasets without paging -->
<Table items="{/LargeDataSet}">

<!-- ✅ Good - Use growing list for large data -->
<Table items="{/LargeDataSet}" growing="true" growingThreshold="50">
```

### 3. Missing Error Handling
```javascript
// ❌ Bad - No error handling
this.getModel().read("/Products", {
    success: function(oData) {
        // Handle success
    }
});

// ✅ Good - Proper error handling
this.getModel().read("/Products", {
    success: function(oData) {
        // Handle success
    },
    error: function(oError) {
        this.handleError(oError);
    }.bind(this)
});
```

## 📊 Performance Optimization

### 1. Lazy Loading
```javascript
// Lazy load views
sap.ui.define([
    "sap/ui/core/mvc/Controller"
], function(Controller) {
    "use strict";

    return Controller.extend("myapp.controller.Base", {
        onOpenDialog: function() {
            if (!this._oDialog) {
                Fragment.load({
                    name: "myapp.fragment.Dialog",
                    controller: this
                }).then(function(oDialog) {
                    this._oDialog = oDialog;
                    this.getView().addDependent(this._oDialog);
                    this._oDialog.open();
                }.bind(this));
            } else {
                this._oDialog.open();
            }
        }
    });
});
```

### 2. Efficient OData Binding
```javascript
// Use $select and $expand
var oList = this.byId("list");
var oBinding = oList.getBinding("items");
oBinding.mParameters.$select = "ID,Name,Status";
oBinding.mParameters.$expand = "Category";
```

### 3. Client-Side Filtering
```javascript
// Use client-side filtering for small datasets
var oBinding = this.byId("table").getBinding("items");
oBinding.filter(aFilters, sap.ui.model.FilterType.Application);
```

## 🧪 Testing Strategies

### QUnit Tests
```javascript
// test/unit/controller/Main.controller.test.js
sap.ui.define([
    "myapp/controller/Main.controller",
    "sap/ui/core/mvc/Controller",
    "sap/ui/model/json/JSONModel"
], function(MainController, Controller, JSONModel) {
    "use strict";

    QUnit.module("Main Controller", {
        beforeEach: function() {
            this.oController = new MainController();
            this.oViewStub = {
                setModel: sinon.stub(),
                getModel: sinon.stub(),
                byId: sinon.stub()
            };
            sinon.stub(Controller.prototype, "getView").returns(this.oViewStub);
        },

        afterEach: function() {
            Controller.prototype.getView.restore();
        }
    });

    QUnit.test("Should initialize view model", function(assert) {
        // Act
        this.oController.onInit();

        // Assert
        assert.ok(this.oViewStub.setModel.calledOnce, "View model was set");
        var oModel = this.oViewStub.setModel.getCall(0).args[0];
        assert.ok(oModel instanceof JSONModel, "JSONModel was created");
    });
});
```

### OPA5 Integration Tests
```javascript
// test/integration/pages/Main.js
sap.ui.define([
    "sap/ui/test/Opa5",
    "sap/ui/test/actions/Press",
    "sap/ui/test/matchers/Properties"
], function(Opa5, Press, Properties) {
    "use strict";

    Opa5.createPageObjects({
        onTheMainPage: {
            actions: {
                iPressTheRefreshButton: function() {
                    return this.waitFor({
                        controlType: "sap.m.Button",
                        matchers: new Properties({ icon: "sap-icon://refresh" }),
                        actions: new Press(),
                        errorMessage: "Could not find refresh button"
                    });
                }
            },

            assertions: {
                iShouldSeeTheList: function() {
                    return this.waitFor({
                        id: "list",
                        success: function() {
                            Opa5.assert.ok(true, "List is visible");
                        },
                        errorMessage: "List was not found"
                    });
                }
            }
        }
    });
});
```

## 🚀 Build & Deployment

### UI5 Tooling Configuration
```yaml
# ui5.yaml
specVersion: '2.6'
metadata:
  name: myapp
type: application
resources:
  configuration:
    paths:
      webapp: "webapp"
builder:
  resources:
    excludes:
      - "/test/**"
      - "/localService/**"
server:
  customMiddleware:
    - name: fiori-tools-proxy
      afterMiddleware: compression
      configuration:
        ignoreCertError: true
        backend:
          - path: /sap
            url: http://localhost:8080
```

### Build Process
```json
{
  "scripts": {
    "start": "ui5 serve",
    "build": "ui5 build --clean-dest",
    "test": "npm run lint && npm run test:unit && npm run test:integration",
    "test:unit": "karma start karma.conf.js",
    "test:integration": "npm run build && npm run serve:dist & wait-on http://localhost:8080 && npm run test:opa",
    "lint": "eslint webapp/"
  }
}
```

## 📈 Advanced Patterns

### Fragment Management
```javascript
// Reusable dialog fragment
onOpenCreateDialog: function() {
    var oView = this.getView();
    
    if (!this.byId("createDialog")) {
        Fragment.load({
            id: oView.getId(),
            name: "myapp.fragment.CreateDialog",
            controller: this
        }).then(function (oDialog) {
            oView.addDependent(oDialog);
            oDialog.open();
        });
    } else {
        this.byId("createDialog").open();
    }
}
```

### Custom Controls
```javascript
// Custom control definition
sap.ui.define([
    "sap/ui/core/Control",
    "sap/m/Text"
], function(Control, Text) {
    "use strict";

    return Control.extend("myapp.control.StatusIndicator", {
        metadata: {
            properties: {
                status: { type: "string", defaultValue: "None" },
                text: { type: "string", defaultValue: "" }
            }
        },

        init: function() {
            this.addStyleClass("myCustomStatusIndicator");
        },

        renderer: {
            apiVersion: 2,
            render: function(oRM, oControl) {
                oRM.openStart("div", oControl);
                oRM.class("statusIndicator");
                oRM.class("status" + oControl.getStatus());
                oRM.openEnd();
                oRM.text(oControl.getText());
                oRM.close("div");
            }
        }
    });
});
```

## 🔒 Security Best Practices

### XSS Prevention
```javascript
// Always escape user input
var sUserInput = oEvent.getParameter("value");
var sEscapedInput = jQuery.sap.encodeHTML(sUserInput);
```

### CSRF Protection
```javascript
// OData model automatically handles CSRF tokens
var oModel = this.getModel();
oModel.setHeaders({
    "X-Requested-With": "XMLHttpRequest"
});
```

## 📋 Code Review Checklist

- [ ] Proper controller inheritance from BaseController
- [ ] Memory leak prevention (destroy objects)
- [ ] Internationalization (i18n) implemented
- [ ] Error handling in place
- [ ] Performance considerations addressed
- [ ] Proper data binding patterns used
- [ ] Security measures implemented
- [ ] Unit/integration tests written
- [ ] Code follows UI5 naming conventions

Remember: Build scalable, maintainable UI5 applications by following SAP's best practices, leveraging the framework's capabilities, and ensuring proper testing and security measures are in place.