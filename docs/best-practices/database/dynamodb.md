# DynamoDB Best Practices

## Overview

Amazon DynamoDB is a fully managed NoSQL database service that provides fast and predictable performance with seamless scalability. It's designed for applications that need consistent, single-digit millisecond latency at any scale, supporting both document and key-value data models.

## Official Documentation
- [DynamoDB Developer Guide](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/)
- [DynamoDB API Reference](https://docs.aws.amazon.com/amazondynamodb/latest/APIReference/)
- [DynamoDB Best Practices](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/best-practices.html)
- [NoSQL Workbench](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/workbench.html)

## Key Features
- **Serverless**: Fully managed with automatic scaling
- **Performance**: Single-digit millisecond response times
- **Scalability**: Handles 10 trillion requests per day
- **Global Tables**: Multi-region, multi-master replication
- **ACID Transactions**: Support for complex transactions
- **Streams**: Change data capture for real-time processing
- **On-Demand Backup**: Point-in-time recovery
- **Encryption**: At-rest and in-transit encryption
- **Fine-grained Access Control**: IAM integration

## Data Modeling

### Single Table Design
```javascript
// Single table design pattern
const TableSchema = {
  TableName: 'ApplicationData',
  KeySchema: [
    { AttributeName: 'PK', KeyType: 'HASH' },  // Partition key
    { AttributeName: 'SK', KeyType: 'RANGE' }  // Sort key
  ],
  AttributeDefinitions: [
    { AttributeName: 'PK', AttributeType: 'S' },
    { AttributeName: 'SK', AttributeType: 'S' },
    { AttributeName: 'GSI1PK', AttributeType: 'S' },
    { AttributeName: 'GSI1SK', AttributeType: 'S' },
    { AttributeName: 'GSI2PK', AttributeType: 'S' },
    { AttributeName: 'GSI2SK', AttributeType: 'S' }
  ],
  GlobalSecondaryIndexes: [
    {
      IndexName: 'GSI1',
      KeySchema: [
        { AttributeName: 'GSI1PK', KeyType: 'HASH' },
        { AttributeName: 'GSI1SK', KeyType: 'RANGE' }
      ],
      Projection: { ProjectionType: 'ALL' },
      ProvisionedThroughput: {
        ReadCapacityUnits: 5,
        WriteCapacityUnits: 5
      }
    },
    {
      IndexName: 'GSI2',
      KeySchema: [
        { AttributeName: 'GSI2PK', KeyType: 'HASH' },
        { AttributeName: 'GSI2SK', KeyType: 'RANGE' }
      ],
      Projection: { ProjectionType: 'ALL' },
      ProvisionedThroughput: {
        ReadCapacityUnits: 5,
        WriteCapacityUnits: 5
      }
    }
  ],
  BillingMode: 'PAY_PER_REQUEST',
  StreamSpecification: {
    StreamEnabled: true,
    StreamViewType: 'NEW_AND_OLD_IMAGES'
  },
  SSESpecification: {
    Enabled: true,
    SSEType: 'KMS'
  },
  Tags: [
    { Key: 'Environment', Value: 'Production' },
    { Key: 'Application', Value: 'MyApp' }
  ]
};

// Entity patterns in single table
const entities = {
  // User entity
  user: {
    PK: 'USER#<userId>',
    SK: 'USER#<userId>',
    GSI1PK: 'USER#EMAIL#<email>',
    GSI1SK: 'USER#<userId>'
  },
  
  // Order entity
  order: {
    PK: 'USER#<userId>',
    SK: 'ORDER#<orderId>',
    GSI1PK: 'ORDER#<orderId>',
    GSI1SK: 'ORDER#<orderId>',
    GSI2PK: 'ORDER#STATUS#<status>',
    GSI2SK: 'ORDER#<timestamp>'
  },
  
  // Product entity
  product: {
    PK: 'PRODUCT#<productId>',
    SK: 'PRODUCT#<productId>',
    GSI1PK: 'PRODUCT#CATEGORY#<category>',
    GSI1SK: 'PRODUCT#<productId>'
  },
  
  // Order items (one-to-many)
  orderItem: {
    PK: 'ORDER#<orderId>',
    SK: 'ITEM#<productId>',
    GSI1PK: 'PRODUCT#<productId>',
    GSI1SK: 'ORDER#<orderId>'
  }
};
```

### Access Patterns Implementation
```javascript
class DynamoDBRepository {
  constructor(documentClient, tableName) {
    this.db = documentClient;
    this.tableName = tableName;
  }

  // Create user
  async createUser(userId, userData) {
    const item = {
      PK: `USER#${userId}`,
      SK: `USER#${userId}`,
      GSI1PK: `USER#EMAIL#${userData.email}`,
      GSI1SK: `USER#${userId}`,
      type: 'USER',
      userId,
      ...userData,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };

    await this.db.put({
      TableName: this.tableName,
      Item: item,
      ConditionExpression: 'attribute_not_exists(PK)'
    }).promise();

    return item;
  }

  // Get user by ID
  async getUserById(userId) {
    const result = await this.db.get({
      TableName: this.tableName,
      Key: {
        PK: `USER#${userId}`,
        SK: `USER#${userId}`
      }
    }).promise();

    return result.Item;
  }

  // Get user by email (using GSI)
  async getUserByEmail(email) {
    const result = await this.db.query({
      TableName: this.tableName,
      IndexName: 'GSI1',
      KeyConditionExpression: 'GSI1PK = :pk',
      ExpressionAttributeValues: {
        ':pk': `USER#EMAIL#${email}`
      },
      Limit: 1
    }).promise();

    return result.Items[0];
  }

  // Create order with items (transaction)
  async createOrderWithItems(userId, orderId, items) {
    const timestamp = new Date().toISOString();
    
    // Prepare order item
    const order = {
      PK: `USER#${userId}`,
      SK: `ORDER#${orderId}`,
      GSI1PK: `ORDER#${orderId}`,
      GSI1SK: `ORDER#${orderId}`,
      GSI2PK: `ORDER#STATUS#PENDING`,
      GSI2SK: `ORDER#${timestamp}`,
      type: 'ORDER',
      orderId,
      userId,
      status: 'PENDING',
      total: items.reduce((sum, item) => sum + item.price * item.quantity, 0),
      createdAt: timestamp
    };

    // Prepare order items
    const orderItems = items.map(item => ({
      PutRequest: {
        Item: {
          PK: `ORDER#${orderId}`,
          SK: `ITEM#${item.productId}`,
          GSI1PK: `PRODUCT#${item.productId}`,
          GSI1SK: `ORDER#${orderId}`,
          type: 'ORDER_ITEM',
          ...item
        }
      }
    }));

    // Execute transaction
    await this.db.transactWrite({
      TransactItems: [
        {
          Put: {
            TableName: this.tableName,
            Item: order,
            ConditionExpression: 'attribute_not_exists(PK)'
          }
        },
        ...orderItems.map(item => ({
          Put: {
            TableName: this.tableName,
            Item: item.PutRequest.Item
          }
        }))
      ]
    }).promise();

    return { order, items: orderItems };
  }

  // Get user orders
  async getUserOrders(userId, limit = 20, lastEvaluatedKey = null) {
    const params = {
      TableName: this.tableName,
      KeyConditionExpression: 'PK = :pk AND begins_with(SK, :sk)',
      ExpressionAttributeValues: {
        ':pk': `USER#${userId}`,
        ':sk': 'ORDER#'
      },
      ScanIndexForward: false, // Most recent first
      Limit: limit
    };

    if (lastEvaluatedKey) {
      params.ExclusiveStartKey = lastEvaluatedKey;
    }

    const result = await this.db.query(params).promise();

    return {
      items: result.Items,
      lastEvaluatedKey: result.LastEvaluatedKey
    };
  }

  // Get order with items
  async getOrderWithItems(orderId) {
    const result = await this.db.query({
      TableName: this.tableName,
      KeyConditionExpression: 'PK = :pk',
      ExpressionAttributeValues: {
        ':pk': `ORDER#${orderId}`
      }
    }).promise();

    const order = result.Items.find(item => item.type === 'ORDER');
    const items = result.Items.filter(item => item.type === 'ORDER_ITEM');

    return { order, items };
  }

  // Update order status
  async updateOrderStatus(orderId, newStatus) {
    const timestamp = new Date().toISOString();

    // Get current order to retrieve userId
    const order = await this.db.query({
      TableName: this.tableName,
      IndexName: 'GSI1',
      KeyConditionExpression: 'GSI1PK = :pk',
      ExpressionAttributeValues: {
        ':pk': `ORDER#${orderId}`
      },
      Limit: 1
    }).promise();

    if (!order.Items[0]) {
      throw new Error('Order not found');
    }

    const { userId, status: oldStatus } = order.Items[0];

    // Update order
    await this.db.update({
      TableName: this.tableName,
      Key: {
        PK: `USER#${userId}`,
        SK: `ORDER#${orderId}`
      },
      UpdateExpression: 'SET #status = :status, GSI2PK = :gsi2pk, updatedAt = :timestamp',
      ExpressionAttributeNames: {
        '#status': 'status'
      },
      ExpressionAttributeValues: {
        ':status': newStatus,
        ':gsi2pk': `ORDER#STATUS#${newStatus}`,
        ':timestamp': timestamp
      }
    }).promise();

    return { orderId, oldStatus, newStatus, timestamp };
  }
}
```

## SDK Usage

### AWS SDK v3 (Recommended)
```javascript
import { 
  DynamoDBClient,
  CreateTableCommand,
  PutItemCommand,
  GetItemCommand,
  QueryCommand,
  UpdateItemCommand,
  DeleteItemCommand,
  BatchWriteItemCommand,
  TransactWriteItemsCommand
} from "@aws-sdk/client-dynamodb";
import { 
  DynamoDBDocumentClient,
  PutCommand,
  GetCommand,
  QueryCommand as DocQueryCommand,
  UpdateCommand,
  DeleteCommand,
  BatchWriteCommand,
  TransactWriteCommand
} from "@aws-sdk/lib-dynamodb";

// Configure client
const client = new DynamoDBClient({
  region: process.env.AWS_REGION || 'us-east-1',
  credentials: {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY
  },
  maxAttempts: 3,
  retryMode: 'adaptive'
});

// Document client for easier JSON handling
const docClient = DynamoDBDocumentClient.from(client, {
  marshallOptions: {
    convertEmptyValues: false,
    removeUndefinedValues: true,
    convertClassInstanceToMap: true
  },
  unmarshallOptions: {
    wrapNumbers: false
  }
});

// Repository pattern
class DynamoRepository {
  constructor(tableName) {
    this.tableName = tableName;
    this.client = docClient;
  }

  async put(item, condition = null) {
    const params = {
      TableName: this.tableName,
      Item: item
    };

    if (condition) {
      params.ConditionExpression = condition;
    }

    try {
      await this.client.send(new PutCommand(params));
      return item;
    } catch (error) {
      if (error.name === 'ConditionalCheckFailedException') {
        throw new Error('Item already exists');
      }
      throw error;
    }
  }

  async get(key) {
    const params = {
      TableName: this.tableName,
      Key: key
    };

    const result = await this.client.send(new GetCommand(params));
    return result.Item;
  }

  async query(keyCondition, options = {}) {
    const params = {
      TableName: this.tableName,
      KeyConditionExpression: keyCondition,
      ...options
    };

    const result = await this.client.send(new DocQueryCommand(params));
    return {
      items: result.Items || [],
      lastEvaluatedKey: result.LastEvaluatedKey,
      count: result.Count
    };
  }

  async update(key, updates, options = {}) {
    const updateExpression = this.buildUpdateExpression(updates);
    
    const params = {
      TableName: this.tableName,
      Key: key,
      ...updateExpression,
      ReturnValues: 'ALL_NEW',
      ...options
    };

    const result = await this.client.send(new UpdateCommand(params));
    return result.Attributes;
  }

  async delete(key, condition = null) {
    const params = {
      TableName: this.tableName,
      Key: key,
      ReturnValues: 'ALL_OLD'
    };

    if (condition) {
      params.ConditionExpression = condition;
    }

    const result = await this.client.send(new DeleteCommand(params));
    return result.Attributes;
  }

  async batchWrite(items) {
    const chunks = this.chunkArray(items, 25); // DynamoDB limit
    const results = [];

    for (const chunk of chunks) {
      const params = {
        RequestItems: {
          [this.tableName]: chunk
        }
      };

      const result = await this.client.send(new BatchWriteCommand(params));
      results.push(result);

      // Handle unprocessed items
      if (result.UnprocessedItems && result.UnprocessedItems[this.tableName]) {
        // Implement exponential backoff retry
        await this.retryUnprocessedItems(result.UnprocessedItems[this.tableName]);
      }
    }

    return results;
  }

  buildUpdateExpression(updates) {
    const expressions = [];
    const attributeNames = {};
    const attributeValues = {};

    Object.entries(updates).forEach(([key, value], index) => {
      const attrName = `#attr${index}`;
      const attrValue = `:val${index}`;

      expressions.push(`${attrName} = ${attrValue}`);
      attributeNames[attrName] = key;
      attributeValues[attrValue] = value;
    });

    return {
      UpdateExpression: `SET ${expressions.join(', ')}`,
      ExpressionAttributeNames: attributeNames,
      ExpressionAttributeValues: attributeValues
    };
  }

  chunkArray(array, size) {
    const chunks = [];
    for (let i = 0; i < array.length; i += size) {
      chunks.push(array.slice(i, i + size));
    }
    return chunks;
  }

  async retryUnprocessedItems(unprocessedItems, retries = 3) {
    let delay = 100;
    
    for (let i = 0; i < retries; i++) {
      await new Promise(resolve => setTimeout(resolve, delay));
      
      const result = await this.client.send(new BatchWriteCommand({
        RequestItems: {
          [this.tableName]: unprocessedItems
        }
      }));

      if (!result.UnprocessedItems || !result.UnprocessedItems[this.tableName]) {
        return;
      }

      unprocessedItems = result.UnprocessedItems[this.tableName];
      delay *= 2; // Exponential backoff
    }

    throw new Error('Failed to process all items after retries');
  }
}
```

### Python SDK (boto3)
```python
import boto3
from boto3.dynamodb.conditions import Key, Attr
from botocore.exceptions import ClientError
from decimal import Decimal
import json
from typing import Dict, List, Optional, Any
from datetime import datetime
import time
from functools import wraps

# Helper to convert float to Decimal for DynamoDB
def float_to_decimal(obj):
    if isinstance(obj, float):
        return Decimal(str(obj))
    elif isinstance(obj, dict):
        return {k: float_to_decimal(v) for k, v in obj.items()}
    elif isinstance(obj, list):
        return [float_to_decimal(item) for item in obj]
    return obj

# Helper to convert Decimal to float for JSON
def decimal_to_float(obj):
    if isinstance(obj, Decimal):
        return float(obj)
    elif isinstance(obj, dict):
        return {k: decimal_to_float(v) for k, v in obj.items()}
    elif isinstance(obj, list):
        return [decimal_to_float(item) for item in obj]
    return obj

class DynamoDBClient:
    """Production-ready DynamoDB client with best practices"""
    
    def __init__(self, table_name: str, region: str = 'us-east-1'):
        self.dynamodb = boto3.resource('dynamodb', region_name=region)
        self.table = self.dynamodb.Table(table_name)
        self.table_name = table_name
        
        # Client for low-level operations
        self.client = boto3.client('dynamodb', region_name=region)
    
    def retry_with_backoff(max_retries=3, base_delay=0.1):
        """Decorator for exponential backoff retry"""
        def decorator(func):
            @wraps(func)
            def wrapper(*args, **kwargs):
                delay = base_delay
                last_exception = None
                
                for attempt in range(max_retries):
                    try:
                        return func(*args, **kwargs)
                    except ClientError as e:
                        last_exception = e
                        error_code = e.response['Error']['Code']
                        
                        if error_code in ['ProvisionedThroughputExceededException', 
                                         'ThrottlingException']:
                            time.sleep(delay)
                            delay *= 2
                        else:
                            raise
                
                raise last_exception
            return wrapper
        return decorator
    
    @retry_with_backoff()
    def put_item(self, item: Dict[str, Any], 
                 condition: Optional[str] = None) -> Dict:
        """Put item with optional condition"""
        item = float_to_decimal(item)
        params = {'Item': item}
        
        if condition:
            params['ConditionExpression'] = condition
        
        try:
            self.table.put_item(**params)
            return decimal_to_float(item)
        except ClientError as e:
            if e.response['Error']['Code'] == 'ConditionalCheckFailedException':
                raise ValueError('Condition check failed')
            raise
    
    @retry_with_backoff()
    def get_item(self, key: Dict[str, Any], 
                 consistent: bool = False) -> Optional[Dict]:
        """Get item by key"""
        params = {
            'Key': float_to_decimal(key),
            'ConsistentRead': consistent
        }
        
        response = self.table.get_item(**params)
        item = response.get('Item')
        
        return decimal_to_float(item) if item else None
    
    @retry_with_backoff()
    def query(self, 
             key_condition: str,
             expression_values: Dict[str, Any],
             index_name: Optional[str] = None,
             limit: Optional[int] = None,
             last_evaluated_key: Optional[Dict] = None,
             scan_forward: bool = True,
             filter_expression: Optional[str] = None,
             projection: Optional[str] = None) -> Dict:
        """Query items with various options"""
        
        params = {
            'KeyConditionExpression': key_condition,
            'ExpressionAttributeValues': float_to_decimal(expression_values),
            'ScanIndexForward': scan_forward
        }
        
        if index_name:
            params['IndexName'] = index_name
        
        if limit:
            params['Limit'] = limit
        
        if last_evaluated_key:
            params['ExclusiveStartKey'] = float_to_decimal(last_evaluated_key)
        
        if filter_expression:
            params['FilterExpression'] = filter_expression
        
        if projection:
            params['ProjectionExpression'] = projection
        
        response = self.table.query(**params)
        
        return {
            'items': [decimal_to_float(item) for item in response.get('Items', [])],
            'count': response.get('Count', 0),
            'last_evaluated_key': decimal_to_float(response.get('LastEvaluatedKey'))
        }
    
    @retry_with_backoff()
    def update_item(self, 
                   key: Dict[str, Any],
                   updates: Dict[str, Any],
                   condition: Optional[str] = None,
                   return_values: str = 'ALL_NEW') -> Dict:
        """Update item with automatic expression building"""
        
        update_expressions = []
        expression_attribute_names = {}
        expression_attribute_values = {}
        
        for field, value in updates.items():
            attr_name = f'#{field}'
            attr_value = f':{field}'
            
            update_expressions.append(f'{attr_name} = {attr_value}')
            expression_attribute_names[attr_name] = field
            expression_attribute_values[attr_value] = float_to_decimal(value)
        
        params = {
            'Key': float_to_decimal(key),
            'UpdateExpression': f"SET {', '.join(update_expressions)}",
            'ExpressionAttributeNames': expression_attribute_names,
            'ExpressionAttributeValues': expression_attribute_values,
            'ReturnValues': return_values
        }
        
        if condition:
            params['ConditionExpression'] = condition
        
        response = self.table.update_item(**params)
        
        return decimal_to_float(response.get('Attributes', {}))
    
    @retry_with_backoff()
    def delete_item(self, key: Dict[str, Any], 
                   condition: Optional[str] = None) -> Optional[Dict]:
        """Delete item with optional condition"""
        params = {
            'Key': float_to_decimal(key),
            'ReturnValues': 'ALL_OLD'
        }
        
        if condition:
            params['ConditionExpression'] = condition
        
        response = self.table.delete_item(**params)
        old_item = response.get('Attributes')
        
        return decimal_to_float(old_item) if old_item else None
    
    def batch_write(self, items: List[Dict], chunk_size: int = 25) -> List:
        """Batch write with automatic chunking and retry"""
        results = []
        
        # Process in chunks
        for i in range(0, len(items), chunk_size):
            chunk = items[i:i + chunk_size]
            
            with self.table.batch_writer() as batch:
                for item in chunk:
                    batch.put_item(Item=float_to_decimal(item))
            
            results.extend(chunk)
        
        return results
    
    def transact_write(self, operations: List[Dict]) -> bool:
        """Execute transactional write"""
        transact_items = []
        
        for op in operations:
            if op['type'] == 'put':
                transact_items.append({
                    'Put': {
                        'TableName': self.table_name,
                        'Item': self._marshall(op['item']),
                        'ConditionExpression': op.get('condition')
                    }
                })
            elif op['type'] == 'update':
                update_params = self._build_update_params(
                    op['key'], 
                    op['updates'],
                    op.get('condition')
                )
                transact_items.append({
                    'Update': {
                        'TableName': self.table_name,
                        **update_params
                    }
                })
            elif op['type'] == 'delete':
                transact_items.append({
                    'Delete': {
                        'TableName': self.table_name,
                        'Key': self._marshall(op['key']),
                        'ConditionExpression': op.get('condition')
                    }
                })
        
        try:
            self.client.transact_write_items(TransactItems=transact_items)
            return True
        except ClientError as e:
            if e.response['Error']['Code'] == 'TransactionCanceledException':
                return False
            raise
    
    def _marshall(self, item: Dict) -> Dict:
        """Marshall Python dict to DynamoDB format"""
        from boto3.dynamodb.types import TypeSerializer
        serializer = TypeSerializer()
        return {k: serializer.serialize(v) for k, v in item.items()}
    
    def _build_update_params(self, key: Dict, updates: Dict, 
                            condition: Optional[str] = None) -> Dict:
        """Build update parameters for transaction"""
        update_expressions = []
        expression_attribute_names = {}
        expression_attribute_values = {}
        
        for field, value in updates.items():
            attr_name = f'#{field}'
            attr_value = f':{field}'
            
            update_expressions.append(f'{attr_name} = {attr_value}')
            expression_attribute_names[attr_name] = field
            expression_attribute_values[attr_value] = value
        
        params = {
            'Key': self._marshall(key),
            'UpdateExpression': f"SET {', '.join(update_expressions)}",
            'ExpressionAttributeNames': expression_attribute_names,
            'ExpressionAttributeValues': self._marshall(expression_attribute_values)
        }
        
        if condition:
            params['ConditionExpression'] = condition
        
        return params
```

## Query Optimization

### Efficient Query Patterns
```javascript
class QueryOptimizer {
  constructor(docClient, tableName) {
    this.db = docClient;
    this.tableName = tableName;
  }

  // Parallel queries for better performance
  async parallelQuery(queries) {
    const promises = queries.map(query => 
      this.db.send(new QueryCommand({
        TableName: this.tableName,
        ...query
      }))
    );

    const results = await Promise.all(promises);
    
    return results.reduce((acc, result) => {
      acc.items.push(...(result.Items || []));
      acc.count += result.Count || 0;
      return acc;
    }, { items: [], count: 0 });
  }

  // Pagination with cursor
  async paginatedQuery(params, pageSize = 20) {
    const pages = [];
    let lastEvaluatedKey = null;

    do {
      const queryParams = {
        ...params,
        Limit: pageSize
      };

      if (lastEvaluatedKey) {
        queryParams.ExclusiveStartKey = lastEvaluatedKey;
      }

      const result = await this.db.send(new QueryCommand(queryParams));
      
      pages.push({
        items: result.Items || [],
        count: result.Count || 0
      });

      lastEvaluatedKey = result.LastEvaluatedKey;
    } while (lastEvaluatedKey);

    return pages;
  }

  // Sparse index pattern
  async querySparseIndex(indexName, pkValue) {
    // Query sparse GSI efficiently
    return await this.db.send(new QueryCommand({
      TableName: this.tableName,
      IndexName: indexName,
      KeyConditionExpression: 'GSI1PK = :pk',
      ExpressionAttributeValues: {
        ':pk': pkValue
      },
      Select: 'ALL_PROJECTED_ATTRIBUTES'
    }));
  }

  // Composite sort key queries
  async queryWithCompositeKey(pk, skPrefix, skRange = {}) {
    const params = {
      TableName: this.tableName,
      KeyConditionExpression: 'PK = :pk',
      ExpressionAttributeValues: {
        ':pk': pk
      }
    };

    if (skPrefix) {
      params.KeyConditionExpression += ' AND begins_with(SK, :skPrefix)';
      params.ExpressionAttributeValues[':skPrefix'] = skPrefix;
    }

    if (skRange.start && skRange.end) {
      params.KeyConditionExpression += ' AND SK BETWEEN :start AND :end';
      params.ExpressionAttributeValues[':start'] = skRange.start;
      params.ExpressionAttributeValues[':end'] = skRange.end;
    }

    return await this.db.send(new QueryCommand(params));
  }

  // Filter expression optimization
  async queryWithFilter(keyCondition, filter) {
    const params = {
      TableName: this.tableName,
      KeyConditionExpression: keyCondition.expression,
      ExpressionAttributeValues: keyCondition.values
    };

    if (filter) {
      params.FilterExpression = filter.expression;
      params.ExpressionAttributeValues = {
        ...params.ExpressionAttributeValues,
        ...filter.values
      };

      if (filter.names) {
        params.ExpressionAttributeNames = filter.names;
      }
    }

    return await this.db.send(new QueryCommand(params));
  }
}
```

## Transactions

### ACID Transactions Implementation
```python
class TransactionManager:
    """Manage DynamoDB transactions"""
    
    def __init__(self, dynamodb_client):
        self.client = dynamodb_client
    
    def transfer_funds(self, from_account: str, to_account: str, 
                      amount: Decimal) -> bool:
        """Transfer funds between accounts atomically"""
        
        timestamp = datetime.utcnow().isoformat()
        transaction_id = str(uuid.uuid4())
        
        # Prepare transaction items
        transact_items = [
            {
                # Debit from account
                'Update': {
                    'TableName': 'Accounts',
                    'Key': {'PK': {'S': f'ACCOUNT#{from_account}'}},
                    'UpdateExpression': 'SET balance = balance - :amount, lastModified = :timestamp',
                    'ConditionExpression': 'balance >= :amount',
                    'ExpressionAttributeValues': {
                        ':amount': {'N': str(amount)},
                        ':timestamp': {'S': timestamp}
                    }
                }
            },
            {
                # Credit to account
                'Update': {
                    'TableName': 'Accounts',
                    'Key': {'PK': {'S': f'ACCOUNT#{to_account}'}},
                    'UpdateExpression': 'SET balance = balance + :amount, lastModified = :timestamp',
                    'ExpressionAttributeValues': {
                        ':amount': {'N': str(amount)},
                        ':timestamp': {'S': timestamp}
                    }
                }
            },
            {
                # Create transaction record
                'Put': {
                    'TableName': 'Transactions',
                    'Item': {
                        'PK': {'S': f'TXN#{transaction_id}'},
                        'SK': {'S': f'TXN#{transaction_id}'},
                        'fromAccount': {'S': from_account},
                        'toAccount': {'S': to_account},
                        'amount': {'N': str(amount)},
                        'timestamp': {'S': timestamp},
                        'status': {'S': 'COMPLETED'}
                    },
                    'ConditionExpression': 'attribute_not_exists(PK)'
                }
            }
        ]
        
        try:
            self.client.transact_write_items(TransactItems=transact_items)
            return True
        except ClientError as e:
            if e.response['Error']['Code'] == 'TransactionCanceledException':
                # Check which condition failed
                reasons = e.response.get('CancellationReasons', [])
                for i, reason in enumerate(reasons):
                    if reason.get('Code') == 'ConditionalCheckFailed':
                        if i == 0:
                            raise ValueError('Insufficient funds')
                        elif i == 2:
                            raise ValueError('Duplicate transaction')
                return False
            raise
    
    def create_order_with_inventory(self, order: Dict, 
                                   items: List[Dict]) -> bool:
        """Create order and update inventory atomically"""
        
        transact_items = []
        
        # Add order
        transact_items.append({
            'Put': {
                'TableName': 'Orders',
                'Item': self._marshall(order),
                'ConditionExpression': 'attribute_not_exists(PK)'
            }
        })
        
        # Update inventory for each item
        for item in items:
            transact_items.append({
                'Update': {
                    'TableName': 'Inventory',
                    'Key': self._marshall({
                        'PK': f"PRODUCT#{item['productId']}"
                    }),
                    'UpdateExpression': 'SET quantity = quantity - :qty',
                    'ConditionExpression': 'quantity >= :qty',
                    'ExpressionAttributeValues': {
                        ':qty': {'N': str(item['quantity'])}
                    }
                }
            })
        
        try:
            self.client.transact_write_items(TransactItems=transact_items)
            return True
        except ClientError as e:
            if e.response['Error']['Code'] == 'TransactionCanceledException':
                self._handle_transaction_failure(e)
                return False
            raise
    
    def _handle_transaction_failure(self, error):
        """Handle transaction cancellation reasons"""
        reasons = error.response.get('CancellationReasons', [])
        
        for i, reason in enumerate(reasons):
            if reason.get('Code') == 'ConditionalCheckFailed':
                print(f"Condition failed for item {i}: {reason.get('Message')}")
            elif reason.get('Code') == 'ItemCollectionSizeLimitExceeded':
                print(f"Item collection size limit exceeded for item {i}")
            elif reason.get('Code') == 'TransactionConflict':
                print(f"Transaction conflict for item {i}")
            elif reason.get('Code') == 'ProvisionedThroughputExceeded':
                print(f"Throughput exceeded for item {i}")
            elif reason.get('Code') == 'ThrottlingError':
                print(f"Request throttled for item {i}")
```

## DynamoDB Streams

### Change Data Capture
```javascript
// Lambda function for processing DynamoDB Streams
export const streamProcessor = async (event) => {
  const processedRecords = [];

  for (const record of event.Records) {
    const { eventName, dynamodb } = record;

    try {
      switch (eventName) {
        case 'INSERT':
          await handleInsert(dynamodb.NewImage);
          break;
        
        case 'MODIFY':
          await handleModify(
            dynamodb.OldImage,
            dynamodb.NewImage
          );
          break;
        
        case 'REMOVE':
          await handleRemove(dynamodb.OldImage);
          break;
      }

      processedRecords.push({
        eventID: record.eventID,
        status: 'SUCCESS'
      });
    } catch (error) {
      console.error(`Error processing record ${record.eventID}:`, error);
      
      processedRecords.push({
        eventID: record.eventID,
        status: 'FAILED',
        error: error.message
      });
    }
  }

  return {
    batchItemFailures: processedRecords
      .filter(r => r.status === 'FAILED')
      .map(r => ({ itemIdentifier: r.eventID }))
  };
};

async function handleInsert(newImage) {
  const item = unmarshall(newImage);
  
  // Example: Sync to Elasticsearch
  if (item.type === 'PRODUCT') {
    await indexToElasticsearch(item);
  }
  
  // Example: Send notification
  if (item.type === 'ORDER') {
    await sendOrderNotification(item);
  }
}

async function handleModify(oldImage, newImage) {
  const oldItem = unmarshall(oldImage);
  const newItem = unmarshall(newImage);
  
  // Example: Audit log
  await createAuditLog({
    action: 'UPDATE',
    entityType: newItem.type,
    entityId: newItem.id,
    changes: calculateDiff(oldItem, newItem),
    timestamp: new Date().toISOString()
  });
  
  // Example: Cache invalidation
  if (newItem.type === 'USER') {
    await invalidateUserCache(newItem.userId);
  }
}

async function handleRemove(oldImage) {
  const item = unmarshall(oldImage);
  
  // Example: Cleanup related data
  if (item.type === 'USER') {
    await cleanupUserData(item.userId);
  }
}

// Stream processing with filtering
class StreamFilter {
  constructor() {
    this.filters = new Map();
  }

  addFilter(eventType, condition) {
    if (!this.filters.has(eventType)) {
      this.filters.set(eventType, []);
    }
    this.filters.get(eventType).push(condition);
  }

  async process(records) {
    const results = [];

    for (const record of records) {
      const filters = this.filters.get(record.eventName) || [];
      
      for (const filter of filters) {
        if (filter.matches(record)) {
          await filter.handler(record);
          results.push({
            recordId: record.eventID,
            filter: filter.name,
            processed: true
          });
        }
      }
    }

    return results;
  }
}
```

## Global Tables

### Multi-Region Setup
```python
class GlobalTableManager:
    """Manage DynamoDB Global Tables"""
    
    def __init__(self):
        self.clients = {
            'us-east-1': boto3.client('dynamodb', region_name='us-east-1'),
            'eu-west-1': boto3.client('dynamodb', region_name='eu-west-1'),
            'ap-southeast-1': boto3.client('dynamodb', region_name='ap-southeast-1')
        }
    
    def create_global_table(self, table_name: str, regions: List[str]):
        """Create a global table across regions"""
        
        # Create table in first region
        primary_region = regions[0]
        primary_client = self.clients[primary_region]
        
        # Table definition
        table_params = {
            'TableName': table_name,
            'KeySchema': [
                {'AttributeName': 'PK', 'KeyType': 'HASH'},
                {'AttributeName': 'SK', 'KeyType': 'RANGE'}
            ],
            'AttributeDefinitions': [
                {'AttributeName': 'PK', 'AttributeType': 'S'},
                {'AttributeName': 'SK', 'AttributeType': 'S'}
            ],
            'BillingMode': 'PAY_PER_REQUEST',
            'StreamSpecification': {
                'StreamEnabled': True,
                'StreamViewType': 'NEW_AND_OLD_IMAGES'
            }
        }
        
        # Create primary table
        primary_client.create_table(**table_params)
        
        # Wait for table to be active
        waiter = primary_client.get_waiter('table_exists')
        waiter.wait(TableName=table_name)
        
        # Create global table
        primary_client.create_global_table(
            GlobalTableName=table_name,
            ReplicationGroup=[
                {'RegionName': region} for region in regions
            ]
        )
        
        return True
    
    def write_with_consistency(self, table_name: str, item: Dict, 
                              regions: List[str]):
        """Write to multiple regions with consistency check"""
        
        results = {}
        
        for region in regions:
            client = self.clients[region]
            table = boto3.resource('dynamodb', 
                                 region_name=region).Table(table_name)
            
            try:
                table.put_item(Item=item)
                results[region] = 'SUCCESS'
            except Exception as e:
                results[region] = f'FAILED: {str(e)}'
        
        # Verify eventual consistency
        time.sleep(1)  # Wait for propagation
        
        for region in regions:
            table = boto3.resource('dynamodb', 
                                 region_name=region).Table(table_name)
            
            response = table.get_item(
                Key={'PK': item['PK'], 'SK': item['SK']}
            )
            
            if 'Item' not in response:
                results[f'{region}_verify'] = 'NOT_FOUND'
            else:
                results[f'{region}_verify'] = 'VERIFIED'
        
        return results
    
    def get_with_fallback(self, table_name: str, key: Dict, 
                         preferred_region: str):
        """Get item with regional fallback"""
        
        # Try preferred region first
        try:
            table = boto3.resource('dynamodb', 
                                 region_name=preferred_region).Table(table_name)
            response = table.get_item(Key=key)
            
            if 'Item' in response:
                return response['Item']
        except Exception as e:
            print(f"Failed to read from {preferred_region}: {e}")
        
        # Fallback to other regions
        for region, client in self.clients.items():
            if region == preferred_region:
                continue
            
            try:
                table = boto3.resource('dynamodb', 
                                     region_name=region).Table(table_name)
                response = table.get_item(Key=key)
                
                if 'Item' in response:
                    return response['Item']
            except Exception:
                continue
        
        return None
```

## Cost Optimization

### On-Demand vs Provisioned
```javascript
class CostOptimizer {
  constructor(cloudWatch, dynamodb) {
    this.cloudWatch = cloudWatch;
    this.dynamodb = dynamodb;
  }

  async analyzeUsagePattern(tableName, days = 7) {
    const endTime = new Date();
    const startTime = new Date(endTime - days * 24 * 60 * 60 * 1000);

    // Get consumed capacity metrics
    const metrics = await this.cloudWatch.getMetricStatistics({
      Namespace: 'AWS/DynamoDB',
      MetricName: 'ConsumedReadCapacityUnits',
      Dimensions: [
        { Name: 'TableName', Value: tableName }
      ],
      StartTime: startTime,
      EndTime: endTime,
      Period: 3600, // 1 hour
      Statistics: ['Average', 'Maximum']
    }).promise();

    // Analyze patterns
    const analysis = this.analyzeMetrics(metrics.Datapoints);
    
    // Recommend billing mode
    return this.recommendBillingMode(analysis);
  }

  analyzeMetrics(datapoints) {
    const sorted = datapoints.sort((a, b) => a.Maximum - b.Maximum);
    
    return {
      average: datapoints.reduce((sum, p) => sum + p.Average, 0) / datapoints.length,
      peak: sorted[sorted.length - 1]?.Maximum || 0,
      p95: sorted[Math.floor(sorted.length * 0.95)]?.Maximum || 0,
      variance: this.calculateVariance(datapoints.map(p => p.Average)),
      utilizationRate: this.calculateUtilization(datapoints)
    };
  }

  recommendBillingMode(analysis) {
    const recommendations = [];

    // High variance suggests on-demand
    if (analysis.variance > 100) {
      recommendations.push({
        mode: 'ON_DEMAND',
        reason: 'High traffic variance detected',
        estimatedMonthlyCost: this.estimateOnDemandCost(analysis)
      });
    }

    // Consistent traffic suggests provisioned
    if (analysis.utilizationRate > 0.7) {
      recommendations.push({
        mode: 'PROVISIONED',
        reason: 'Consistent traffic pattern',
        suggestedRCU: Math.ceil(analysis.p95),
        suggestedWCU: Math.ceil(analysis.p95),
        estimatedMonthlyCost: this.estimateProvisionedCost(analysis)
      });
    }

    // Auto-scaling for predictable patterns
    if (analysis.variance < 50 && analysis.utilizationRate > 0.5) {
      recommendations.push({
        mode: 'PROVISIONED_WITH_AUTO_SCALING',
        reason: 'Predictable traffic with some variation',
        minCapacity: Math.ceil(analysis.average * 0.8),
        maxCapacity: Math.ceil(analysis.peak * 1.2),
        targetUtilization: 70
      });
    }

    return recommendations;
  }

  calculateVariance(values) {
    const mean = values.reduce((sum, v) => sum + v, 0) / values.length;
    const squaredDiffs = values.map(v => Math.pow(v - mean, 2));
    return squaredDiffs.reduce((sum, v) => sum + v, 0) / values.length;
  }

  calculateUtilization(datapoints) {
    // Calculate how consistently capacity is used
    const nonZero = datapoints.filter(p => p.Average > 0).length;
    return nonZero / datapoints.length;
  }

  estimateOnDemandCost(analysis) {
    // Simplified cost calculation
    const monthlyReads = analysis.average * 730 * 3600; // hours to seconds
    const monthlyWrites = analysis.average * 730 * 3600 * 0.2; // assume 20% writes
    
    const readCost = (monthlyReads / 4000) * 0.25; // $0.25 per million RCU
    const writeCost = (monthlyWrites / 1000) * 1.25; // $1.25 per million WCU
    
    return readCost + writeCost;
  }

  estimateProvisionedCost(analysis) {
    const rcu = Math.ceil(analysis.p95);
    const wcu = Math.ceil(analysis.p95 * 0.2); // assume 20% writes
    
    const rcuCost = rcu * 0.00013 * 730; // $0.00013 per RCU per hour
    const wcuCost = wcu * 0.00065 * 730; // $0.00065 per WCU per hour
    
    return rcuCost + wcuCost;
  }
}
```

## Performance Monitoring

### CloudWatch Metrics and Alarms
```python
class DynamoDBMonitor:
    """Monitor DynamoDB performance and set up alarms"""
    
    def __init__(self, table_name: str, region: str = 'us-east-1'):
        self.table_name = table_name
        self.cloudwatch = boto3.client('cloudwatch', region_name=region)
        self.dynamodb = boto3.client('dynamodb', region_name=region)
    
    def create_standard_alarms(self, sns_topic_arn: str):
        """Create standard monitoring alarms"""
        
        alarms = [
            {
                'name': f'{self.table_name}-ThrottledRequests',
                'metric': 'UserErrors',
                'statistic': 'Sum',
                'threshold': 10,
                'comparison': 'GreaterThanThreshold',
                'description': 'Alert when requests are throttled'
            },
            {
                'name': f'{self.table_name}-HighLatency',
                'metric': 'SuccessfulRequestLatency',
                'statistic': 'Average',
                'threshold': 100,  # milliseconds
                'comparison': 'GreaterThanThreshold',
                'description': 'Alert when latency is high'
            },
            {
                'name': f'{self.table_name}-SystemErrors',
                'metric': 'SystemErrors',
                'statistic': 'Sum',
                'threshold': 5,
                'comparison': 'GreaterThanThreshold',
                'description': 'Alert on system errors'
            },
            {
                'name': f'{self.table_name}-ConsumedCapacity',
                'metric': 'ConsumedReadCapacityUnits',
                'statistic': 'Sum',
                'threshold': 1000,
                'comparison': 'GreaterThanThreshold',
                'description': 'Alert on high capacity consumption'
            }
        ]
        
        for alarm in alarms:
            self.cloudwatch.put_metric_alarm(
                AlarmName=alarm['name'],
                ComparisonOperator=alarm['comparison'],
                EvaluationPeriods=2,
                MetricName=alarm['metric'],
                Namespace='AWS/DynamoDB',
                Period=300,  # 5 minutes
                Statistic=alarm['statistic'],
                Threshold=alarm['threshold'],
                ActionsEnabled=True,
                AlarmActions=[sns_topic_arn],
                AlarmDescription=alarm['description'],
                Dimensions=[
                    {
                        'Name': 'TableName',
                        'Value': self.table_name
                    }
                ]
            )
    
    def get_table_metrics(self, metric_name: str, 
                         start_time: datetime, 
                         end_time: datetime) -> List[Dict]:
        """Get specific metrics for the table"""
        
        response = self.cloudwatch.get_metric_statistics(
            Namespace='AWS/DynamoDB',
            MetricName=metric_name,
            Dimensions=[
                {
                    'Name': 'TableName',
                    'Value': self.table_name
                }
            ],
            StartTime=start_time,
            EndTime=end_time,
            Period=3600,  # 1 hour
            Statistics=['Average', 'Sum', 'Maximum', 'Minimum']
        )
        
        return response['Datapoints']
    
    def analyze_hot_partition(self) -> Dict:
        """Analyze for hot partition issues"""
        
        # Get contributor insights
        try:
            response = self.dynamodb.describe_contributor_insights(
                TableName=self.table_name
            )
            
            if response['ContributorInsightsStatus'] == 'ENABLED':
                # Get actual insights
                insights = self.dynamodb.describe_contributor_insights(
                    TableName=self.table_name
                )
                return insights
        except:
            pass
        
        # Enable contributor insights if not enabled
        self.dynamodb.update_contributor_insights(
            TableName=self.table_name,
            ContributorInsightsAction='ENABLE'
        )
        
        return {'status': 'Contributor Insights enabled'}
    
    def create_dashboard(self):
        """Create CloudWatch dashboard for table"""
        
        dashboard_body = {
            "widgets": [
                {
                    "type": "metric",
                    "properties": {
                        "metrics": [
                            ["AWS/DynamoDB", "ConsumedReadCapacityUnits", 
                             {"stat": "Sum"}],
                            [".", "ConsumedWriteCapacityUnits", 
                             {"stat": "Sum"}]
                        ],
                        "period": 300,
                        "stat": "Average",
                        "region": "us-east-1",
                        "title": "Consumed Capacity"
                    }
                },
                {
                    "type": "metric",
                    "properties": {
                        "metrics": [
                            ["AWS/DynamoDB", "UserErrors", {"stat": "Sum"}],
                            [".", "SystemErrors", {"stat": "Sum"}]
                        ],
                        "period": 300,
                        "stat": "Sum",
                        "region": "us-east-1",
                        "title": "Errors"
                    }
                },
                {
                    "type": "metric",
                    "properties": {
                        "metrics": [
                            ["AWS/DynamoDB", "SuccessfulRequestLatency", 
                             {"stat": "Average"}]
                        ],
                        "period": 300,
                        "stat": "Average",
                        "region": "us-east-1",
                        "title": "Latency"
                    }
                }
            ]
        }
        
        self.cloudwatch.put_dashboard(
            DashboardName=f'{self.table_name}-Dashboard',
            DashboardBody=json.dumps(dashboard_body)
        )
```

## Best Practices Summary

### Design Patterns
1. **Single Table Design**: Use one table with GSIs for all entities
2. **Composite Keys**: Leverage sort keys for hierarchical data
3. **Sparse Indexes**: Use GSIs with sparse attributes
4. **Adjacency Lists**: Model many-to-many relationships
5. **Time Series Data**: Use time-based sort keys

### Performance
1. **Batch Operations**: Use batch APIs for bulk operations
2. **Parallel Scanning**: Divide large scans across segments
3. **Caching**: Implement DAX or ElastiCache
4. **Connection Pooling**: Reuse connections
5. **Compression**: Compress large attributes

### Cost Optimization
1. **Right-size Capacity**: Use auto-scaling or on-demand
2. **TTL**: Enable TTL for temporary data
3. **Projection**: Query only needed attributes
4. **Archive Old Data**: Move to S3 for long-term storage
5. **Reserved Capacity**: Purchase for predictable workloads

### Security
1. **IAM Policies**: Use fine-grained access control
2. **Encryption**: Enable encryption at rest
3. **VPC Endpoints**: Use for private connectivity
4. **Audit Logging**: Enable CloudTrail
5. **Backup**: Configure point-in-time recovery

### Monitoring
1. **CloudWatch Metrics**: Monitor all key metrics
2. **Alarms**: Set up proactive alerts
3. **Contributor Insights**: Identify hot partitions
4. **X-Ray**: Trace request paths
5. **Performance Insights**: Analyze query patterns

## Common Pitfalls
1. **Hot Partitions**: Uneven key distribution
2. **Large Items**: Items exceeding 400KB
3. **Inefficient Queries**: Not using indexes properly
4. **Over-provisioning**: Paying for unused capacity
5. **Missing Retries**: No exponential backoff
6. **No Monitoring**: Flying blind without metrics
7. **Poor Key Design**: Leading to inefficient access patterns
8. **Ignoring Limits**: Hitting throughput or size limits
9. **No Backup Strategy**: Risk of data loss
10. **Synchronous Processing**: Not using streams for async work